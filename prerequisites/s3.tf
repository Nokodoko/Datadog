resource "aws_s3_bucket" "datadog_monitor" {
    bucket          = "datadog_monitor_state"
    key             = "datadog_monitor_state/monior_state.tf"
    region          = "us-east-1"
    encrypt         = true

    tags = {
        name        = "datadog_monitor_state"
        environment = "production"
    }
}
