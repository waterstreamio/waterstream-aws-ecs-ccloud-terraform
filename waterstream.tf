resource "aws_ecs_cluster" "waterstream_ecs" {
  name = var.waterstream_env_name
  //  capacity_providers = [FARGATE]
//  setting {
//    name = "containerInsights"
//    value = "enabled"
//  }
}

data "aws_iam_policy_document" "task-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskRole" {
  name = "${var.waterstream_env_name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.task-assume-role.json
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "${var.waterstream_env_name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task-assume-role.json
}

resource "aws_iam_role" "ecsCwAgentTaskRole" {
  name = "${var.waterstream_env_name}-ecsCwAgentTaskRole"
  assume_role_policy = data.aws_iam_policy_document.task-assume-role.json
}

resource "aws_iam_role" "ecsCwAgentTaskExecutionRole" {
  name = "${var.waterstream_env_name}-ecsCwAgentTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task-assume-role.json
}

data "aws_iam_policy_document" "task-logs-permissions-policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "task-logs-permission-policy" {
  name        = "${var.waterstream_env_name}-task-permission-policy"
  description = "Grants permissions for Waterstream demo tasks"
  policy      = data.aws_iam_policy_document.task-logs-permissions-policy.json
}

data "aws_iam_policy_document" "ECSSSMInlinePolicy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.dockerhub_credentials_arn
    ]
  }
}
resource "aws_iam_policy" "ECSSSMInlinePolicy" {
  name        = "ECSSSMInlinePolicy"
  description = "ECSSSMInlinePolicy"
  policy      = data.aws_iam_policy_document.ECSSSMInlinePolicy.json
}

data "aws_iam_policy_document" "ECSServiceDiscoveryInlinePolicy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:DescribeContainerInstances",
      "ec2:DescribeInstances",
      "ecs:DescribeTaskDefinition"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "ECSServiceDiscoveryInlinePolicy" {
  name        = "${var.waterstream_env_name}-ECSServiceDiscoveryInlinePolicy"
  description = "ECSServiceDiscoveryInlinePolicy"
  policy      = data.aws_iam_policy_document.ECSServiceDiscoveryInlinePolicy.json
}


data "aws_iam_policy_document" "waterstream_task_exec_inline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.dockerhub_credentials_arn
    ]
  }
}
resource "aws_iam_policy" "waterstream_task_exec_inline_policy" {
  name        = "${var.waterstream_env_name}_task_exec_inline_policy"
  policy      = data.aws_iam_policy_document.waterstream_task_exec_inline_policy.json
}

resource "aws_iam_role_policy_attachment" "task-permissions-attach" {
  role = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.task-logs-permission-policy.arn
}

resource "aws_iam_role_policy_attachment" "task-metering-attach" {
  role       = aws_iam_role.ecsTaskRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage"
}

resource "aws_iam_role_policy_attachment" "task-execution-permissions-attach" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task-execution-inline-policy-attach" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.waterstream_task_exec_inline_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecsCwAgentTaskExecutionRole-1" {
  role = aws_iam_role.ecsCwAgentTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecsCwAgentTaskExecutionRole-2" {
  role = aws_iam_role.ecsCwAgentTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecsCwAgentTaskExecutionRole-3" {
  role = aws_iam_role.ecsCwAgentTaskExecutionRole.name
  policy_arn = aws_iam_policy.ECSSSMInlinePolicy.arn
}

resource "aws_iam_role_policy_attachment" "ecsCwAgentTaskRole-1" {
  role = aws_iam_role.ecsCwAgentTaskRole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecsCwAgentTaskRole-2" {
  role = aws_iam_role.ecsCwAgentTaskRole.name
  policy_arn = aws_iam_policy.ECSServiceDiscoveryInlinePolicy.arn
}

