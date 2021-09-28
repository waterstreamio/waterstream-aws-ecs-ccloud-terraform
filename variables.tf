variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "region" {
  default = "eu-central-1"
  type = string
}

variable "aws_keypair_public_key_location" {
  type = string
  default = "ssh_keypair/waterstream-key.pub"
}

variable "aws_keypair_private_key_location" {
  type = string
  default = "ssh_keypair/waterstream-key"
}

variable "dockerhub_credentials_arn" {
  description = <<EOF
    ARN of the DockerHub credentials in the AWS Secrets Manager (needed because anonymous access exceeds DockerHub pull limits too fast).
    See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html#private-auth-enable for the creation instructions.
  EOF

  type = string
}

###########################################
#############   Network        ############
###########################################

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "load_balancer_name_prefix" {
  type = string
  # <prefix>-mqtt-<code>.elb.<region>.amazonaws.com must not be longer than 64 characters so that SSL certificate could be generated for it
  default = "ws"
}

###########################################
#############   Waterstream    ############
###########################################

#Distinguishes resources from possible multiple Waterstream deployments
variable "waterstream_env_name" {
  type = string
  default = "waterstream"
}

variable "waterstream_image_name" {
  type        = string
  #AWS Marketplace repository
  # default = "709825985650.dkr.ecr.us-east-1.amazonaws.com/waterstream/waterstream-kafka"
  #DockerHub repository
  default     = "simplematter/waterstream-kafka"
}

variable "waterstream_version" {
  type        = string
  default     = "1.3.22"
  # Latest AWS Marketplace version
  # default     = "1.3.16"
}

variable "waterstream_enable_ssl" {
  type        = string
  default     = "false"
}

variable "waterstream_task_cpu" {
  type        = number
  default     = 1024
  validation {
    condition = contains([256, 512, 1024, 2048, 4096], var.waterstream_task_cpu)
    error_message = "Allowed values for waterstream_task_cpu are: 256, 512, 1024, 2048, 4096."
  }
}

variable "waterstream_task_memory" {
  type        = number
  default     = 2048
}

variable "waterstream_coroutines_threads" {
  type = number
  default = 8
}

variable "waterstream_ram_percentage" {
  description = "JVM MaxRAMPercentage parameter value"
  type        = number
  default     = 80
  validation {
    condition = var.waterstream_ram_percentage >= 10 && var.waterstream_ram_percentage <= 90
    error_message = "JVM MaxRAMPercentage must be between 10 and 90."
  }
}

variable "waterstream_instances" {
  type        = number
  default     = 2
  validation {
    condition = var.waterstream_instances >= 1
    error_message = "Must be at least 1 Waterstream instance."
  }
}

variable "waterstream_task_family_name" {
  type        = string
  default     = "waterstream_task"
}

variable "waterstream_cloudwatch_metrics_enabled" {
  type        = bool
  default     = false
}

variable "waterstream_prometheus_metrics_enabled" {
  type        = bool
  default     = true
}

variable "waterstream_license_file" {
  type = string
  default = "waterstream.license"
}

variable "testbox_ingress_cidr" {
  type = string
  default = "0.0.0.0/0"
}

###########################################
#############  AuthN & AuthZ   ############
###########################################

variable "waterstream_require_authentication" {
  type        = string
  default     = "false"
}

variable "waterstream_authentication_method_ssl_enabled" {
  type        = string
  default     = "true"
}

variable "waterstream_authentication_method_jwt_enabled" {
  type        = string
  default     = "true"
}

variable "waterstream_jwt_mqtt_connect_username" {
  type        = string
  default     = "JWT"
}

variable "waterstream_jwt_audience" {
  type        = string
  default     = "WS"
}

variable "waterstream_jwt_verification_key_file" {
  type        = string
  default     = "local_scripts/jwt/jwt_public.pem"
}

variable "waterstream_jwt_verification_key_algorithm" {
  type        = string
  description = "Type of the key used for JWT signature verification. Valid values are HmacSHA256, HmacSHA384, HmacSHA512, RSA, ECDSA"
  default     = "RSA"
}

variable "waterstream_authorization_rules_file" {
  type = string
  default = ""
}

###########################################
#############       Kafka      ############
###########################################

variable "kafka_bootstrap_servers" {
  type        = string
}

variable "ccloud_api_key" {
}

variable "ccloud_api_secret" {
}

variable "kafka_streams_replication_factor" {
  type        = number
  default     = 3
}

variable "kafka_request_timeout_ms" {
  type = number
  default = 20000
}

variable "kafka_retry_backoff_ms" {
  type = number
  default = 500
}

variable "kafka_fetch_min_bytes" {
  type = number
  default = 10000
}

variable "kafka_sessions_topic" {
  type = string
  default = "mqtt_sessions"
}

variable "kafka_retained_messages_topic" {
  type = string
  default = "mqtt_retained_messages"
}

variable "kafka_connections_topic" {
  type = string
  default = "mqtt_connections"
}

variable "kafka_mqtt_messages_topic" {
  type = string
  default = "mqtt_messages"
}

variable "kafka_messages_topics_patterns" {
  type = string
  description = "Comma-separated: kafkaTopic1:pattern1,kafkaTopic2:pattern2. Patterns follow the MQTT subscription wildcards rules"
  default = ""
}

variable "kafka_messages_topics_prefixes" {
  type = string
  description = "Comma-separated: kafkaTopic1:prefix1/,kafkaTopic2:pre/fix/2. prefix + kafka message key = MQTT topic. Prefixes should not intersect. Prefixes have priority over patterns."
  default = ""
}

variable "kafka_mqtt_topic_to_messages_key" {
  type = string
  description = "Transformation of MQTT topic into Kafka message key - for example: foo/+/bar/+:$1_$2 makes messages in foo/a/bar/b topic to have Kafka key a_b. Placeholders must be separated by some characters - e.g $1$1 is invalid, while $1+$2 is valid"
  default = ""
}
