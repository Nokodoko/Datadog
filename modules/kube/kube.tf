terraform {
  required_providers{
        datadog = {
            source = "Datadog/datadog"
        }
    }
}

    #########################
    #-----MONITOR ORDER-----#
    #########################
    #1. k8s_deployment_replica_is_down
    #2. pods_restarting
    #3. daemonset_pod_down
    #4. statefulset-replica-down
    #5. daemonset_pod_down
    #6. multi_pods_failing
    #7. unavailable_statefulset_replica
    #8. node_status_unschedulable
    #9. k8s_imagepullbackoff
   #10. pending_pods 

#1. MONITOR: k8s_deployment_replica_is_down
resource "datadog_monitor" "k8s_deployment_replica_is_down" {
    name               = "(k8s) ${title(var.service)} Deployement Replica is down"
    type               = "query alert"
    query              = "avg(last_15m):avg:kubernetes_state.deployment.replicas_desired{*} by {cluster_name,deployment} - avg:kubernetes_state.deployment.replicas_ready{*} by {cluster_name,deployment} >= 2"
    message            = <<-EOM
    ({{cluster_name.name}}) More than one Deployments Replica's pods are down on {{deployment.name}}
    EOM

    monitor_thresholds {
      critical          = 2
    }

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#2. MONITOR: pods_restarting
resource "datadog_monitor" "pods_restarting" {
    name               = "(k8s) ${title(var.service)} Pods are restarting several times"
    type               = "query alert"
    query              = "change(sum(last_5m),last_5m):exclude_null(avg:kubernetes.containers.restarts{*} by {cluster_name,kube_namespace,pod_name}) > 5"
    message            = <<-EOM
    ({{cluster_name.name}}) pod {{pod_name.name}} is restarting multiple times on {{kube_namespace.name}}
    EOM

    monitor_thresholds {
        critical        = 5
        warning         = 3
    }

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#3. MONITOR: statefulset-replica-down
resource "datadog_monitor" "statefulset-replica-down" {
    name                = "(k8s) ${title(var.service)} Statefulset Replica Pod is Down"
    type                = "query alert"
    query               = "max(last_15m):sum:kubernetes_state.statefulset.replicas_desired{*} by {cluster_name,kube_namespace,statefulset} - sum:kubernetes_state.statefulset.replicas_ready{*} by {cluster_name,kube_namespace,statefulset} >= 2"
    message             = <<-EOM
    ({{cluster_name.name}} {{statefulset.name}}) More than one StatefulSet Replica's pods are down on {{kube_namespace.name}}
    EOM

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#4. MONITOR: daemonset_pod_down
resource "datadog_monitor" "daemonset_pod_down" {
    name               = "(k8s) ${title(var.service)} Daemonset Pod is Down"
    type               = "query alert"
    query              = "max(last_15m):sum:kubernetes_state.daemonset.desired{*} by {cluster_name,kube_namespace,daemonset} - sum:kubernetes_state.daemonset.ready{*} by {cluster_name,kube_namespace,daemonset} >= 1"
    message            = <<-EOM
    ({{cluster_name.name}} {{daemonset.name}}) One or more DaemonSet pods are down on {{kube_namespace.name}}
    EOM

    monitor_thresholds {
      critical          = 1
    }
    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#5. MONITOR: multi_pods_failing
resource "datadog_monitor" "multi_pods_failing" {
    name    = "(k8s) ${title(var.service)} Mulitple pods failing"
    type    = "query alert"
    query   = "change(avg(last_5m),last_5m):sum:kubernetes_state.pod.status_phase{phase:failed} by {cluster_name,kube_namespace} > 10"
    message = <<-EOM
    ({{cluster_name.name}}) Detected unavailable Deployment replicas for longer than 10 minutes on {{kube_namespace.name}}
    EOM

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#6. MONITOR: unavailable_statefulset_replica
resource "datadog_monitor" "unavailable_statefulset_replica" {
    name = "(k8s) ${title(var.service)} Statefulset Replica(s) are unavailable"
    type = "metric alert"
    query = "max(last_10m):max:kubernetes_state.statefulset.replicas_unavailable{*} by {cluster_name,kube_namespace} > 0 "
    message = <<-EOM
    ({{cluster_name.name}}) Detected unavailable Statefulset replicas for longer than 10 minutes on {{kube_namespace.name}}
    EOM

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#7. MONITOR: node_status_unschedulable
resource "datadog_monitor" "node_status_unschedulable" {
    name = "(k8s) ${title(var.service)} Unschedulable Node found"
    type  = "query alert"
    query = "max(last_15m):sum:kubernetes_state.node.status{status:schedulable} by {cluster_name} * 100 / sum:kubernetes_state.node.status{*} by {cluster_name} < 80"
    message = <<-EOM
    More than 20% of nodes are unschedulable on ({{cluster_name}} cluster). \n Keep in mind that this might be expected based on your infrastructure.
    EOM

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#8. MONITOR: k8s_imagepullbackoff
resource "datadog_monitor" "k8s_imagepullbackoff" {
    name = "(k8s) ${title(var.service)} ImagepullBackoff Found"
    type = "query alert"
    query = "max(last_10m):max:kubernetes_state.container.status_report.count.waiting{reason:imagepullbackoff} by {kube_cluster_name,kube_namespace,pod_name} >= 1 "
    message = <<-EOM
    Pod {{pod_name.name}} is ImagePullBackOff on namespace {{kube_namespace.name}}
    EOM

    notify_audit        = true
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "pods",
        "k8s",
        "managed_by:terraform"
    ]
}

#9. MONITOR: pending_pods 
resource "datadog_monitor" "pending_pods" {
    name                = "(k8s) ${title(var.service)} Pods Pending"
    type                = "metric alert"
    query               = "min(last_30m):sum:kubernetes_state.pod.status_phase{phase:running} by {cluster_name} - sum:kubernetes_state.pod.status_phase{phase:running} by {cluster_name} + sum:kubernetes_state.pod.status_phase{phase:pending} by {cluster_name}.fill(zero) >= 1"
    message             = <<-EOM
    ({{cluster_name.name}}) There has been at least 1 pod Pending for 30 minutes.
    There are currently ({{value}}) pods Pending.
    EOM

    monitor_thresholds {
        critical         = 1
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "k8s",
        "pods",
        "managed_by:terraform"
    ]
}

resource "datadog_monitor" "nodes_have_increased" {
    name    = "(k8s) ${title(var.service)} Total Nodes Have Increased"
    type    = "query alert"
    query   = "avg(last_5m):per_minute(sum:cluster_autoscaler_nodes_count{state:ready} by {kube_cluster_name}) > 100"
    message = <<-EOM
    {{#is_warning}}
    {{#is_exact_match "kube_cluster_name.name" "production"}}@slack--ops-datadog-warnings  {{/is_exact_match}}
    {{#is_exact_match "kube_cluster_name.name" "staging"}}@slack--ops-datadog-staging-warnings   {{/is_exact_match}}
    {{/is_warning}} 

    Cluster has scaled in new nodes recently
    EOM

    monitor_thresholds {
        critical = 100
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 5

    tags = [
        "alert:${var.alert_recipients}",
        "env:${var.env}",
        "team:${var.team}",
        "k8s",
        "pods",
        "managed_by:terraform"
    ]

}