resource "aws_security_group" "cloudwatch-prometheus-sg" {
  name = "cloudwatch-prometheus-sg"
  vpc_id = aws_vpc.aws-vpc.id
  //TODO remove ingress all after debug
//    ingress {
//      cidr_blocks = ["0.0.0.0/0"]
//      from_port = 0
//      to_port = 65500
//      protocol = "tcp"
//    }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 9090
    to_port = 9090
    protocol = "tcp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "grafana-sg" {
  name = "grafana-sg"
  vpc_id = aws_vpc.aws-vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_cloudformation_stack" "cloudwatch-agent-prometheus-waterstream" {
  count = "${var.waterstream_cloudwatch_metrics_enabled == true ? 1 : 0 }"

  name = "cloudwatch-agent-prometheus-${var.waterstream_env_name}"
  parameters = {
    ECSClusterName = aws_ecs_cluster.waterstream_ecs.name
    CreateIAMRoles = "True"
    ECSLaunchType = "FARGATE"
    SecurityGroupID = aws_security_group.cloudwatch-prometheus-sg.id
    SubnetID = aws_subnet.private_subnet_1.id
    TaskRoleName = "waterstream-demo-cloudWatchAgentTaskRole"
    ExecutionRoleName = "waterstream-demo-cloudWatchAgentTaskExecutionRole"
  }
  capabilities = ["CAPABILITY_NAMED_IAM"]
  template_body = file("cloud_watch/cwagent-ecs-prometheus-metric-for-awsvpc.yaml")
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Waterstream"

  count = "${var.waterstream_cloudwatch_metrics_enabled == true ? 1 : 0 }"

  depends_on = [aws_cloudformation_stack.cloudwatch-agent-prometheus-waterstream]

  //templating here is a workaround for metrics in CloudWatch staying for too long, thus growing over the quota of metrics per the response
  dashboard_body = templatefile("cloud_watch/cw_waterstream_dashboard.json.tpl", {
    task_def_family = aws_ecs_task_definition.waterstream.family
    aws_region = var.region
  })
}

