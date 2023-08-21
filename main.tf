terraform {
  required_providers {
    datadog = {
      source = "Datadog/datadog"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket  = "aisoftware-ops"
    key     = "terraform/datadog-tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}


provider "aws" {
  region = var.region
}

provider "datadog" {
  api_key = var.api_key
  app_key = var.app_key
}

#-----BASE MONITORS-----#
#1. MONITOR: no_audit_logs
resource "datadog_monitor" "no_audit_logs" {
  name    = "No Recent Audit Logs"
  type    = "query alert"
  query   = "max(last_15m):abs(sum:most_recent_audit_log_id{*}.as_rate() - day_before(sum:most_recent_audit_log_id{*}.as_rate())) <= 0"
  message = <<-EOM
    {{#is_alert}}
    ${var.alert_recipients_testing}
    {{/is_alert}} 

    no audit logs detected in `equity_jane.audit_log` in the last 15 minutes. check status of `audit-daemon` in production!

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
    "base",
    "managed_by:terraform"
  ]
}


#2. MONITOR: clockskew_sync
#resource "datadog_monitor" "clockskew_sync" {
#    name               = "[Auto] Clock in sync with NTP"
#    type               = "service check"
#    query              = "\"ntp.in_sync\".over(\"*\").last(2).count_by_status()"
#    message            = <<-EOM
#    {{#is_alert}}
#    ${var.alert_recipients_testing}
#    {{/is_alert}} 
#
#    Triggers if any host's clock goes out of sync with the time given by NTP. The offset threshold is configured in the Agent's `ntp.yaml` file.
#
#    Please read the [KB article](https://docs.datadoghq.com/agent/faq/network-time-protocol-ntp-offset-issues) on NTP Offset issues for more details on cause and resolution.
#    {{#is_recovery}}
#    ${var.alert_recipients_testing}
#    {{/is_recovery}}
#    EOM
#
#    monitor_thresholds {
#      warning           = 1
#      ok                = 1
#      critical          = 1
#    }
#
#    notify_audit        = true
#    require_full_window = false
#    renotify_interval   = 0
#    include_tags        = true
#    priority            = 3
#
#    tags = [
#        "alert:${var.alert_recipients_testing}",
#        "base",
#        "managed_by:terraform"
#    ]
#}


#2. MONITOR: instance_down
resource "datadog_monitor" "instance_down" {
  name    = "Instance Down for 3 Minutes"
  type    = "query alert"
  query   = "min(last_3m):max:aws.ec2.status_check_failed_instance{cluster_name:production} by {instance-type} > 0"
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

  notify_audit        = true
  require_full_window = false
  renotify_interval   = 0
  include_tags        = true
  priority            = 3
  evaluation_delay    = 900

  tags = [
    "alert:${var.alert_recipients_testing}",
    "base",
    "managed_by:terraform"
  ]
}


resource "datadog_monitor" "vpn_site_to_site" {
  name    = "VPN: Site to site down"
  type    = "query alert"
  query   = "avg(last_5m):avg:aws.vpn.tunnel_state{vpnid:vpn-026358002d035d56e} <= 0"
  message = <<-EOM
    {{#is_alert}}
    ${var.alert_recipients_testing}
    {{/is_alert}} 

    Site to Site VPN is down! Check office Meraki device and AWS VPC Site-to-Site settings

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
    "base",
    "managed_by:terraform"
  ]
}
