terraform {
    required_providers {
        datadog = {
            source = "Datadog/datadog"
        }
    }
}
    #-----MONITOR ORDER-----#
    #1. node_not_ready
    #2. kube_api_down
    #3. pod_crashes
    #4. hpa_errors
    #5.Daemonset Unschedulable
    #6. pending_pods
    #7. network_rx_errors



#2. MONITOR: kube_api_error -- by host - should be a different set of monitors 
resource "datadog_monitor" "kube_api_error" {
    name               = "(hpa) ${var.hpa} KubeAPI Error:{{value}}"
    type               = "event-v2 alert"
    query              = "events(\"@evt.type:kubernetes_apiserver status:error\").rollup(\"count\").by(\"kube_cluster_name,pod_name,@evt.type,@event_object\").last(\"5m\") > 1"
    message            = <<-EOF
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_alert}} 

    ERROR:
    {{event.id}} 
    {{event.title}}
    {{@event_object.name}}  

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_recovery}}
    EOF

    monitor_thresholds {
        critical       = 1
    }

    #enable_log_sample   = true
    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3
    new_group_delay     = 60

    tags = [
        "alert:${var.alert_recipients_testing}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}


#3. MONITOR: hpa_errors - should be a different set of monitors 
resource "datadog_monitor" "hpa_errors" {
    name                = "(hpa) HPA Errors ${var.hpa} with {{resource_name.name}}"
    type                = "event-v2 alert"
    query               = "events(\"source:kubernetes @priority:all \\\"unable to fetch metrics from resource metrics API:\\\"\").rollup(\"count\").by(\"${var.hpa}, pod_name, service,resource_name\").last(\"1m\") > 5"
    message             = <<-EOF
    {{#is_alert}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_alert}} 

    {{value}} in {{kube_cluster_name.name}} 
    Pod        :{{pod_name.name}} 
    Resource   :{{resource_name.name}} 
    Service    :{{service.name}} 

    {{#is_recovery}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}${var.alert_recipients_testing}{{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}${var.alert_recipients_testing}{{/is_exact_match}} 
    {{/is_recovery}}
    EOF
    monitor_thresholds {
        critical        = 5
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients_testing}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}


#4. MONITOR: below desired replicased
resource "datadog_monitor" "below_desired_replicas" {
    name                 = "(hpa) ${var.hpa} is below the desired {{kubernetes_state.hpa.desired_replicas}} replicas"
    type                 = "query alert"
    query                = "sum(last_1m):avg:kubernetes_state.hpa.current_replicas{${var.hpa}} by {${var.hpa}} - avg:kubernetes_state.hpa.desired_replicas{horizontalpodautoscaler:*} by {horizontalpodautoscaler} < 0"
    message              = <<-EOF
    {{#is_alert}}\nService {{${var.hpa}.name}} is below the desired replica count of {{kubernetes_state.hpa.desired_replicas}} by {{value}}.\n{{/is_alert}}

    Alert: ${var.alert_recipients_testing}
    EOF

    monitor_thresholds {
        critical          = 0
        critical_recovery = 0.1
    }

    notify_audit          = false
    require_full_window   = false
    renotify_interval     = 0
    include_tags          = true
    priority              = 3

    tags = [
        "alert:${var.alert_recipients_testing}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#5. MONITOR: above desired replicased
resource "datadog_monitor" "above_desired_replicas" {
    name                 = "(hpa) ${var.hpa} is above the desired {{kubernetes_state.hpa.desired_replicas}} replicas"
    type                 = "query alert"
    query                = "sum(last_1m):avg:kubernetes_state.hpa.current_replicas{${var.hpa}} by {${var.hpa}} - avg:kubernetes_state.hpa.desired_replicas{horizontalpodautoscaler:*} by {horizontalpodautoscaler} > 0"
    message              = <<-EOF
    {{#is_alert}}
    Service {{${var.hpa}.name}} is above the desired replica count of {{kubernetes_state.hpa.desired_replicas}} by {{value}}.
    Alert: ${var.alert_recipients_testing}
    {{/is_alert}}
    EOF

    monitor_thresholds {
        critical          = 0
        critical_recovery = -0.1
    }

    notify_audit          = false
    require_full_window   = false
    renotify_interval     = 0
    include_tags          = true
    priority              = 3

    tags = [
        "alert:${var.alert_recipients_testing}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}
