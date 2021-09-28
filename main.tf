provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_cloudwatch_log_group" "waterstream_logs" {
  name = "${var.waterstream_env_name}_logs"
}

resource "aws_iam_role" "testbox-role" {
  name = "${var.waterstream_env_name}-testbox-role"
  assume_role_policy = data.aws_iam_policy_document.ec2-assume-role.json
}

data "aws_iam_policy_document" "ec2-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "testbox-permission-policy" {
  name        = "${var.waterstream_env_name}-testbox-permission-policy"
  description = "Grants permissions for Waterstream testbox"
  policy      = data.aws_iam_policy_document.testbox-permissions-policy.json
}

resource "aws_iam_role_policy_attachment" "testbox-permissions-attach" {
  role       = aws_iam_role.testbox-role.name
  policy_arn = aws_iam_policy.testbox-permission-policy.arn
}

data "aws_iam_policy_document" "testbox-permissions-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = ["elasticfilesystem:DescribeMountTargets"]
    resources = [
      aws_efs_file_system.waterstream-resources.arn
    ]
  }
}


resource "aws_security_group" "testbox_sg" {
  name = "testbox-allow-ssh"
  vpc_id = aws_vpc.aws-vpc.id
  ingress {
    cidr_blocks = [var.testbox_ingress_cidr]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [var.testbox_ingress_cidr]
    #Allow PING
    from_port = 8
    to_port = 0
    protocol = "icmp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "waterstream-kp" {
  key_name = "${var.waterstream_env_name}-testbox-keypair"
  public_key = file(var.aws_keypair_public_key_location)
}

resource "aws_eip" "waterstream_testbox_ip" {
  instance = aws_instance.waterstream_testbox.id
  vpc      = true
}

resource "aws_iam_instance_profile" "waterstream_testbox_profile" {
  name = "${var.waterstream_env_name}_testbox_profile"
  role = aws_iam_role.testbox-role.name
}

data "template_file" "testbox_cloud_init_yml" {
  template = file("${path.module}/testbox_scripts/testbox_cloud_init.yml.tpl")
  vars = {
    aws_region = var.region
    setup_role_arn = aws_iam_role.testbox-role.arn

    kafka_bootstrap = var.kafka_bootstrap_servers
    waterstream_resources_efs_id = aws_efs_file_system.waterstream-resources.id
    SESSION_TOPIC = var.kafka_sessions_topic
    RETAINED_MESSAGES_TOPIC = var.kafka_retained_messages_topic
    CONNECTION_TOPIC = var.kafka_connections_topic
    KAFKA_MESSAGES_DEFAULT_TOPIC = var.kafka_mqtt_messages_topic
    HEARTBEAT_TOPIC = "__waterstream_heartbeat"
  }
}

data "template_file" "testbox_ssl_broker_cnf" {
  template = file("${path.module}/testbox_scripts/broker.cnf.tpl")
  vars = {
    mqtt_broker_cn = aws_lb.waterstream_mqtt_lb.dns_name
  }
}

data "aws_ami" "testbox_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "waterstream_testbox" {
  depends_on = [
    aws_efs_file_system.waterstream-resources,
    aws_efs_mount_target.waterstream-resouces-priv-1,
    aws_efs_mount_target.waterstream-resouces-priv-2,
    aws_efs_mount_target.waterstream-resouces-priv-3
  ]

  lifecycle {
    #Workaround for https://github.com/hashicorp/terraform-provider-aws/issues/5011
    #Comment out if you actually want to update the user_data
    ignore_changes = [user_data]
  }

  ami = data.aws_ami.testbox_ami.id

  instance_type = "t3.nano"

  iam_instance_profile = aws_iam_instance_profile.waterstream_testbox_profile.name

  key_name = aws_key_pair.waterstream-kp.key_name

  subnet_id = aws_subnet.public_subnet_1.id

  vpc_security_group_ids = [aws_security_group.testbox_sg.id]

  user_data = data.template_file.testbox_cloud_init_yml.rendered

  tags = {
    environment = "demo"
    app = "waterstream-demo"
    name = "waterstream-testbox"
  }
}

output "waterstream_testbox" {
  description = "Testbox URL"
  value       = aws_eip.waterstream_testbox_ip.public_dns
}

resource "null_resource" "wait_testbox_kafka" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [aws_instance.waterstream_testbox]

  provisioner "remote-exec" {
    connection {
      host = aws_eip.waterstream_testbox_ip.public_dns
      user = "ec2-user"
      private_key = file(var.aws_keypair_private_key_location)
    }

    inline = ["/home/ec2-user/wait_cloud_init_complete.sh"]
  }
}

