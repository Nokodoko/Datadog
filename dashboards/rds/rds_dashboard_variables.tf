terraform {
  required_providers {
    datadog = {
      source = "Datadog/datadog"
    }
  }
}

resource "datadog_dashboard" "rds" {
  title       = "${title(var.dbinstanceidentifier)} Dashboard"
  description = "The health of your dbinstanceidentifier at a glance."
  layout_type = "free"

  widget {
    max_read_latency_definition {
      autoscale  = true
      event_size  = "l"
        request {
            query{

            }  "max:aws.rds.read_latency{$account, $dbinstanceidentifier}"
            aggregator = "max"
        }
    }
    widget_layout {
      height = 6
      width  = 16
      x      = 58
      y      = 0
    }
      title       = "${title(var.dbinstanceidentifier)} Events"
      title_size  = 13
      title_align = "center"
      live_span   = "1h"
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
}

    #  widget {
    #    max_write_latency_definition {
    #      title       = "${title(var.dbinstanceidentifier)} Timeline"
    #      title_size  = 16
    #      title_align = "left"
    #      query       = "*"
    #      live_span   = "1h"
    #    }
    #    widget_layout {
    #      height = 9
    #      width  = 66
    #      x      = 33
    #      y      = 60
    #    }
    #  }
    #
    #  widget {
    #    avg_read_ops_definition {
    #      text       = "${title(var.dbinstanceidentifier)} Dashboard"
    #      color      = "#d00"
    #      font_size  = "36"
    #      text_align = "left"
    #    }
    #    widget_layout {
    #      height = 20
    #      width  = 34
    #      x      = 33
    #      y      = 0
    #    }
    #  }
    #
    #  widget {
    #    replication_lag_by_instance_definition {
    #      text       = "${title(var.dbinstanceidentifier)} Dashboard"
    #      color      = "#d00"
    #      font_size  = "36"
    #      text_align = "left"
    #    }
    #    widget_layout {
    #      height = 20
    #      width  = 34
    #      x      = 33
    #      y      = 0
    #    }
    #  }
    #
    #  widget {
    #    connections_by_instance_definition {
    #      text       = "${title(var.dbinstanceidentifier)} Dashboard"
    #      color      = "#d00"
    #      font_size  = "36"
    #      text_align = "left"
    #    }
    #    widget_layout {
    #      height = 20
    #      width  = 34
    #      x      = 33
    #      y      = 0
    #    }
    #  }
    #
    #  widget {
    #    avg_replication_lay_by_instance_past_day_definition {
    #      text       = "${title(var.dbinstanceidentifier)} Dashboard"
    #      color      = "#d00"
    #      font_size  = "36"
    #      text_align = "left"
    #    }
    #    widget_layout {
    #      height = 20
    #      width  = 34
    #      x      = 33
    #      y      = 0
    #    }
    #  }
    #
    #  widget {
    #    connections_by_instance_definition {
    #      text       = "${title(var.dbinstanceidentifier)} Dashboard"
    #      color      = "#d00"
    #      font_size  = "36"
    #      text_align = "left"
    #    }
    #    widget_layout {
    #      height = 20
    #      width  = 34
    #      x      = 33
    #      y      = 0
    #    }
    #  }
    #
    #  widget {
    #    cpu_by_instance_definition {
    #      text       = "${title(var.dbinstanceidentifier)} Dashboard"
    #      color      = "#d00"
    #      font_size  = "36"
    #      text_align = "left"
    #    }
    #    widget_layout {
    #      height = 20
    #      width  = 34
    #      x      = 33
    #      y      = 0
    #    }
    #  }

  #  WIDGET {
  #    LOG_STREAM_DEFINITION {
  #      INDEXES             = ["MAIN"]
  #      QUERY               = "ERROR"
  #      COLUMNS             = ["CORE_HOST", "CORE_DBINSTANCEIDENTIFIER", "TAG_SOURCE"]
  #      SHOW_DATE_COLUMN    = TRUE
  #      SHOW_MESSAGE_COLUMN = TRUE
  #      MESSAGE_DISPLAY     = "EXPANDED-MD"
  #      SORT {
  #        COLUMN = "TIME"
  #        ORDER  = "DESC"
  #      }
  #    }
  #    WIDGET_LAYOUT {
  #      HEIGHT = 36
  #      WIDTH  = 32
  #      X      = 0
  #      Y      = 45
  #    }
  #  }
  #
  #  WIDGET {
  #    MANAGE_STATUS_DEFINITION {
  #      COLOR_PREFERENCE    = "TEXT"
  #      DISPLAY_FORMAT      = "COUNTSANDLIST"
  #      HIDE_ZERO_COUNTS    = TRUE
  #      QUERY               = "TYPE:METRIC"
  #      SHOW_LAST_TRIGGERED = FALSE
  #      SORT                = "STATUS,ASC"
  #      SUMMARY_TYPE        = "MONITORS"
  #      TITLE               = "${TITLE(VAR.DBINSTANCEIDENTIFIER)} MONITORS"
  #      TITLE_SIZE          = 16
  #      TITLE_ALIGN         = "LEFT"
  #    }
  #    WIDGET_LAYOUT {
  #      HEIGHT = 40
  #      WIDTH  = 30
  #      X      = 101
  #      Y      = 48
  #    }
  #  }
  #
  #  WIDGET {
  #    TRACE_DBINSTANCEIDENTIFIER_DEFINITION {
  #      DISPLAY_FORMAT       = "THREE_COLUMN"
  #      ENV                  = "PROD"
  #      DBINSTANCEIDENTIFIER = VAR.DBINSTANCEIDENTIFIER
  #      SHOW_BREAKDOWN       = TRUE
  #      SHOW_DISTRIBUTION    = TRUE
  #      SHOW_ERRORS          = TRUE
  #      SHOW_HITS            = TRUE
  #      SHOW_LATENCY         = TRUE
  #      SHOW_RESOURCE_LIST   = TRUE
  #      SIZE_FORMAT          = "LARGE"
  #      SPAN_NAME            = "CASSANDRA.QUERY"
  #      TITLE                = "${TITLE(VAR.DBINSTANCEIDENTIFIER)} #ENV:${VAR.ENV}"
  #      TITLE_ALIGN          = "CENTER"
  #      TITLE_SIZE           = "13"
  #      LIVE_SPAN            = "1H"
  #    }
  #    WIDGET_LAYOUT {
  #      HEIGHT = 38
  #      WIDTH  = 66
  #      X      = 33
  #      Y      = 21
  #    }
  #  }
  #
  #  WIDGET {
  #    TIMESERIES_DEFINITION {
  #      REQUEST {
  #        FORMULA {
  #          FORMULA_EXPRESSION = "MY_QUERY_1 + MY_QUERY_2"
  #          ALIAS              = "MY FF QUERY"
  #        }
  #        FORMULA {
  #          FORMULA_EXPRESSION = "MY_QUERY_1 * MY_QUERY_2"
  #          LIMIT {
  #            COUNT = 5
  #            ORDER = "DESC"
  #          }
  #          ALIAS = "MY SECOND FF QUERY"
  #        }
  #        QUERY {
  #          METRIC_QUERY {
  #            DATA_SOURCE = "METRICS"
  #            QUERY       = "AVG:SYSTEM.CPU.USER{APP:GENERAL} BY {ENV}"
  #            NAME        = "MY_QUERY_1"
  #            AGGREGATOR  = "SUM"
  #          }
  #        }
  #        QUERY {
  #          METRIC_QUERY {
  #            QUERY      = "AVG:SYSTEM.CPU.USER{APP:GENERAL} BY {ENV}"
  #            NAME       = "MY_QUERY_2"
  #            AGGREGATOR = "SUM"
  #          }
  #        }
  #      }
  #    }
  #    WIDGET_LAYOUT {
  #      HEIGHT = 16
  #      WIDTH  = 25
  #      X      = 58
  #      Y      = 83
  #    }
  #  }
  #  WIDGET {
  #    TIMESERIES_DEFINITION {<F5><F5>
  #      REQUEST {
  #        QUERY {
  #          EVENT_QUERY {
  #            NAME        = "MY-QUERY"
  #            DATA_SOURCE = "LOGS"
  #            INDEXES     = ["DAYS-3"]
  #            COMPUTE {
  #              AGGREGATION = "COUNT"
  #            }
  #            GROUP_BY {
  #              FACET = "HOST"
  #              SORT {
  #                METRIC      = "@LAMBDA.MAX_MEMORY_USED"
  #                AGGREGATION = "AVG"
  #              }
  #              LIMIT = 10
  #            }
  #          }
  #        }
  #      }
  #    }
  #    WIDGET_LAYOUT {
  #      HEIGHT = 16
  #      WIDTH  = 28
  #      X      = 29
  #      Y      = 83
  #    }
  #  }
  #  WIDGET {
  #    TIMESERIES_DEFINITION {
  #      REQUEST {
  #        QUERY {
  #          PROCESS_QUERY {
  #            DATA_SOURCE       = "PROCESS"
  #            TEXT_FILTER       = "ABC"
  #            METRIC            = "PROCESS.STAT.CPU.TOTAL_PCT"
  #            LIMIT             = 10
  #            TAG_FILTERS       = ["SOME_FILTER"]
  #            NAME              = "MY_PROCESS_QUERY"
  #            SORT              = "ASC"
  #            IS_NORMALIZED_CPU = TRUE
  #            AGGREGATOR        = "SUM"
  #          }
  #        }
  #      }
  #    }
  #    WIDGET_LAYOUT {
  #      HEIGHT = 16
  #      WIDTH  = 28
  #      X      = 0
  #      Y      = 83
  #    }
  #  }
  #
  #  TEMPLATE_VARIABLE {
  #    NAME    = "VAR_1"
  #    PREFIX  = "HOST"
  #    DEFAULT = "AWS"
  #  }
  #  TEMPLATE_VARIABLE {
  #    NAME    = "VAR_2"
  #    PREFIX  = "DBINSTANCEIDENTIFIER_NAME"
  #    DEFAULT = "AUTOSCALING"
  #  }
  #
  #  TEMPLATE_VARIABLE_PRESET {
  #    NAME = "PRESET_1"
  #    TEMPLATE_VARIABLE {
  #      NAME  = "VAR_1"
  #      VALUE = "HOST.DC"
  #    }
  #    TEMPLATE_VARIABLE {
  #      NAME  = "VAR_2"
  #      VALUE = "MY_DBINSTANCEIDENTIFIER"
  #    }
  #  }
}
