terraform {
  required_providers {
    datadog = {
      source = "Datadog/datadog"
    }
  }
}

#-----MONITOR ORDER-----#
#1. SERVICE_ERRORS
#2. SERVICE_CONTAINER_RESTART
#3. SERVICE_CRASHLOOP
#4. PODS
#5. PODS NOT READY
#6. PODS RECENT RESTARTS
#7. PODS STATUS TERMINATED
#8. PODS TERMINATED
#9. PODS STATUS ERROR

#1.MONTOR: service_errors
resource "datadog_monitor" "service_errors" {
  name    = "${title(var.service)} Errors Detected"
  type    = "query alert"
  query   = "sum(last_5m):default_zero(sum:trace.${var.framework}.request.errors{env:${var.env} AND service:${title(var.service)} AND NOT http.status_code:520} by {resource_name}.as_count()) > 0"
  message = <<-EOM
    {{#is_alert}}
    ${var.alert_recipients_testing}
    {{/is_alert}}

        A call to resource {{resource_name.name}} on service ${title(var.service)} returned an error.
        For more information, see https://app.datadoghq.com/apm/services/${title(var.service)}
    EOM

  monitor_thresholds {
    critical = 0
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform"
  ]
}

#2.MONITOR: service_container_restart
resource "datadog_monitor" "service_container_restart" {
  name    = "${title(var.service)} Container Restart"
  type    = "query alert"
  query   = "change(sum(last_5m),last_5m):exclude_null(avg:kubernetes.containers.restarts{*} by {cluster_name,kube_namespace,pod_name}) > 5"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

        Container restart detected on service ${title(var.service)}, pod `{{pod_name.name}}`, container `{{kube_container_name.name}}`
        For more information, see https://app.datadoghq.com/apm/services/${title(var.service)}

    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 5
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform"
  ]
}

##3. MONITOR: service_crashloop
resource "datadog_monitor" "service_crashloop" {
  name    = "${title(var.service)} CrashLoopBackOff"
  type    = "query alert"
  query   = "max(last_10m):max:kubernetes_state.container.status_report.count.waiting{reason:crashloopbackoff,env:${var.env},service:${title(var.service)}} by {service,pod_name,kube_container_name} >= 1"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

        Pod in CrashLoopBackoff, service ${title(var.service)}, pod `{{pod_name.name}}`, container `{{kube_container_name.name}}`
        For more information, see https://app.datadoghq.com/apm/services/${title(var.service)}
    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 1
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform"
  ]
}

#----- POD ALERTS -----#
#1. PODS NOT READY
#2. PODS RECENT RESTARTS
#3. PODS STATUS TERMINATED
#4. PODS TERMINATED
#5. PODS STATUS ERROR

#4. MONITOR: pods not ready
resource "datadog_monitor" "pods_not_ready" {
  name    = "Pod(s) Not Ready in ${title(var.service)}"
  type    = "query alert"
  query   = "avg(last_5m):top(exclude_null(sum:kubernetes_state.pod.ready{condition:false,*,*,*,*,*,*,*} by {kube_namespace}), 25, \"last\", \"desc\") < 0"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

        A Pod(s) are in a state other than `Running` in {{service.name}} for longer than 3 minutes.  
        For more information see: https://app.datadoghq.com/apm/{{service.name}}

        ```kubectl get po -A | grep -i  {{service.name}}```

        For a stack trace:https://app.datadoghq.com/apm/traces?query=%40_top_level%3A1%20env%3Aprod%20service%3A{{service.name}}

    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 0
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true

  new_group_delay = 300

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform"
  ]
}

#5. MONITOR: pods Recent restarts
resource "datadog_monitor" "pods_recent_restarts" {
  name    = "pods recent restarts in ${title(var.service)}"
  type    = "query alert"
  query   = "avg(last_5m):avg:kubernetes_state.pod.ready{pod_name:*} by {service} - hour_before(avg:kubernetes_state.pod.ready{pod_name:*} by {service}) < 0"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

        pods are in a state other than `Running` in ${title(var.service)}.\n
        For more information see: https://app.datadoghq.com/apm/${title(var.service)}\n\n```\nkubectl get po -A | grep -i  ${var.service} \n```\n\nFor a stack trace:\nhttps://app.datadoghq.com/apm/traces?query=%40_top_level%3A1%20env%3Aprod%20service%3A{{service.name}}\n\n\nFor a program profiler:\n\n{{#is_recovery}}\n@slack-ops-datadog-warnings  \n{{/is_recovery}}\n\n\nNot Ready @chris.montgomery@.com
        For more information, see: https://app.datadoghq.com/apm/services/${title(var.service)}

    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 0
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true

  new_group_delay = 300

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform",
  ]
}

