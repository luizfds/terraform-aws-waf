resource "aws_wafv2_web_acl" "waf_regional" {
  count = var.waf_regional_enable ? 1 : 0

  name        = "${var.environment_name}-api-gw-${var.regional_rule}"
  description = "Regional WAF managed rules"
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.metrics_enabled
    metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}"
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  dynamic "rule" {

    for_each = { for rule in try(var.byte_match_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        dynamic "byte_match_statement" {
          for_each = { for byte_match in try(rule.value.byte_matchs, []) : byte_match.search_string => byte_match }

          content {
            positional_constraint = byte_match_statement.value.positional_constraint
            search_string         = byte_match_statement.value.search_string

            dynamic "field_to_match" {
              for_each = rule.value.byte_match_statement

              content {
                dynamic "all_query_arguments" {
                  for_each = field_to_match.value.all_query_arguments != null ? [1] : []

                  content {}
                }

                dynamic "body" {
                  for_each = field_to_match.value.body != null ? [1] : []

                  content {}
                }

                dynamic "method" {
                  for_each = field_to_match.value.method != null ? [1] : []

                  content {}
                }

                dynamic "query_string" {
                  for_each = field_to_match.value.query_string != null ? [1] : []

                  content {}
                }
                dynamic "single_header" {
                  for_each = field_to_match.value.single_header != null ? [1] : []

                  content {
                    name = field_to_match.value.single_header
                  }
                }
                dynamic "single_query_argument" {
                  for_each = field_to_match.value.single_query_argument != null ? [1] : []

                  content {
                    name = field_to_match.value.single_query_argument
                  }
                }

                dynamic "uri_path" {
                  for_each = field_to_match.value.uri_path != null ? [1] : []

                  content {}
                }
              }
            }

            dynamic "text_transformation" {
              for_each = { for text_transformation_rule in try(rule.value.text_transformation, []) : text_transformation_rule.priority => text_transformation_rule }

              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.geo_match_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        geo_match_statement {
          country_codes = rule.value.country_codes
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.ip_set_reference_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        ip_set_reference_statement {
          arn =  length(try(rule.value.ip_set, [])) > 0 ? aws_wafv2_ip_set.ip_set[rule.value.name].arn : rule.value.ip_set_arn
          
          dynamic "ip_set_forwarded_ip_config" {
            for_each = rule.value.ip_set_reference_statement != null ? [1] : []
            content {
              fallback_behavior = rule.value.ip_set_reference_statement.fallback_behavior
              header_name       = rule.value.ip_set_reference_statement.header_name
              position          = rule.value.ip_set_reference_statement.position
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.managed_rule_group_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "count" {
          for_each = lookup(rule.value, "override_action", null) == "count" ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = lookup(rule.value, "override_action", null) != "count" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = { for managed_rule in try(rule.value.managed_rule_group_statement, []) : managed_rule.name => managed_rule }

          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor_name

            dynamic "rule_action_override" {
              for_each = toset(try(managed_rule_group_statement.value.block_rule_action_override, []))
              iterator = rule_action_override_block
 
              content {
                name = rule_action_override_block.value
                action_to_use {
                  block {}
                }
              }
            }

            dynamic "rule_action_override" {
              for_each = toset(try(managed_rule_group_statement.value.count_rule_action_override, []))
              iterator = rule_action_override_count

              content {
                name = rule_action_override_count.value
                action_to_use {
                  count {}
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }

    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.rate_based_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        dynamic "rate_based_statement" {
          for_each = { for rate_based in try(rule.value.rate_based, []) : rate_based.aggregate_key_type => rate_based }

          content {
            aggregate_key_type = rate_based_statement.value.aggregate_key_type
            limit              = rate_based_statement.value.limit

            dynamic "forwarded_ip_config" {
              for_each = { for forwarded_ip_config_rule in try(rule.value.rate_based_statement, []) : forwarded_ip_config_rule.fallback_behavior => forwarded_ip_config_rule }

              content {
                fallback_behavior = forwarded_ip_config.value.fallback_behavior
                header_name       = forwarded_ip_config.value.header_name
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.regex_pattern_set_reference_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        regex_pattern_set_reference_statement {
          arn = aws_wafv2_regex_pattern_set.regex_set[rule.value.name].arn

          dynamic "field_to_match" {
            for_each = rule.value.regex_pattern_set_reference_statement

            content {
              dynamic "all_query_arguments" {
                for_each = field_to_match.value.all_query_arguments != null ? [1] : []

                content {}
              }

              dynamic "body" {
                for_each = field_to_match.value.body != null ? [1] : []

                content {}
              }

              dynamic "method" {
                for_each = field_to_match.value.method != null ? [1] : []

                content {}
              }

              dynamic "query_string" {
                for_each = field_to_match.value.query_string != null ? [1] : []

                content {}
              }
              dynamic "single_header" {
                for_each = field_to_match.value.single_header != null ? [1] : []

                content {
                  name = field_to_match.value.single_header
                }
              }
              dynamic "single_query_argument" {
                for_each = field_to_match.value.single_query_argument != null ? [1] : []

                content {
                  name = field_to_match.value.single_query_argument
                }
              }

              dynamic "uri_path" {
                for_each = field_to_match.value.uri_path != null ? [1] : []

                content {}
              }
            }
          }

          dynamic "text_transformation" {
            for_each = { for text_transformation_rule in try(rule.value.text_transformation, []) : text_transformation_rule.priority => text_transformation_rule }

            content {
              priority = text_transformation.value.priority
              type     = text_transformation.value.type
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.size_constraint_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        size_constraint_statement {
          comparison_operator = rule.value.comparison_operator
          size                = rule.value.size

          dynamic "field_to_match" {
            for_each = rule.value.size_constraint_statement

            content {
              dynamic "all_query_arguments" {
                for_each = field_to_match.value.all_query_arguments != null ? [1] : []

                content {}
              }

              dynamic "body" {
                for_each = field_to_match.value.body != null ? [1] : []

                content {}
              }

              dynamic "method" {
                for_each = field_to_match.value.method != null ? [1] : []

                content {}
              }

              dynamic "query_string" {
                for_each = field_to_match.value.query_string != null ? [1] : []

                content {}
              }

              dynamic "single_header" {
                for_each = field_to_match.value.single_header != null ? [1] : []

                content {
                  name = field_to_match.value.single_header
                }
              }
              dynamic "single_query_argument" {
                for_each = field_to_match.value.single_query_argument != null ? [1] : []

                content {
                  name = field_to_match.value.single_query_argument
                }
              }

              dynamic "uri_path" {
                for_each = field_to_match.value.uri_path != null ? [1] : []

                content {}
              }
            }
          }

          dynamic "text_transformation" {
            for_each = { for text_transformation_rule in try(rule.value.text_transformation, []) : text_transformation_rule.priority => text_transformation_rule }

            content {
              priority = text_transformation.value.priority
              type     = text_transformation.value.type
            }
          }
        }
      }


      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.sqli_match_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        sqli_match_statement {

          dynamic "field_to_match" {
            for_each = rule.value.sqli_match_statement

            content {
              dynamic "all_query_arguments" {
                for_each = field_to_match.value.all_query_arguments != null ? [1] : []

                content {}
              }

              dynamic "body" {
                for_each = field_to_match.value.body != null ? [1] : []

                content {}
              }

              dynamic "method" {
                for_each = field_to_match.value.method != null ? [1] : []

                content {}
              }

              dynamic "query_string" {
                for_each = field_to_match.value.query_string != null ? [1] : []

                content {}
              }
              dynamic "single_header" {
                for_each = field_to_match.value.single_header != null ? [1] : []

                content {
                  name = field_to_match.value.single_header
                }
              }
              dynamic "single_query_argument" {
                for_each = field_to_match.value.single_query_argument != null ? [1] : []

                content {
                  name = field_to_match.value.single_query_argument
                }
              }

              dynamic "uri_path" {
                for_each = field_to_match.value.uri_path != null ? [1] : []

                content {}
              }
            }
          }

          dynamic "text_transformation" {
            for_each = { for text_transformation_rule in try(rule.value.text_transformation, []) : text_transformation_rule.priority => text_transformation_rule }

            content {
              priority = text_transformation.value.priority
              type     = text_transformation.value.type
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.xss_match_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []

          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []

          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []

          content {}
        }
      }

      statement {
        xss_match_statement {

          dynamic "field_to_match" {
            for_each = rule.value.xss_match_statement

            content {
              dynamic "all_query_arguments" {
                for_each = field_to_match.value.all_query_arguments != null ? [1] : []

                content {}
              }

              dynamic "body" {
                for_each = field_to_match.value.body != null ? [1] : []

                content {}
              }

              dynamic "method" {
                for_each = field_to_match.value.method != null ? [1] : []

                content {}
              }

              dynamic "query_string" {
                for_each = field_to_match.value.query_string != null ? [1] : []

                content {}
              }
              dynamic "single_header" {
                for_each = field_to_match.value.single_header != null ? [1] : []

                content {
                  name = ield_to_match.value.single_header
                }
              }
              dynamic "single_query_argument" {
                for_each = field_to_match.value.single_query_argument != null ? [1] : []

                content {
                  name = field_to_match.value.single_query_argument
                }
              }

              dynamic "uri_path" {
                for_each = field_to_match.value.uri_path != null ? [1] : []

                content {}
              }
            }
          }

          dynamic "text_transformation" {
            for_each = { for text_transformation_rule in try(rule.value.text_transformation, []) : text_transformation_rule.priority => text_transformation_rule }

            content {
              priority = text_transformation.value.priority
              type     = text_transformation.value.type
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  dynamic "rule" {

    for_each = { for rule in try(var.user_defined_rule_group_statement_rules, []) : rule.name => rule }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "count" {
          for_each = lookup(rule.value, "override_action", null) == "count" ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = lookup(rule.value, "override_action", null) != "count" ? [1] : []
          content {}
        }
      }

      statement {
        rule_group_reference_statement  {
          arn =  rule.value.rule_group_arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.metrics_enabled, var.metrics_enabled)
        metric_name                = "${var.environment_name}-api-gw-${var.regional_rule}-${rule.value.name}"
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.sampled_requests_enabled)
      }
    }
  }

  tags = {
    Name = "waf-api-gw-${var.regional_rule}"
  }
}

resource "aws_wafv2_web_acl_association" "waf_association" {
  for_each = {
    for resource in var.resource_arn : resource => resource
    if var.associate_waf == true
  }

  resource_arn = each.key
  web_acl_arn  = aws_wafv2_web_acl.waf_regional[0].arn
}

resource "aws_cloudwatch_log_group" "waf_log_group" {
  count = var.logs_enable && !var.log_destination ? 1 : 0

  name              = "aws-waf-logs-${var.environment_name}-api-gw/${var.regional_rule}"
  retention_in_days = var.logs_retension
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging_configuration" {
  count = var.logs_enable ? 1 : 0

  log_destination_configs = var.log_destination ? var.log_destination_arn : [aws_cloudwatch_log_group.waf_log_group[count.index].arn]
  resource_arn            = aws_wafv2_web_acl.waf_regional[count.index].arn

  dynamic "redacted_fields" {
    for_each = try(var.logging_redacted_fields, [])

    content {
      dynamic "method" {
        for_each = redacted_fields.value.method != null ? [1] : []

        content {}
      }

      dynamic "query_string" {
        for_each = redacted_fields.value.query_string != null ? [1] : []

        content {}
      }
      dynamic "single_header" {
        for_each = redacted_fields.value.single_header != null ? [1] : []

        content {
          name = redacted_fields.value.single_header
        }
      }

      dynamic "uri_path" {
        for_each = redacted_fields.value.uri_path != null ? [1] : []

        content {}
      }
    }
  }

  dynamic "logging_filter" {
    for_each = try(var.logging_filter, [])

    content {
      default_behavior = logging_filter.value.default_behavior

      dynamic "filter" {
        for_each = try(logging_filter.value.filter, [])

        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement

          dynamic "condition" {
            for_each = try(filter.value.condition, [])

            content {
              dynamic "action_condition" {
                for_each = condition.value.action_condition != null ? [1] : []

                content {
                  action = condition.value.action_condition
                }
              }

              dynamic "label_name_condition" {
                for_each = condition.value.label_name_condition != null ? [1] : []

                content {
                  label_name = condition.value.label_name_condition
                }
              }
            }
          }
        }
      }
    }
  }
}