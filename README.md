*Terraform configuration for managing Datadog*

Here is where we are housing our codified monitors in Datadog(wip, what isn't?). As we begin to get closer to our goal of sensible observability. 
on both micro and macro levels as well as horizontially. You will find monitors modularized by:
    1. Per Service Alert 2. Ops Alerts
    3. RabbitMq Alerts
    4. Paging Alerts

Current Module Breakdown of alerts  

1. _Cluster Alerts_
   1. node not ready / node in {{cluster_name}}
   2. Node Memory Pressure 
AWS autoscaling Alerts_
   1. node not ready / node in {{cluster_name}}
   2. Node Memory Pressure 
2. Scaling alerts_
   1. kube api errors/down
   2. hpa errors 
   3. pending pods
   4. nodes have increased
   5. below desired replicas
   6. above desired replicas
Kube Alerts_
   1. deploy replica down
   2. pod restarting
   3. statefulset repliva down
   4. daemonset pod down
   5. multiple pods failing
   6. unavailable statefulset replica
   7. node status unscheduable
   8. k8s imagepullbackoff
   9. pending pods
3. Service Alerts_
   1. service errors
   2. service container restart
   3. service crashloop
   4. pod status terminated
   5. pod not ready
   6. pod recent restarts
   7. pod status error
   8. oom detected
   9. pod crashes
   10. network rx (receive)errors
4. Rabbitmq Alerts_
   1. Rabbitmq Queue Status (move back from Readme)
   2. Rabbitmq High Memory Critical
   3. Rabbitmq High Queue Count
   4. Node Down (Includes pod.phase if it's not in a running state)
   5. Rabbitmq High message count
   6. Rabbitmq disk usage
   7. Rabbitmq unacknowledged rate too high
5. Rabbitmq Staging alerts_
   1. Rabbitmq Queue Status (move back from Readme)
   2. Rabbitmq High Memory Critical
   3. Rabbitmq High Queue Count
   4. Node Down (Includes pod.phase if it's not in a running state)
   5. Rabbitmq High message count
   6. Rabbitmq disk usage
   7. Rabbitmq unacknowledged rate too high
6. RDS Alerts_
   1. RDS Replica Lag
   2. RDS swap
   3. RDS Free Memory
   4. RDS Connections
   5. RDS High CPU
   6. RDS Disk Queue
7. Paging Alerts_
   1. SLA
   2.  Slow

*Alert Rules and Routing*
     While we are establishing alerts and alerting rules, we are also establishing alerting routes. These are currently in flux so while we are fine tuning and calibrating our monitors, these routes are commented out of the alerts being managed by this repo. Once the alert is established as fully tactically operational the appropriate alert routing will be uncommented and applied
     
 
Possible duplicate monitors: 
1. RabbitMq (queue_status: -- this is covered with the Node down alert)
 
```tf
resource "datadog_monitor" "queue_status" {
    name = "Rabbitmq Status Error"
    type = "query_alert"
    query = "avg(last_1m):max:kubernetes_state.pod.status_phase{pod_name:idle-narwhal-rabbitmq-0} by {pod_phase,pod_name} + max:kubernetes_state.pod.status_phase{pod_name:idle-narwhal-rabbitmq-1} by {pod_phase,pod_name} + max:kubernetes_state.pod.status_phase{pod_name:idle-narwhal-rabbitmq-2} by {pod_phase,pod_name} < 1"
    message = <<-EOM

    EOM

    monitor_thresholds {
        critical = 0
    }

    require_full_window = false
    notify_no_data = false
    renotify_interval = 0
    include_tags = true

    tags = [
        "rabbitmq",
        "managed_by:terraform"
    ]
}
```

TODO
1. Ticketing Backlog
2. Organization - create - Chris/Gabe/Brian
    1. add users  (parent/child org) - Chris/Gabe
     ```tfO
     module "datadog_child_organization" {
          source = "/platform/datadog//modules/child_organization"
          # version = "x.x.x" //PINNED VERSION(YOU CAN DELETE THE COMMENT)

          organization_name                = "test"
          saml_enabled                     = false  # Note that Free and Trial organizations cannot enable SAML
          saml_autocreate_users_domains    = []
          saml_autocreate_users_enabled    = false
          saml_idp_initiated_login_enabled = true
          saml_strict_mode_enabled         = false
          private_widget_share             = false
          saml_autocreate_access_role      = "ro"

          context = module.this.context
        }
     ```
    2. adding roles (and how this will help with auditing - Brian/Adam - we will have to define roles. I can start with some that make sense - look to see what we are using with AWS and mimic that mimic that)
    ```tf
    module "monitor_configs" {
      source  = "/config/yaml"
      version = "0.8.1"

      map_config_local_base_path = path.module
      map_config_paths           = var.monitor_paths

      context = module.this.context
    }

    module "role_configs" {
      source  = "/config/yaml"
      version = "0.8.1"

      map_config_local_base_path = path.module
      map_config_paths           = var.role_paths

      context = module.this.context
    }

    locals {
      monitors_write_role_name    = module.datadog_roles.datadog_roles["monitors-write"].name
      monitors_downtime_role_name = module.datadog_roles.datadog_roles["monitors-downtime"].name

      monitors_roles_map = {
        aurora-replica-lag              = [local.monitors_write_role_name, local.monitors_downtime_role_name]
        ec2-failed-status-check         = [local.monitors_write_role_name, local.monitors_downtime_role_name]
        redshift-health-status          = [local.monitors_downtime_role_name]
        k8s-deployment-replica-pod-down = [local.monitors_write_role_name]
      }
    }

    module "datadog_roles" {
      source = "/platform/datadog//modules/roles"
      # version = "x.x.x"

      datadog_roles = module.role_configs.map_configs

      context = module.this.context
    }

    module "datadog_monitors" {
      source = "/platform/datadog//modules/monitors"
      # version = "x.x.x"

      datadog_monitors     = module.monitor_configs.map_configs
      alert_tags           = var.alert_tags
      alert_tags_separator = var.alert_tags_separator
      restricted_roles_map = local.monitors_roles_map

      context = module.this.context
    }
    ```
3. (look up what it means to "pin version" that we are using ) - When using module "version" will be monitor resource attribute.
