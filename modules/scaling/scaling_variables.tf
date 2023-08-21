    #################
    #---SECTIONS:---#
    #################
        #1. ALERT ROUTING
        #2. SERVICES

##-----ALERT ROUTING-----#
variable "alert_recipients_testing" {
    type        = string
    description = "Alert recipients per team and environment"
}

variable "env" {
    type        = string
    description = "Mapping of services to owner and web framework"
}

variable "team" {
  type        = string
  description = "Team that owns the service"
}

variable "hpa" {
    type        = string
    description = "Mapping of services to owner and web framework"
}


