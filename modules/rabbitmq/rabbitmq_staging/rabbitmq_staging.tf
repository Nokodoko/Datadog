
terraform {
  required_providers {
    datadog = {
            source = "Datadog/datadog"
        }
  }
}

    #-----(RMQ) Monitor List-----#
    #1a. queue_status -- (see ../../README.md for this monitor if not deemed a duplicate)

    #1. high_message_count
    #2. rabbitmq_memory_usage_is_high
    #3. node down

resource "datadog_monitor" "high_message_count"{
    name               = "(RMQ) ${var.rabbit_stage_pods} High Message Count"
    type               = "query alert"
    query              = "avg(last_5m):avg:rabbitmq.overview.queue_totals.messages.count{environment:production} > 30000"
    message            = <<-EOM
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients}{{/is_exact_match}} 
    {{/is_alert}} 

    abnormal memory usage on the rabbitmq cluster in {{kube_cluster_name.name}}, current cluster usage is `{{value}}` percent

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients}{{/is_exact_match}} 
    {{/is_recovery}}
    EOM

    require_full_window = false
    notify_audit        = false
    notify_no_data      = false
    renotify_interval   = 0
    include_tags        = true
    
    monitor_thresholds {
        critical        = 30000
    }

    tags = [
        "rmq:${var.rabbit_stage_pods}",
        "managed_by:terraform"
    ]
}

resource "datadog_monitor" "rabbitmq_memory_usage_is_high"{
    name                = "(RMQ) ${var.rabbit_stage_pods} Memory Usage is High"
    type                = "query alert"
    query               = "avg(last_12h):anomalies(avg:rabbitmq.node.mem_used{*} by {kube_cluster_name} / avg:rabbitmq.node.mem_limit{*} by {kube_cluster_name} * 100, 'agile', 2, direction='above', interval=120, alert_window='last_30m', seasonality='hourly', timezone='utc', count_default_zero='true') > 1"
    message             = <<-EOM
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}@${var.alert_recipients}{{/is_exact_match}} 
    {{/is_alert}} 

    abnormal memory usage on the rabbitmq cluster in {{kube_cluster_name.name}}, current cluster usage is `{{value}}` percent

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}@${var.alert_recipients}{{/is_exact_match}} 
    {{/is_recovery}}
    EOM
    monitor_threshold_windows {
        recovery_window   = "last_5m"
        trigger_window    = "last_30m"
    }

    monitor_thresholds {
        critical          = 1
        critical_recovery = 0
    }

    require_full_window   = false
    notify_no_data        = false
    new_group_delay       = 60

    tags = [
        "rmq:${var.rabbit_stage_pods}",
        "managed_by:terraform",
    ]
}

resource "datadog_monitor" "node_is_down" {
    name                  = "(RMQ) ${var.rabbit_stage_pods} Node is down"
    type                  = "query alert"
    query                 = "max(last_1m):max:kubernetes_state.pod.status_phase{pod_name:idle-narwhal-rabbitmq-0} by {pod_phase,pod_name} < 0"
    message               = <<-EOM
    {{#is_alert}}
    ${var.alert_recipients} 
    Rabbitmq Pod {{pod_name.name}} is in a {{pod_phase.name}} phase. 
    If you have access please see rabbitui.aisoftware.com for more details (login information is in LastPass)
    {{/is_alert}} 

    {{#is_recovery}}
    ${var.alert_recipients} 
    Rabbitmq pod {{pod_name.name}} has recovered into a running state.
    {{/is_recovery}} 
    EOM

    notify_audit           = true
    include_tags           = true

    monitor_thresholds {
        critical           = 0
        critical_recovery  = 1
    }

    require_full_window    = false
    notify_no_data         = false
    renotify_interval      = 0
    new_group_delay        = 60
    priority               = 3

    tags = [
        "rmq:${var.rabbit_stage_pods}",
        "managed_by:terraform"
    ]
}

resource "datadog_monitor" "rabbitmq_disk_usage_high" {
    name = "(RMQ) ${var.rabbit_stage_pods} Disk Usage is High"
    type = "query alert"
    query = "avg(last_5m):avg:rabbitmq.node.mem_used{*} by {host} / avg:system.mem.total{*} by {host} * 100 > 35"
    message = <<-EOM
    RabbitMQ is using too many resources on host: {{host.name}}.
    It may block connections and won't be able to perform many internal operations.
    EOM

    monitor_thresholds {
        critical = 35
        warning = 30
    }

    require_full_window     = true
    notify_no_data          = false
    renotify_interval       = 0
    new_group_delay         = 0
    evaluation_delay        = 60
    priority                = 1
    include_tags            = true

    tags = [
        "rmq:${var.rabbit_stage_pods}",
        "managed_by:terraform"
    ]
}

resource "datadog_monitor" "rabbitmq_messages_unacknowleged" {
    name = "(RMQ) ${var.rabbit_stage_pods} Unacknowledged Message Rate is High"
    type = "query alert"
    query = "avg(last_4h):anomalies(avg:rabbitmq.queue.messages_unacknowledged.rate{*} by {rabbitmq_queue,host}, 'agile', 2, direction='above', alert_window='last_15m', interval=60, count_default_zero='true', seasonality='hourly') >= 1"
    message = <<-EOM
    The rate at which messages are being delivered without receiving acknowledgement is higher than usual.
    There may be errors or performance issues downstream.\n
    Host: {{host.name}}\n
    RabbitMQ Queue: {{rabbitmq_queue.name}}
    EOM

    monitor_thresholds {
      critical = 1
      critical_recovery = 0
    }

    require_full_window = true
    force_delete        = true
    notify_audit        = true
    notify_no_data      = false
    renotify_interval   = 0
    new_group_delay     = 0
    priority            = 1
    include_tags        = true

    tags = [
        "rmq:${var.rabbit_stage_pods}",
        "managed_by:terraform"
    ]
}
