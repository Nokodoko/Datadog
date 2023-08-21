#README
#######################
#-----MODULE LIST-----#
#######################
#1. KUBE
#2. OPS
#3. PAGING
#4. SERVICE
#5. RDS 
#6. RABBITMQ

#-----MONITOR MODULES-----#
module "kube" {
  source           = "./modules/kube/"
  for_each         = var.service
  service          = each.key
  team             = each.value.team
  env              = "prod"
  alert_recipients = var.alert_recipients_testing
}

module "scaling_monitors" {
  source                   = "./modules/scaling/"
  for_each                 = var.hpa
  hpa                      = each.key
  team                     = each.value.team
  env                      = "prod"
  alert_recipients_testing = var.alert_recipients_testing
}

module "aws_autoscaling" {
  source                   = "./modules/aws/"
  for_each                 = var.aws_autoscaling
  aws_autoscaling          = each.key
  alert_recipients_testing = var.alert_recipients_testing
}

module "cluster" {
  source                   = "./modules/cluster/"
  for_each                 = var.clusterName
  clusterName              = each.key
  alert_recipients_testing = var.alert_recipients_testing
}

##-----paging monitors-----#
#module "paging"  {
#    source          = "./modules/paging/paging.tf"
#    recipients      = var.alert_recipients["prod"][each.value.team]
#}

#-----service monitors-----#
module "service" {
  source                   = "./modules/service/"
  for_each                 = var.service
  service                  = each.key
  framework                = each.value.framework
  team                     = each.value.team
  env                      = "prod"
  alert_recipients_testing = var.alert_recipients_testing
  alert_staging_testing    = var.alert_staging_testing
  #recipients      = var.alert_recipients["prod"][each.value.team]
}

#-----rds modules-----#
module "rds_production_monitors" {
  source        = "./modules/rds/"
  for_each      = var.db_identifier
  db_identifier = each.key
  #alert_recipients = var.alert_recipients_testing 
}

#module "rds_stage_monitor"     {
#    source           = "./modules/rds/"
#    for_each         = var.db_identifier["stage_db"]
#    alert_recipients = var.alert_recipients_testing 
#}

#-----rabbitmq-----#
module "rabbitmq_monitor" {
  source           = "./modules/rabbitmq/"
  for_each         = var.rabbit_prod_pods
  alert_recipients = var.alert_recipients_testing
  rabbit_prod_pods = each.key
}

module "rabbitmq_staging_monitor" {
  source            = "./modules/rabbitmq/rabbitmq_staging/"
  for_each          = var.rabbit_stage_pods
  alert_recipients  = var.alert_recipients_testing
  rabbit_stage_pods = each.key
}

###############
#  DASHBOARDS #
###############

module "monitor_dashboards" {
  source   = "./dashboards/service/"
  for_each = var.service
  service  = each.key
  env      = "prod"
}

#module "rds_dashboards" {
#  source   = "./dashboards/rds/"
#  for_each = var.db_identifier
#  service  = each.key
#  env      = "prod"
#}
