# Waterstream AWS ECS with Confluent Cloud Terraform scripts 

Deploy scripts for [Waterstream](https://waterstream.io/) - MQTT broker build on top of [Apache Kafka](https://kafka.apache.org/)

Scripts in this repository set up Waterstream + Linux testbox with MQTT and Kafka clients.
Supports MQTT SSL (including client authentication) and JWT authentication.
MQTT load balancer endpoint is exposed on the internet.
Waterstream metrics can be monitored either with Prometheus + Grafana or with the CloudWatch Metrics.

Kafka cluster creation isn't included in these scripts, it is expected to be provided by [Confluent Cloud](https://confluent.cloud/).

## Pre-requisites 

- AWS account
- [Confluent Cloud account](https://confluent.cloud/), locally installed `ccloud` CLI recommended
- Terraform installed locally
- Waterstream license file or AWS marketplace subscription for Waterstream container
- DockerHub account, credentials confgured in AWS Secrets 
  (See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html#private-auth-enable for the creation instructions.)

### Required AWS permissions

AWS user must have the following permissions:

- ecs:RegisterTaskDefinition
- ecs:CreateService
- logs:ListTagsLogGroup
- iam:CreateRole
- iam:GetRole
- iam:ListInstanceProfilesForRole
- iam:DeleteRole
- ec2:DeleteInternetGateway
- ec2:AllocateAddress
- ec2:CreateNatGateway
- logs:CreateLogGroup
- iam:CreatePolicy
- iam:GetPolicy
- iam:GetPolicyVersion
- iam:ListPolicyVersions
- iam:DeletePolicy
- iam:AttachRolePolicy
- iam:ListEntitiesForPolicy
- iam:DetachRolePolicy
- ec2:DeleteRouteTable
- ec2:DeleteNatGateway
- ec2:ReleaseAddress
- ec2:RevokeSecurityGroupEgress
- ec2:DeleteSecurityGroup
- kafka:CreateCluster
- ec2:AuthorizeSecurityGroupEgress
- ec2:AuthorizeSecurityGroupIngress
- ec2:ImportKeyPair
- ec2:CreateTags
- ec2:AssociateAddress
- ec2:TerminateInstances
- ec2:DisassociateAddress
- ec2:DeleteKeyPair
- ec2:RevokeSecurityGroupIngress
- iam:CreateInstanceProfile
- iam:GetInstanceProfile
- iam:RemoveRoleFromInstanceProfile
- iam:DeleteInstanceProfile
- iam:AddRoleToInstanceProfile
- iam:PassRole
- iam:CreateServiceLinkedRole
- iam:ListRolePolicies
- elasticloadbalancing:DescribeTags
- elasticloadbalancing:DescribeLoadBalancerAttributes
- elasticloadbalancing:ModifyLoadBalancerAttributes
- elasticloadbalancing:ModifyTargetGroup
- elasticloadbalancing:DescribeTargetGroupAttributes
- elasticloadbalancing:ModifyTargetGroupAttributes
- elasticloadbalancing:SetSecurityGroups
- ec2:DeleteRoute
- elasticfilesystem:CreateFileSystem
- elasticfilesystem:CreateAccessPoint
- elasticfilesystem:CreateMountTarget
- elasticfilesystem:DeleteAccessPoint
- elasticfilesystem:DeleteFileSystem
- elasticfilesystem:DeleteMountTarget
- elasticfilesystem:DescribeLifecycleConfiguration
- elasticfilesystem:DescribeMountTargets
- elasticfilesystem:ClientMount
- elasticfilesystem:DescribeMountTargetSecurityGroups
- ssm:PutParameter
- cloudformation:GetTemplate
- ssm:AddTagsToResource
- ssm:DeleteParameter
- iam:DeleteRolePolicy
- iam:PutRolePolicy
- cloudwatch:PutDashboard
- cloudwatch:GetDashboard
- cloudwatch:DeleteDashboards
- ec2:DeleteTags


Achieved with policies:

- AmazonECS_FullAccess
- CloudWatchLogsFullAccess
- custom WaterstreamDeployAdditional

You can import `WaterstreamDeployAdditional` policy from `WaterstreamDeployAdditional_policy.json` file. 

## Create Kafka topics

To follow these steps you'll need Confluent Cloud CLI: https://docs.confluent.io/current/cloud/cli/install.html
After installation log into the cloud:
```shell script
ccloud login
```

And run the topic creation script with your cluster ID (not to mix up with cluster name!) to create the cheapest possible set of the topics:
```shell script
./createTopicsCCloudMinimal.sh <cluster_ID> 
```
If you want better performance, you can copy the `createTopicsCCloudMinimal.sh` script and customize `DEFAULT_MESSAGES_TOPIC_PARTITIONS` and 
`DEFAULT_MESSAGES_TOPIC_PARTITIONS` environment variables. You may also want to add more Kafka topics if you'd like
to segragate messages for different MQTT topics 
(you'll also need to specify `DEFAULT_MESSAGES_TOPIC_PARTITIONS` or `DEFAULT_MESSAGES_TOPIC_PARTITIONS` parameter in Waterstream in this case).

When you don't need Kafka topics any more you can delete them:
```shell script
./deleteTopicsCCloud.sh <cluster_ID> 
```

Some other useful commands you may use after `ccloud login`:

- List Kafka clusters: `ccloud kafka cluster list`
- Describe the cluster: `ccloud kafka cluster describe <cluster_ID>` - the "Endpoint" row contains the bootstrap servers after "SASL_SSL://" prefix
- List topics of the Kafka cluster: `ccloud kafka topic list --cluster <cluster_ID>`
- Delete the single topic:  `ccloud kafka topic delete <topic name> --cluster <cluster_ID>`

## Generate the SSH keypair

Keypair is needed for the access to the testbox. You can generate it with the following command:
```shell script
./ssh_keypair/generate.sh
```

Alternatively, you can use the existing keypair - in this case specify `aws_keypair_public_key_location ` and
`aws_keypair_private_key_location` in `config.auto.tfvars`

## Configure

Copy `config.auto.tfvars.example` into `config.auto.tfvars`, customize it:

    cp config.auto.tfvars.example config.auto.tfvars
    vim config.auto.tfvars

## Run

First, initialize the Terraform:

    terraform init

Then run the Waterstream:

    ./apply.sh

Or, if you prefer to run the commands individually:

    ssh_keypair/generate.sh
    # If you want to use JWT with the example keypair:
    local_scripts/generate_jwt_keypair.sh 
    terraform apply -auto-approve

When done it will output the URLs of the resources it has created:
- MQTT server endpoint: `waterstream_lb`
- Grafana URL (for monitoring): `waterstream_grafana_lb`
- Testbox hostname: `waterstream_testbox` 

To stop Waterstream:

    ./destroy.sh

Or:

    terraform destroy -auto-approve

## Try out

SSH into the testbox:

     ssh -i ssh_keypair/waterstream-key ec2-user@<waterstream_testbox>

Testbox has Kafka and MQTT clients (mosquitto-client). You can use it to teest client connection.

Listen to the messages on all MQTT topics, use QoS 0 for subscription:

    mosquitto_sub -h <hostname> -p 1883 -t "#" -i mosquitto_1 -q 0 -v
    
Send "Hello, world!" message to "sample_topic" topic with QoS0:
 
    mosquitto_pub -h <hostname> -p 1883 -t "sample_topic" -i mosquitto_2 -q 0 -m "Hello, world!" 

If you want to test JWT authentication you can use https://jwt.io/ or https://token.dev/. 
Choose one of the "RS.." algorithms, put public key from `local_scripts/jwt/jwt_public.pem`, private - from `local_scripts/jwt/jwt_private.pem`.

    # For the local machine. On the testbox just copy-paste the corresponding output from the Terraform 
    WATERSTREAM_LB_HOSTNAME=`terraform output -raw waterstream_lb_hostname` 
    JWT_TOKEN=<sample token goes here>

Having thus configured the environment variables you can listen to the messages:

    mosquitto_sub -h $WATERSTREAM_LB -p 1883 -t "#" -i mosquitto_l_p1 -q 0 -v -u JWT -P $JWT_TOKEN

and publish the messages:

    mosquitto_pub -h $WATERSTREAM_LB -p 1883 -t "sample_topic" -i mosquitto_l_p2 -q 0 -u JWT -P $JWT_TOKEN -m "Hello, world" 
    
## Monitoring 

Output variable `waterstream_grafana_lb` contains the link to the Grafana. 
Open it in the browser, default credentials are admin/admin - you'll be prompted to change it first time you access it.
Waterstream dashboard is installed in Grafana, you can see the metrics there.

## SSL/TLS

If SSL is enabled (`waterstream_enable_ssl=true`) you can try it out on the testbox:

    mosquitto_pub -h <hostname> -p 1883 -t "sample_topic" -i mosquitto_2 -q 0 -m "Hello, world!" --cafile /home/ec2-user/tls/root/waterstream_demo_ca.pem

