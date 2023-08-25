### very generic apm alerts
### these need to be improved upon and should just be the first pass
### in order to get apm alerting in slack for other teams to see

variable "apm_default_priority" {
    default = "1"
}
variable "apm_tags" {
  type = list(string)
  default = [ "category:apm" ]
}
variable "apm_default_notify_channels" {
    type = map
    default = {
        production = "<slack_channel_prod>"
        staging    = "<slack_channel_staging>"
    }
}

resource "datadog_monitor" "apm_general_onlyrelay" {
  name    = "Trace Error on {{kube_deployment.name}}"
  type    = "trace-analytics alert"
  query   = "trace-analytics(\"@http.status_code:(5** OR -520) kube_deployment:relay\").rollup(\"count\").by(\"resource_name,kube_deployment,@http.url,env\").last(\"5m\") > 1"
  message = <<-EOM
    {{#is_alert}}
    {{#is_exact_match "env.name" "prod"}}${var.apm_default_notify_channels["production"]}{{/is_exact_match}}
    {{#is_exact_match "env.name" "staging"}}${var.apm_default_notify_channels["staging"]}{{/is_exact_match}}
    {{/is_alert}}

    **service**: `{{kube_deployment.name}}`
    **resource**: `{{resource_name.name}}`
    **http_url**: `{{[@http.url].name}}`

    is experiencing `{{value}}` 5xx errors in the last 5 minutes

    [DataDog Trace](https://app.datadoghq.com/apm/traces?query=env%3A{{env.name}}%20-status%3Aok%20-%40http.status_code%3A520%20kube_deployment%3A{{kube_deployment.name}})
    EOM

  monitor_thresholds {
    critical = 1
  }

  new_group_delay     = 60
  notify_audit        = var.notification_on_changes
  require_full_window = false
  renotify_interval   = var.notifcation_renotify
  include_tags        = var.notification_include_msg_tags
  priority            = var.apm_default_priority
  tags                = setunion(var.default_tags,var.apm_tags)
}

resource "datadog_monitor" "apm_general_norelay" {
  name    = "Trace Error on {{kube_deployment.name}}"
  type    = "trace-analytics alert"
  query   = "trace-analytics(\"@http.status_code:5** -kube_deployment:relay\").rollup(\"count\").by(\"resource_name,kube_deployment,env\").last(\"5m\") > 1"
  message = <<-EOM
    {{#is_alert}}
    {{#is_exact_match "env.name" "prod"}}${var.apm_default_notify_channels["production"]}{{/is_exact_match}}
    {{#is_exact_match "env.name" "staging"}}${var.apm_default_notify_channels["staging"]}{{/is_exact_match}}
    {{/is_alert}}

    **service**: `{{kube_deployment.name}}`
    **operation and endpoint**: `{{resource_name.name}}`

    is experiencing `{{value}}` 5xx errors in the last 5 minutes

    [DataDog Trace](https://app.datadoghq.com/apm/traces?query=env%3A{{env.name}}%20-status%3Aok%20kube_deployment%3A{{kube_deployment.name}})
    EOM

  monitor_thresholds {
    critical = 1
  }

  new_group_delay     = 60
  notify_audit        = var.notification_on_changes
  require_full_window = false
  renotify_interval   = var.notifcation_renotify
  include_tags        = var.notification_include_msg_tags
  priority            = var.apm_default_priority
  tags                = setunion(var.default_tags,var.apm_tags)
}
