    #################
    #---SECTIONS:---#
    #################
        #1. SECRETS
        #2. ALERT ROUTING
        #3. ALERT TAGSS
        #4. RESTRICTED ROLES
        #5. CONTEXT
        #6. MONITOR DEFINITION
        #7. MONITOR ATTRIBUTES
        #8. SERVICES

#-----SECRETS-----#
variable "api_key"{
    description = "api_key from Datadog site"
    default     = "<app_key>"
}

variable "app_key"{
    description = "app_key from Datadog site"
    default     = "<app_key>"
}

variable "region" {
    description = "aws region"
    default     = "us-east-1"
}

#-----ALERT ROUTING-----#
variable "alert_recipients" {
    type = map
    description = "Alert recipients per team and environment"
    default = {
        prod = {
            <teamName>       = ["@datadog-alerts"]
            <teamName>       = ["@datadog-alerts"]
        }
        staging = {
            <teamName>       = ["@datadog-alerts"]
            <teamName>       = ["@datadog-alerts"]
        }
    }
}

variable "alert_recipients_testing" {
    type = string
    description = "Alert recipients per team and environment"
        default = "@slack-datadog-testing"
}

variable "alert_staging_testing" {
    type = string
    description = "Alert recipients per team and environment"
        default = "@datadog-staging-warnings"
}

#-----RESTRICTRED ROLES-----#
variable "restricted_roles_map" {
    type                   = map(set(string))
    description            = "Monitors mapped to names of roles in Datadog"
    default                = {}
}

#-----SERVICES-----#
variable "service" {
    description = "Mapping of services to owner and web framework"
    type = map
    default = {
        service_1 = {
            team        = "<team_Name>"
            framework   = "flask"
        }
        service_2 = {
            team        = "<team_Name>"
            framework   = "flask"
        }
    }
}

variable "clusterName"{
    description = "aws-level cluster names"
    type        = map
    default = {
        production = {name = "production"}
        staging    = {name = "staging"}
        services   = {name = "services"}
    }
}

#-----KUBE NAMESPACES-----#
variable "hpa"{
    description = "Namespace for autoscalers"
    type        = map
    default = {
        hpa_1 = {
                name      = "ambassador"
                team      = "apps"
                framework = "flask"
            }
        hpa_2 = {
                name      = "ambassador-asyncrequest-daemon"
                team      = "apps"
                framework = "flask"
            }
       }
}

#-----RDS VARIABLES-----#
variable "db_identifier"{
    description = "production database(s) identifiers"
    default     = {
        prod_db  = [<prodDBVars>]
        stage_db = [<stagingDBVars>]
    }
}

#-----RABBITMQ-----#
variable "rabbit_prod_pods" {
    description = "Environment variables for montors (mostly used for Rabbitmq monitors)"
    type    = map
    default = {
        prod_queue-0 = {name = "prod_queue-0"}
        prod_queue-1 = {name = "prod_queue-1"}
        prod_queue-2 = {name = "prod_queue-2"}
    } 
}


variable "rabbit_stage_pods" {
    description = "Environment variables for montors (mostly used for Rabbitmq monitors)"
    type    = map
    default = {
        staging_queue-0 = {name = "staging_queue-0"}
        staging_queue-1 = {name = "staging_queue-1"}
        staging_queue-2 = {name = "staging_queue-2"}
   } 
}

variable "aws_autoscaling" {
    description = "Map of Nodes for aws_autoscaling"
    type = map
    default = {
            production-jubilee-dmz20220608152027872000000019 = {name = "production-jubilee-dmz20220608152027872000000019"}
            production-jubilee-generic2022060815202787200000001a = {name = "production-jubilee-generic2022060815202787200000001a"}
            production-jubilee-infra2022060815202787220000001c = {name = "production-jubilee-infra2022060815202787220000001c"}
            production-jubilee-nlp2022060815202787210000001b = {name = "production-jubilee-nlp2022060815202787210000001b"}
            services-default2021052521263004800000000e = {name = "services-default2021052521263004800000000e"}
            staging-fuji-generic2021011417541230030000001d = {name = "staging-fuji-generic2021011417541230030000001d"}
            staging-fuji-infra20220512201936941500000003 = {name = "staging-fuji-infra20220512201936941500000003"}
    }
}