resource "aws_ecs_task_definition" "waterstream" {
  depends_on = [null_resource.wait_testbox_kafka, null_resource.testbox_tls]
  family                   = var.waterstream_task_family_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.waterstream_task_cpu
  memory                   = var.waterstream_task_memory
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecsTaskRole.arn

  container_definitions    = jsonencode([{
    "name": "waterstream",
    "cpu": var.waterstream_task_cpu,
    "repositoryCredentials": {
      "credentialsParameter": var.dockerhub_credentials_arn
    },
    "essential": true,
    "image": "${var.waterstream_image_name}:${var.waterstream_version}",
    "memory": var.waterstream_task_memory,
    "portMappings": [
      {
        "containerPort": 1882,
        "hostPort": 1882,
        "protocol": "tcp"
      },
      {
        "containerPort": 1883,
        "hostPort": 1883,
        "protocol": "tcp"
      },
      {
        "containerPort": 1884,
        "hostPort": 1884,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.region}",
        "awslogs-group": "${aws_cloudwatch_log_group.waterstream_logs.name}",
        "awslogs-stream-prefix": "waterstream_broker"
      }
    },
    "mountPoints": [{
      "sourceVolume": "waterstream-resources",
      "containerPath": "/var/waterstream_resources",
      "readOnly": true
    }],
    "volumesFrom": [],
    "environment": [
      {"name": "KAFKA_BOOTSTRAP_SERVERS", "value": var.kafka_bootstrap_servers},
      {"name": "KAFKA_SASL_JAAS_CONFIG", "value": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${var.ccloud_api_key}\" password=\"${var.ccloud_api_secret}\";"},
      {"name": "KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM", "value": "https"},
      {"name": "KAFKA_SASL_MECHANISM", "value": "PLAIN"},
      {"name": "KAFKA_SECURITY_PROTOCOL", "value": "SASL_SSL"},
      {"name": "KAFKA_REQUEST_TIMEOUT_MS", "value": tostring(var.kafka_request_timeout_ms)},
      {"name": "KAFKA_RETRY_BACKOFF_MS", "value": tostring(var.kafka_retry_backoff_ms)},
      {"name": "KAFKA_FETCH_MIN_BYTES", "value": tostring(var.kafka_fetch_min_bytes)},
      {"name": "KAFKA_TRANSACTIONAL_ID", "value": ""},
      {"name": "KAFKA_STREAMS_APP_SERVER_PORT", "value": "1882"},
      {"name": "KAFKA_STREAMS_REPLICATION_FACTOR", "value": tostring(var.kafka_streams_replication_factor)},
      {"name": "SESSION_TOPIC", "value": var.kafka_sessions_topic},
      {"name": "RETAINED_MESSAGES_TOPIC", "value": var.kafka_retained_messages_topic},
      {"name": "CONNECTION_TOPIC", "value": var.kafka_connections_topic},
      {"name": "KAFKA_MESSAGES_DEFAULT_TOPIC", "value": var.kafka_mqtt_messages_topic},
      {"name": "KAFKA_MESSAGES_TOPICS_PATTERNS", "value": var.kafka_messages_topics_patterns},
      {"name": "KAFKA_MESSAGES_TOPICS_PREFIXES", "value": var.kafka_messages_topics_prefixes},
      {"name": "KAFKA_MQTT_TOPIC_TO_MESSAGE_KEY", "value": var.kafka_mqtt_topic_to_messages_key},
      {"name": "CENTRALIZED_CONSUMER_LISTENER_QUEUE", "value": "128"},
      {"name": "MQTT_BLOCKING_THREAD_POOL_SIZE", "value": "10"},
      {"name": "MAX_QUEUED_INCOMMING_MESSAGES", "value": "1000"},
      {"name": "MQTT_MAX_IN_FLIGHT_MESSAGES", "value": "10"},
      {"name": "COROUTINES_THREADS", "value": tostring(var.waterstream_coroutines_threads)},
      {"name": "WATERSTREAM_LICENSE_DATA", "value": var.waterstream_license_file == "" ? "" : file(var.waterstream_license_file)},
      {"name": "WATERSTREAM_LICENSE_AWS_MARKETPLACE_ENABLED", "value": var.waterstream_license_file == "" ? "true" : "false"},
      {"name": "WATERSTREAM_JAVA_OPTS", "value": "-XX:InitialRAMPercentage=${var.waterstream_ram_percentage} -XX:MaxRAMPercentage=${var.waterstream_ram_percentage}"},
      {"name": "SSL_ENABLED", "value": var.waterstream_enable_ssl},
      {"name": "SSL_KEY_PATH", "value": "/var/waterstream_resources/mqtt_broker.pkcs8.key"},
      {"name": "SSL_CERT_PATH", "value": "/var/waterstream_resources/mqtt_broker.crt"},
      {"name": "SSL_ADDITIONAL_CA_CERTS_PATH", "value": "/var/waterstream_resources/waterstream_demo_ca.pem"},
      {"name": "AUTHENTICATION_REQUIRED", "value": var.waterstream_require_authentication},
      {"name": "AUTHENTICATION_METHOD_CLIENT_SSL_CERT_ENABLED", "value": var.waterstream_authentication_method_ssl_enabled},
      {"name": "AUTHENTICATION_METHOD_JWT_ENABLED", "value": var.waterstream_authentication_method_jwt_enabled},
      {"name": "AUTHORIZATION_RULES", "value": var.waterstream_authorization_rules_file == "" ? "" : file(var.waterstream_authorization_rules_file)},
      {"name": "JWT_MQTT_CONNECT_USERNAME", "value": var.waterstream_jwt_mqtt_connect_username},
      {"name": "JWT_AUDIENCE", "value": var.waterstream_jwt_audience},
      {"name": "JWT_VERIFICATION_KEY_ALGORITHM", "value": var.waterstream_jwt_verification_key_algorithm},
      {"name": "JWT_VERIFICATION_KEY", "value": var.waterstream_authentication_method_jwt_enabled == "true" ? file(var.waterstream_jwt_verification_key_file) : ""}
    ],
    "ulimits": [{
      "name": "nofile",
      "softLimit": 500000,
      "hardLimit": 500000
    }],
    "dockerLabels": {
      //Containers with ECS_PROMETHEUS_EXPORTER_PORT label are picked by CloudWatch agent by default
      "ECS_PROMETHEUS_EXPORTER_PORT": "1884",
      "job": "waterstream-kafka",
      "env": var.waterstream_env_name,
      "service": "waterstream"
    }
  }])

  volume {
    name = "waterstream-resources"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.waterstream-resources.id
//      root_directory          = "/tls/mqtt_broker"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.waterstream-resources-broker-ap.id
        iam             = "ENABLED"
      }
    }
  }
}


