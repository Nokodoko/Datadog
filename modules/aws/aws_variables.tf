variable "aws_autoscaling" {
    type = string
    description = "AWS autoscaling node group"
}

##-----ALERT ROUTING-----#
variable "alert_recipients_testing" {
    type        = string
    description = "Alert recipients per team and environment"
}

