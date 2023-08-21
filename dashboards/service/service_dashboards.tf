terraform {
  required_providers {
    datadog = {
      source = "Datadog/datadog"
    }
  }
}

resource "datadog_dashboard" "service" {
  title       = "${title(var.service)} Dashboard"
  description = "The health of your service at a glance."
  layout_type = "free"

  widget {
    event_stream_definition {
      query       = "*"
      event_size  = "l"
      title       = "${title(var.service)} Events"
      title_size  = 16
      title_align = "left"
      live_span   = "1h"
    }
    widget_layout {
      height = 43
      width  = 32
      x      = 0
      y      = 0
    }
  }

  widget {
    event_timeline_definition {
      query       = "*"
      title       = "${title(var.service)} Timeline"
      title_size  = 16
      title_align = "left"
      live_span   = "1h"
    }
    widget_layout {
      height = 9
      width  = 66
      x      = 33
      y      = 60
    }
  }

  widget {
    free_text_definition {
      text       = "${title(var.service)} Dashboard"
      color      = "#d00"
      font_size  = "36"
      text_align = "left"
    }
    widget_layout {
      height = 20
      width  = 34
      x      = 33
      y      = 0
    }
  }

  widget {
    iframe_definition {
      url = "http://google.com"
    }
    widget_layout {
      height = 46
      width  = 39
      x      = 101
      y      = 0
    }
  }

  widget {
    image_definition {
      url    = "https://images.pexels.com/photos/67636/rose-blue-flower-rose-blooms-67636.jpeg?auto=compress&cs=tinysrgb&h=350"
      sizing = "fit"
      margin = "small"
    }
    widget_layout {
      height = 20
      width  = 30
      x      = 69
      y      = 0
    }
  }

  widget {
    log_stream_definition {
      indexes             = ["main"]
      query               = "error"
      columns             = ["core_host", "core_service", "tag_source"]
      show_date_column    = true
      show_message_column = true
      message_display     = "expanded-md"
      sort {
        column = "time"
        order  = "desc"
      }
    }
    widget_layout {
      height = 36
      width  = 32
      x      = 0
      y      = 45
    }
  }

  widget {
    manage_status_definition {
      color_preference    = "text"
      display_format      = "countsAndList"
      hide_zero_counts    = true
      query               = "type:metric"
      show_last_triggered = false
      sort                = "status,asc"
      summary_type        = "monitors"
      title               = "${title(var.service)} Monitors"
      title_size          = 16
      title_align         = "left"
    }
    widget_layout {
      height = 40
      width  = 30
      x      = 101
      y      = 48
    }
  }

  widget {
    trace_service_definition {
      display_format     = "three_column"
      env                = "prod"
      service            = var.service
      show_breakdown     = true
      show_distribution  = true
      show_errors        = true
      show_hits          = true
      show_latency       = true
      show_resource_list = true
      size_format        = "large"
      span_name          = "cassandra.query"
      title              = "${title(var.service)} #env:${var.env}"
      title_align        = "center"
      title_size         = "13"
      live_span          = "1h"
    }
    widget_layout {
      height = 38
      width  = 66
      x      = 33
      y      = 21
    }
  }

  widget {
    timeseries_definition {
      request {
        formula {
          formula_expression = "my_query_1 + my_query_2"
          alias              = "my ff query"
        }
        formula {
          formula_expression = "my_query_1 * my_query_2"
          limit {
            count = 5
            order = "desc"
          }
          alias = "my second ff query"
        }
        query {
          metric_query {
            data_source = "metrics"
            query       = "avg:system.cpu.user{app:general} by {env}"
            name        = "my_query_1"
            aggregator  = "sum"
          }
        }
        query {
          metric_query {
            query      = "avg:system.cpu.user{app:general} by {env}"
            name       = "my_query_2"
            aggregator = "sum"
          }
        }
      }
    }
    widget_layout {
      height = 16
      width  = 25
      x      = 58
      y      = 83
    }
  }
  widget {
    timeseries_definition {
      request {
        query {
          event_query {
            name        = "my-query"
            data_source = "logs"
            indexes     = ["days-3"]
            compute {
              aggregation = "count"
            }
            group_by {
              facet = "host"
              sort {
                metric      = "@lambda.max_memory_used"
                aggregation = "avg"
              }
              limit = 10
            }
          }
        }
      }
    }
    widget_layout {
      height = 16
      width  = 28
      x      = 29
      y      = 83
    }
  }
  widget {
    timeseries_definition {
      request {
        query {
          process_query {
            data_source       = "process"
            text_filter       = "abc"
            metric            = "process.stat.cpu.total_pct"
            limit             = 10
            tag_filters       = ["some_filter"]
            name              = "my_process_query"
            sort              = "asc"
            is_normalized_cpu = true
            aggregator        = "sum"
          }
        }
      }
    }
    widget_layout {
      height = 16
      width  = 28
      x      = 0
      y      = 83
    }
  }

  template_variable {
    name    = "var_1"
    prefix  = "host"
    default = "aws"
  }
  template_variable {
    name    = "var_2"
    prefix  = "service_name"
    default = "autoscaling"
  }

  template_variable_preset {
    name = "preset_1"
    template_variable {
      name  = "var_1"
      value = "host.dc"
    }
    template_variable {
      name  = "var_2"
      value = "my_service"
    }
  }
}