resource "null_resource" "testbox_tls" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [aws_instance.waterstream_testbox,
    null_resource.wait_testbox_kafka]

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ec2-user/tls",
      "sudo mkdir -p /home/ec2-user/plain",
      "sudo mkdir -p /home/ec2-user/tls/root",
      "sudo mkdir -p /home/ec2-user/tls/mqtt_broker",
      "sudo mkdir -p /home/ec2-user/tls/clients",
      "sudo mkdir -p /var/waterstream_resources/tls",
      "sudo mkdir -p /var/waterstream_resources/tls/root",
      "sudo mkdir -p /var/waterstream_resources/tls/mqtt_broker",
      "sudo mkdir -p /var/waterstream_resources/tls/clients",
      "sudo mkdir -p /var/waterstream_resources/prometheus/etc",
      "sudo mkdir -p /var/waterstream_resources/prometheus/tmp",
      "sudo mkdir -p /var/waterstream_resources/grafana/etc-prov/datasources",
      "sudo mkdir -p /var/waterstream_resources/grafana/etc-prov/dashboards",
      "sudo mkdir -p /var/waterstream_resources/grafana/dashboards",
      "sudo mkdir -p /var/waterstream_resources/grafana/data",
      #Pick the persistent data in case of the Testbox re-creation
      "sudo cp -r /var/waterstream_resources/tls/root/* /home/ec2-user/tls/root",
      "sudo chown -R ec2-user /home/ec2-user/tls",
      "sudo chown -R ec2-user /home/ec2-user/plain",
      "sudo chown -R ec2-user /var/waterstream_resources/prometheus",
      "sudo chown -R ec2-user /var/waterstream_resources/grafana",
      "sudo chmod a+w -R /var/waterstream_resources/grafana/data"
    ]
  }

  provisioner "file" {
    source = "testbox_scripts/config.sh"
    destination = "/home/ec2-user/tls/config.sh"
  }
  provisioner "file" {
    source = "testbox_scripts/generate_ca.sh"
    destination = "/home/ec2-user/tls/generate_ca.sh"
  }
  provisioner "file" {
    source = "testbox_scripts/generate_broker_cert.sh"
    destination = "/home/ec2-user/tls/generate_broker_cert.sh"
  }
  provisioner "file" {
    source = "testbox_scripts/generate_client_cert.sh"
    destination = "/home/ec2-user/tls/generate_client_cert.sh"
  }
  provisioner "file" {
    source = "testbox_scripts/copy_waterstream_resources.sh"
    destination = "/home/ec2-user/tls/copy_waterstream_resources.sh"
  }
  provisioner "file" {
    source = "testbox_scripts/waterstream_demo_ca.cnf"
    destination = "/home/ec2-user/tls/root/waterstream_demo_ca.cnf"
  }
  provisioner "file" {
    content = data.template_file.testbox_ssl_broker_cnf.rendered
    destination = "/home/ec2-user/tls/mqtt_broker/mqtt_broker.cnf"
  }

  //Test scripts
  provisioner "file" {
    content = <<EOF
      #!/bin/sh
      mosquitto_pub -h  ${aws_lb.waterstream_mqtt_lb.dns_name} -p 1883 -t "sample_topic" -i mosquitto_p2 -q 0 -m "Hello, world!"
    EOF
    destination = "/home/ec2-user/plain/mqtt_send_sample.sh"
  }
  provisioner "file" {
    content = <<EOF
      #!/bin/sh
      mosquitto_sub -h ${aws_lb.waterstream_mqtt_lb.dns_name} -p 1883 -t "#" -i mosquitto_p1 -q 0 -v
    EOF
    destination = "/home/ec2-user/plain/mqtt_receive_sample.sh"
  }
  provisioner "file" {
    content = <<EOF
      #!/bin/sh
      mosquitto_pub -h  ${aws_lb.waterstream_mqtt_lb.dns_name} -p 1883 -t "sample_topic" -i mosquitto_t2 -q 0 -m "Hello, world!" \
          --cafile /home/ec2-user/tls/root/waterstream_demo_ca.pem \
          --cert /home/ec2-user/tls/clients/client_client2.crt --key /home/ec2-user/tls/clients/client_client2.pkcs8.key
    EOF
    destination = "/home/ec2-user/tls/mqtt_send_sample.sh"
  }
  provisioner "file" {
    content = <<EOF
      #!/bin/sh
      mosquitto_pub -h  ${aws_lb.waterstream_mqtt_lb.dns_name} -p 1883 -t "sample_topic" -i mosquitto_at2 -q 0 -m "Hello, world!" \
          --cafile /home/ec2-user/tls/root/waterstream_demo_ca.pem
    EOF
    destination = "/home/ec2-user/tls/mqtt_send_sample_anonymous.sh"
  }
  provisioner "file" {
    content = <<EOF
      #!/bin/sh
      mosquitto_sub -h ${aws_lb.waterstream_mqtt_lb.dns_name} -p 1883 -t "#" -i mosquitto_t1 -q 0 -v \
          --cafile /home/ec2-user/tls/root/waterstream_demo_ca.pem \
          --cert /home/ec2-user/tls/clients/client_client1.crt --key /home/ec2-user/tls/clients/client_client1.pkcs8.key
    EOF
    destination = "/home/ec2-user/tls/mqtt_receive_sample.sh"
  }
  provisioner "file" {
    content = <<EOF
      #!/bin/sh
      mosquitto_sub -h ${aws_lb.waterstream_mqtt_lb.dns_name} -p 1883 -t "#" -i mosquitto_at1 -q 0 -v \
          --cafile /home/ec2-user/tls/root/waterstream_demo_ca.pem
    EOF
    destination = "/home/ec2-user/tls/mqtt_receive_sample_anonymous.sh"
  }
  //End Test scripts

  //Prometheus
  provisioner "file" {
    content = <<EOF
      global:
        scrape_interval: 1m
        scrape_timeout: 10s
      scrape_configs:
        - job_name: waterstream-kafka
          sample_limit: 10000
          file_sd_configs:
            - files: [ "/tmp/cwagent_ecs_auto_sd.yaml" ]
    EOF
    destination = "/var/waterstream_resources/prometheus/etc/prometheus.yml"
  }
  //end Prometheus

  //Grafana
  provisioner "file" {
    source = "grafana/dashboard-provider.yaml"
    destination = "/var/waterstream_resources/grafana/etc-prov/dashboards/provider.yaml"
  }

  provisioner "file" {
    source = "grafana/datasources.yaml"
    destination = "/var/waterstream_resources/grafana/etc-prov/datasources/datasources.yaml"
  }

  provisioner "file" {
    source = "grafana/dashboards/waterstream_grafana_dashboard.json"
    destination = "/var/waterstream_resources/grafana/dashboards/waterstream_grafana_dashboard.json"
  }
  //end Grafana


  provisioner "remote-exec" {
    inline = [
      "chmod a+x /home/ec2-user/tls/*.sh",
      "chmod a+x /home/ec2-user/plain/*.sh",
      "/home/ec2-user/tls/generate_ca.sh",
      "/home/ec2-user/tls/generate_broker_cert.sh",
      "/home/ec2-user/tls/generate_client_cert.sh client1",
      "/home/ec2-user/tls/generate_client_cert.sh client2",
      "sudo /home/ec2-user/tls/copy_waterstream_resources.sh"
    ]
  }

  connection {
    host = aws_eip.waterstream_testbox_ip.public_dns
    user = "ec2-user"
    private_key = file(var.aws_keypair_private_key_location)
  }
}