resource "aws_ecs_service" "waterstream" {
  platform_version = "1.4.0"
  name            = var.waterstream_env_name
  cluster         = aws_ecs_cluster.waterstream_ecs.id
  task_definition = aws_ecs_task_definition.waterstream.arn
  desired_count   = var.waterstream_instances
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    subnets = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id
    ]
    security_groups = [aws_security_group.waterstream_task_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.waterstream_app.arn
    container_name   = "waterstream"
    container_port   = 1883
  }
}

resource "aws_lb_target_group" "waterstream_app" {
  name = "${var.waterstream_env_name}-target-group"
  port = 1883
  protocol = "TCP"
  vpc_id = aws_vpc.aws-vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold = "3"
    interval = "30"
    port = 1884
    protocol = "HTTP"
    path = "/metrics"
    unhealthy_threshold = "3"
  }
}

resource "aws_security_group" "waterstream_task_sg" {
  vpc_id = aws_vpc.aws-vpc.id
  name = "${var.waterstream_env_name}_task_sg"
  ingress {
    cidr_blocks = [var.vpc_cidr]
    from_port = 1882
    to_port = 1884
    protocol = "tcp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "waterstream_lb_sg" {
  vpc_id = aws_vpc.aws-vpc.id
  name = "${var.waterstream_env_name}_lb_sg"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 1883
    to_port = 1883
    protocol = "tcp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "waterstream_mqtt_lb" {
  name               = "${var.load_balancer_name_prefix}-mqtt"
  internal           = false
  load_balancer_type = "network"

  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id
  ]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "waterstream_lb_listener" {
  load_balancer_arn = aws_lb.waterstream_mqtt_lb.arn
  port              = "1883"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waterstream_app.arn
  }
}


