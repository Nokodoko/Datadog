terraform {
  required_providers {
    datadog = {
      source = "Datadog/datadog"
    }
  }
}

resource "datadog_monitor" "node_high_memory" {
  name    = "${title(var.aws_autoscaling)} High Memory Usage Detected"
  type    = "metric alert"
  query   = "avg(last_5m):avg:kubernetes_state.node.memory_{aws_autoscaling_groupname:*} by {aws_autoscaling_groupname} > 250000000000"
  message = <<-EOF
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_alert}} 

    ${title(var.aws_autoscaling)}'s memory usage is High! Please consider recent changes, or adding addtional memory resources to meet safely the demand. 

    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_recovery}}
    EOF

  notify_audit        = false
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "aws:${title(var.aws_autoscaling)}",
    "k8s",
    "managed_by:terraform"
  ]
}

resource "datadog_monitor" "Low_Disk_Space" {
  name    = "${title(var.aws_autoscaling)} has Low Ephemeral Storage"
  type    = "query alert"
  query   = "avg(last_5m):avg:kubernetes_state.node.ephemeral_storage_{kube_cluster_name:*} - avg:kubernetes_state.node.ephemeral_storage_allocatable{kube_cluster_name:*} < 10000000000"
  message = <<-EOF
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_alert}} 

    ${title(var.aws_autoscaling)} has low disk space! Consider adding more resources of find the cause of the unexpected disk spend!

    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_recovery}}
    EOF

  monitor_thresholds {
    critical          = 10000000000
    warning           = 15000000000
    critical_recovery = 19000000000
    warning_recovery  = 18000000000
  }

  notify_audit        = true
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3

  tags = [
    "alert:${var.alert_recipients_testing}",
    "aws:${title(var.aws_autoscaling)}",
    "k8s",
    "managed_by:terraform"
  ]
}
