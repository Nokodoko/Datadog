    #################
    #---SECTIONS:---#
    #################
        #1. CLUSTERNAME
        #2. ALERT_RECIPIENTS_TESTING

variable "clusterName" {
    type        = string
    description = "Mapping of services to owner and web framework"
}

variable "alert_recipients_testing" {
    type        = string
    description = "Alert recipients per team and environment"
}