resource "aws_efs_file_system" "waterstream-resources" {
  creation_token = "waterstream-resources-fs"

  encrypted = true

  tags = {
    Name = "waterstream-resources"
  }
}

resource "aws_efs_access_point" "waterstream-resources-broker-ap" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  root_directory {
    path = "/tls/mqtt_broker"
  }
}

resource "aws_efs_access_point" "waterstream-prometheus-etc-ap" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  root_directory {
      path = "/prometheus/etc"
  }
}

resource "aws_efs_access_point" "waterstream-prometheus-tmp-ap" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  root_directory {
    path = "/prometheus/tmp"
  }
}

resource "aws_efs_access_point" "waterstream-grafana-etc-prov-ap" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  root_directory {
    path = "/grafana/etc-prov"
  }
}

resource "aws_efs_access_point" "waterstream-grafana-dashboards-ap" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  root_directory {
    path = "/grafana/dashboards"
  }
}

resource "aws_efs_access_point" "waterstream-grafana-data-ap" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  root_directory {
    path = "/grafana/data"
  }
}

resource "aws_security_group" "efs-sg" {
  name = "efs-sg"
  vpc_id = aws_vpc.aws-vpc.id
  ingress {
    cidr_blocks = [var.vpc_cidr]
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
  }
}

resource "aws_efs_mount_target" "waterstream-resouces-priv-1" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  subnet_id      = aws_subnet.private_subnet_1.id
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_efs_mount_target" "waterstream-resouces-priv-2" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  subnet_id      = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_efs_mount_target" "waterstream-resouces-priv-3" {
  file_system_id = aws_efs_file_system.waterstream-resources.id
  subnet_id      = aws_subnet.private_subnet_3.id
  security_groups = [aws_security_group.efs-sg.id]
}

# ******************* Output ***********************

output "waterstream_lb_hostname" {
  description = "Waterstream MQTT endpoint - just hostname"
  value = aws_lb.waterstream_mqtt_lb.dns_name
}

output "waterstream_lb" {
  description = "Waterstream MQTT endpoint"
  value = "${aws_lb.waterstream_mqtt_lb.dns_name}:1883"
}

output "waterstream_grafana_lb" {
  description = "Grafana endpoint"
  value = "http://${aws_lb.waterstream_grafana_lb.dns_name}:3000"
}