resource "aws_ecs_task_definition" "cwagent-prometheus" {
  depends_on = [null_resource.wait_testbox_kafka, null_resource.testbox_tls]

  family                   = "cwagent-prometheus-${aws_ecs_cluster.waterstream_ecs.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn = aws_iam_role.ecsCwAgentTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecsCwAgentTaskRole.arn

  container_definitions    = jsonencode([
    {
      "name": "cloudwatch-agent-prometheus",
      "image": "amazon/cloudwatch-agent:1.247346.0b249609",

      "essential": true,
      "mountPoints": [
        {
          "sourceVolume": "waterstream-resources-prometheus-tmp",
          "containerPath": "/tmp",
          "readOnly": false
        }
      ],
      "portMappings": [],
      "environment": [
        {"name": "PROMETHEUS_CONFIG_CONTENT",
         "value": <<EOF
            global:
              scrape_interval: 1m
              scrape_timeout: 10s
            scrape_configs:
              - job_name: cwagent-ecs-file-sd-config
                sample_limit: 10000
                file_sd_configs:
                  - files: [ "/tmp/cwagent_ecs_auto_sd.yaml" ]
          EOF
        },
        {"name": "CW_CONFIG_CONTENT",
         "value": <<EOF
        {
          "agent": {
            "debug": true
          },
          "logs": {
            "metrics_collected": {
              "prometheus": {
                "prometheus_config_path": "env:PROMETHEUS_CONFIG_CONTENT",
                "ecs_service_discovery": {
                  "sd_frequency": "1m",
                  "sd_result_file": "/tmp/cwagent_ecs_auto_sd.yaml",
                  "docker_label": { },
                  "task_definition_list": [ ]
                },
                "emf_processor": {
                  "metric_declaration": [
                  ]
                }
              }
            },
            "force_flush_interval": 5
          }
        }
         EOF
        }
      ],
      "secrets": [],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "True",
          "awslogs-region": "${var.region}",
          "awslogs-group": "/ecs/ecs-cwagent-prometheus",
          "awslogs-stream-prefix": "ecs-fargate-awsvpc"
        }
      }
    },
    {
      "name": "prometheus",
//      "hostname": "prometheus",
      "image": "prom/prometheus:v2.23.0",
      "repositoryCredentials": {
        "credentialsParameter": var.dockerhub_credentials_arn
      },
      "essential": true,
      "portMappings": [
        {
          "containerPort": 9090,
          "hostPort": 9090,
          "protocol": "tcp"
        },
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${var.region}",
          "awslogs-group": "${aws_cloudwatch_log_group.waterstream_logs.name}",
          "awslogs-stream-prefix": "waterstream_prometheus"
        }
      },
      "mountPoints": [
        {
        "sourceVolume": "waterstream-resources-prometheus-etc",
        "containerPath": "/etc/prometheus",
        "readOnly": true
       },
       {
          "sourceVolume": "waterstream-resources-prometheus-tmp",
          "containerPath": "/tmp",
          "readOnly": false
        }
      ],
      "volumesFrom": [],
      "environment": [],
      "ulimits": [],
      "dockerLabels": {}
    },
    {
      "name": "grafana",
      "image": "grafana/grafana:7.0.3",
      "repositoryCredentials": {
        "credentialsParameter": var.dockerhub_credentials_arn
      },
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${var.region}",
          "awslogs-group": "${aws_cloudwatch_log_group.waterstream_logs.name}",
          "awslogs-stream-prefix": "waterstream_grafana"
        }
      },
      "mountPoints": [
        {
          "sourceVolume": "waterstream-resources-grafana-etc-prov",
          "containerPath": "/etc/grafana/provisioning",
          "readOnly": true
        },
        {
          "sourceVolume": "waterstream-resources-grafana-dashboards",
          "containerPath": "/var/waterstream_monitoring/dashboards",
          "readOnly": true
        },
        {
          "sourceVolume": "waterstream-resources-grafana-data",
          "containerPath": "/var/lib/grafana",
          "readOnly": false
        }
      ],
      "volumesFrom": [],
      "environment": [],
      "ulimits": [],
      "dockerLabels": {}
    }
  ])

  volume {
    name = "waterstream-resources-prometheus-etc"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.waterstream-resources.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.waterstream-prometheus-etc-ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "waterstream-resources-prometheus-tmp"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.waterstream-resources.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.waterstream-prometheus-tmp-ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "waterstream-resources-grafana-etc-prov"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.waterstream-resources.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.waterstream-grafana-etc-prov-ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "waterstream-resources-grafana-dashboards"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.waterstream-resources.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.waterstream-grafana-dashboards-ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "waterstream-resources-grafana-data"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.waterstream-resources.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.waterstream-grafana-data-ap.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_lb" "waterstream_grafana_lb" {
  name               = "${var.load_balancer_name_prefix}-grafana"
  internal           = false
  load_balancer_type = "network"

  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "waterstream_grafana_lb_listener" {
  load_balancer_arn = aws_lb.waterstream_grafana_lb.arn
  port              = "3000"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waterstream_grafana.arn
  }
}


resource "aws_lb_target_group" "waterstream_grafana" {
  name = "waterstream-grafana-target-group"
  port = 3000
  protocol = "TCP"
  vpc_id = aws_vpc.aws-vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold = "3"
    interval = "30"
    port = 3000
    protocol = "HTTP"
    path = "/"
    unhealthy_threshold = "3"
  }
  depends_on = [aws_lb.waterstream_grafana_lb]
}

resource "aws_ecs_service" "ECSCWAgentService" {
  platform_version = "1.4.0"
  name            = "ECSCWAgentService"
  cluster         = aws_ecs_cluster.waterstream_ecs.id
  task_definition = aws_ecs_task_definition.cwagent-prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets = [
      aws_subnet.private_subnet_1.id
    ]
    security_groups = [aws_security_group.cloudwatch-prometheus-sg.id, aws_security_group.grafana-sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.waterstream_grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }
}


