terraform {
  required_providers {
    datadog = {
      source = "Datadog/datadog"
    }
  }
}

#1. MONITOR: node_not_ready - should be a different set of monitors 
resource "datadog_monitor" "node_not_ready" {
  name    = "(clusterName) ${title(var.clusterName)} is in {{condition.name}} [Node Not Ready]"
  type    = "service check"
  query   = "\"kubernetes_state.node.ready\".over(\"cluster_name:staging\",\"condition:ready\").by(\"cluster_name\").last(4).count_by_status()"
  message = <<-EOF
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_alert}} 

    Nodes in {{cluster_name.name}} failed 2 status checks and is not in a Ready state. Node showing {{condition.name}} state.

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_recovery}}
    EOF

  monitor_thresholds {
    unknown  = 2
    warning  = 1
    ok       = 3
    critical = 2
  }

  notify_audit        = false
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "pods",
    "k8s",
    "managed_by:terraform"
  ]
}

resource "datadog_monitor" "node_memory_pressure" {
  name    = "${title(var.clusterName)} Memory Pressure checks are 75% CRITICAL"
  type    = "service check"
  query   = "\"kubernetes_state.node.memory_pressure\".over(\"kube_cluster_name:${title(var.clusterName)}\").by(\"*\").last(1).pct_by_status()"
  message = <<-EOF
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_alert}} 

    ${title(var.clusterName)}'s checks are 75% CRITICAL. This suggests that our network memory is under memory pressure.

    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_recovery}}
    EOF

  monitor_thresholds {
    critical = 75
    ok       = 25
  }

  notify_audit        = false
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3
  no_data_timeframe   = 2

  tags = [
    "alert:${var.alert_recipients_testing}",
    "pods",
    "k8s",
    "managed_by:terraform"
  ]
}

resource "datadog_monitor" "e2e_sla_verify" {
  name    = "${title(var.clusterName)} End to End SLA Verify"
  type    = "query alert"
  query   = "sum(last_3m):avg:sql_exporter_e2e_sla_testing{*} by {${title(var.clusterName)}} <= 0"
  message = <<-EOM
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{/is_alert}} 

    Recent runs of EndToEnd SLA Tests have failed in the last 3 mins

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 0
  }

  no_data_timeframe   = 6
  notify_audit        = true
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "pods",
    "k8s",
    "managed_by:terraform"
  ]
}

resource "datadog_monitor" "velero_backup_failures" {
  name    = "${title(var.clusterName)}: Velero backup failure detected"
  type    = "query alert"
  query   = "sum(last_5m):sum:velero_backup_failure_total{${title(var.clusterName)}}.as_count() > 0"
  message = <<-EOM
    {{#is_alert}}
    ${var.alert_recipients_testing}
    {{/is_alert}} 

    Velero backup failure detected! Check backup list and reason why recent cluster backup has failed (in production or staging).

    {{#is_recovery}}
    ${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 0
  }

  notify_audit        = true
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "pods",
    "k8s",
    "managed_by:terraform"
  ]
}

resource "datadog_monitor" "_slow" {
  name    = "(BOT)${title(var.clusterName)} is Slow"
  type    = "query alert"
  query   = "avg(last_5m):avg:interface_gateway_avg_round_trip_time{cluster_name:${var.clusterName}} > 4"
  message = <<-EOM
    {{#is_alert}}
    ${var.alert_recipients_testing}
    {{/is_alert}} 

    Interface Gateway's Average Response Time is currently {{value}}

    {{#is_recovery}}
    ${var.alert_recipients_testing}
    {{/is_recovery}}
    EOM

  monitor_thresholds {
    critical = 4
  }

  notify_audit        = true
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [

    "alert:${var.alert_recipients_testing}",
    "pods",
    "k8s",
    "managed_by:terraform"
  ]
}
