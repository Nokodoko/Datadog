terraform {
    required_providers {
      datadog = {
            source = "Datadog/datadog"
        }
    }
}

    #-----MONITOR ORDER:-----#
    #1.RDS_REPLICA_LAG
    #2.RDS_SWAP
    #3.RDS_FREE_MEMORY
    #4.RDS_CONNECTIONS
    #5.RDS_HIGH_CPU_ANALYTICS
    #6.RDS_DISK_QUEUE_DEPTH


#1. MONITOR: rds_replica_lag
resource "datadog_monitor" "rds_replica_lag" {
    name    = "(RDS) ${var.db_identifier} Replica Lag"
    type    = "query alert"
    query   = "avg(last_5m):avg:aws.rds.replica_lag{*} by {dbinstanceidentifier} > 7200"
    message = <<-EOM
    {{#is_warning}}
    replica lag is currently {{value}} on {{dbinstanceidentifier.name}}
    {{/is_warning}} 
    {{#is_alert}}
    replica lag is currently {{value}} on {{dbinstanceidentifier.name}}
    {{/is_alert}}
    EOM

    monitor_thresholds {
        critical        = 7200
        warning         = 3600
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3
    tags = [
        "rds",
        "mariaddb",
        "managed_by:terraform"
    ]
} 

#2.MONITOR: rds_swap
resource "datadog_monitor" "rds_swap" {
    name    = "(RDS) ${var.db_identifier} Swap use is above 256 MB"
    type    = "query alert"
    query   = "avg(last_15m):avg:aws.rds.swap_usage{*} by {dbinstanceidentifier} > 256000000"
    message = <<-EOM
    {{#is_warning}}
    ({dbinstanceidentifier}) Swap usage above 128 MB
    {{/is_warning}}
    {{#is_alert}}
    ({dbinstanceidentifier}) Swap usage above 256 MB
    {{/is_alert}}
    EOM

    monitor_thresholds {
        critical        = 256000000
        warning         = 128000000
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3
    tags = [
        "rds",
        "mariaddb",
        "managed_by:terraform"
    ]
}

#3. MONITOR: rds_free_memory
resource "datadog_monitor" "rds_free_memory" {
    name    = "(RDS) ${var.db_identifier} Free Memory below 256 MB"
    type    = "query alert"
    query   = "avg(last_5m):avg:aws.rds.freeable_memory{*} < 256000000"
    message = <<-EOM
    {{#is_warning}}
    ({dbinstanceidentifier}) Freeable memory below 512 MB
    {{/is_warning}}
    {{#is_alert}}
    ({dbinstanceidentifier}) Freeable memory below 256 MB
    {{/is_alert}}
    EOM

    monitor_thresholds {
        critical = 256000000
        warning = 512000000
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3
    tags = [
        "rds",
        "mariaddb",
        "managed_by:terraform"
    ]
}

#4. MONITOR: rds_connections
resource "datadog_monitor" "rds_connections" {
    name    = "(RDS) ${var.db_identifier} Anomaly of a large variance in RDS connection count"
    type    = "query alert"
    query   = "avg(last_4h):anomalies(avg:aws.rds.database_connections{*}, 'basic', 2, direction='both', alert_window='last_15m', interval=60, count_default_zero='true') >= 1"
    message = <<-EOM
    {{#is_warning}}
    ({dbinstanceidentifier}) Anomaly of a large variance in RDS connection count
    {{/is_warning}}
    {{#is_alert}}
    ({dbinstanceidentifier}) Anomaly of a large variance in RDS connection count
    {{/is_alert}}
    EOM

    monitor_thresholds {
        critical        = 1
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3
    tags = [
        "rds",
        "mariaddb",
        "managed_by:terraform"
    ]
}

#5. MONITOR: rds_high_cpu_analytics
resource "datadog_monitor" "rds_high_cpu_analytics" {
    name    = "(RDS) ${var.db_identifier} CPU Utilization above 90%"
    type    = "query alert"
    query   = "avg(last_15m):avg:aws.rds.cpuutilization{*} by {dbinstanceidentifier} > 90"
    message = <<-EOM
    {{#is_warning}}
    ({dbinstanceidentifier}) CPU Utilization above 85%
    {{/is_warning}}
    {{#is_alert}}
    ({dbinstanceidentifier}) CPU Utilization above 90%
    {{/is_alert}}
    EOM

    monitor_thresholds {
        critical        = 90
        warning         = 85
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "rds",
        "mariaddb",
        "managed_by:terraform"
    ]
}

#6. MONITOR: rds_disk_queue_depth
resource "datadog_monitor" "rds_disk_queue_depth" {
    name    = "(RDS) ${var.db_identifier} Disk queue depth above 64"
    type    = "metric alert"
    query   = "avg(last_15m):avg:aws.rds.disk_queue_depth{*} by {dbinstanceidentifier} > 64"
    message = <<-EOM
    {{#is_warning}}
    ({dbinstanceidentifier}) Disk queue depth above 48
    {{/is_warning}}
    {{#is_alert}}
    ({dbinstanceidentifier}) Disk queue depth above 64
    {{/is_alert}}
    EOM

    monitor_thresholds {
        critical        = 64
        warning         = 48
    }

    notify_audit        = false
    require_full_window = false
    renotify_interval   = 0
    include_tags        = true
    priority            = 3

    tags = [
        "rds",
        "mariaddb",
        "managed_by:terraform"
    ]
}