#6. MONITOR: pods Terminated
resource "datadog_monitor" "pods_terminated" {
  name    = "pods Not Ready in ${title(var.service)}"
  type    = "query alert"
  query   = "avg(last_5m):avg:kubernetes_state.pod.ready{pod_name:*} by {service} - hour_before(avg:kubernetes_state.pod.ready{pod_name:*} by {service}) < 0"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

        pods are in a state other than `Running` in ${title(var.service)} in a comparative 5 minute check against it's state an hour ago.\n
        For more information see: https://app.datadoghq.com/apm/${title(var.service)}\n\n```\nkubectl get po -A | grep -i  ${var.service} \n```\n\nFor a stack trace:\nhttps://app.datadoghq.com/apm/traces?query=%40_top_level%3A1%20env%3Aprod%20service%3A{{service.name}}\n\n\nFor a program profiler:\n\n{{#is_recovery}}\n@slack-ops-datadog-warnings  \n{{/is_recovery}}\n\n\nNot Ready @chris.montgomery@.com
        For more information, see: https://app.datadoghq.com/apm/services/${title(var.service)}

    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 0
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true

  new_group_delay = 300

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform",
  ]
}

#7. MONITOR: OOM Detected
resource "datadog_monitor" "OOM_Detected" {
  name    = "OOM Detected on Service ${title(var.service)}"
  type    = "query alert"
  query   = "avg(last_5m):monotonic_diff(avg:container.memory.oom_events{env:prod,kube_service:${title(var.service)}} by {kube_service,kube_container_name}) > 0"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

    OOM_Detected Panic!
    Pod is out of Memory, service ${title(var.service)}, pod `{{pod_name.name}}`, container `{{kube_container_name.name}}`

    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 0
  }

  require_full_window = false
  notify_no_data      = false
  renotify_interval   = 0
  include_tags        = true
  notify_audit        = false
  new_group_delay     = 300
  priority            = 4
  restricted_roles    = null

  tags = [
    "env:${var.env}",
    "team:${var.team}",
    "service:${title(var.service)}",
    "managed_by:terraform",
  ]
}

#1. MONITOR: pod_crashes 
resource "datadog_monitor" "pod_crashes" {
  name    = "(k8s) ${title(var.service)} Increased Pod Crashes"
  type    = "query alert"
  query   = "avg(last_5m):avg:kubernetes_state.container.restarts{*} by {cluster_name,kube_namespace,pod} - hour_before(avg:kubernetes_state.container.restarts{*} by {cluster_name,kube_namespace,pod}) > 3"
  message = <<-EOM
    {{#is_alert}}
    @${var.alert_recipients_testing}
    {{/is_alert}} 

    ({{cluster_name.name}} {{kube_namespace.name}} {{pod.name}}) has crashed repeatedly over the last hour

    {{#is_recovery}}
    @${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 3
  }

  notify_audit        = false
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "team:${var.team}",
    "framework:${var.framework}",
    "k8s",
    "pods",
    "managed_by:terraform"
  ]
}

#2. MONITOR: network_rx_errors
resource "datadog_monitor" "rx_errors" {
  name    = "(k8s) ${title(var.service)} Network RX (recieve) Errors"
  type    = "metric alert"
  query   = "avg(last_10m):avg:kubernetes.network.rx_errors{*} by {cluster_name} > 100"
  message = <<-EOM

    {{#is_alert}}${var.alert_recipients_testing}{{/is_alert}} 

    {{#is_warning}}
    {{cluster_name.name}} network RX (receive) errors occurring 10 times per second
    {{/is_warning}}
    {{#is_alert}}
    {{cluster_name.name}} network RX (receive) errors occurring 100 times per second
    {{/is_alert}}
    {{#is_recovery}}${var.alert_recipients_testing}{{/is_recovery}} 
    EOM

  monitor_thresholds {
    critical = 100
    warning  = 10
  }

  notify_audit        = false
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "team:${var.team}",
    "framework:${var.framework}",
    "k8s",
    "pods",
    "managed_by:terraform"
  ]
}


#2. MONITOR: httpErrors
resource "datadog_monitor" "httpErrors" {
  name    = "(HTTP Errors) ${title(var.service)} Http 5x Errors -- Excluding 520 Responses"
  type    = "query alert"
  query   = "sum(last_5m):sum:nginx_ingress.controller.requests{status:5* AND NOT status:520 AND ingress NOT IN (lua-scripting)} by {ingress,kube_cluster_name}.as_count() > 10"
  message = <<-EOM
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
        {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_staging_testing}{{/is_exact_match}}
    {{/is_alert}} 

    Ingress `{{ingress.name}}` has had `{{value}}` 5xx errors in the last 5 minutes

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_staging_testing}{{/is_exact_match}}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 10
    critical_recovery = 0
  }

  notify_audit        = false
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "env:${var.env}",
    "alert:${var.alert_recipients_testing}",
    "team:${var.team}",
    "framework:${var.framework}",
    "k8s",
    "pods",
    "managed_by:terraform"
  ]
}
