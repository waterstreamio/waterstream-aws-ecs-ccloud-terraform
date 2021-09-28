#cloud-config
packages:
    - openjdk-11-jdk
    - amazon-efs-utils
    - gcc
    - gcc-c++
    - openssl-devel
write_files:
    - content: |
          #!/bin/sh
          export KAFKA_BOOTSTRAP=${kafka_bootstrap}
          export AWS_REGION=${aws_region}
      path: /home/ec2-user/config.sh
    - content: |
           #!/bin/sh
           while [ ! -f /home/ec2-user/cloud_init_complete.txt ]; do
             echo Testbox cloud-init not complete yet, sleeping...
             sleep 10;
           done
           echo Testbox cloud-init complete
      path: /home/ec2-user/wait_cloud_init_complete.sh
      permissions: '0555'
    - content: |
         export PATH=$PATH:/home/ec2-user/kafka_2.12-2.6.0/bin
         export KAFKA_BOOTSTRAP=${kafka_bootstrap}
      path: /home/ec2-user/.profile
      permissions: '0555'
    - content: |
         /usr/local/lib
      path: /etc/ld.so.conf.d/local_libs.conf
runcmd:
    - cd /home/ec2-user
    - wget https://archive.apache.org/dist/kafka/2.6.0/kafka_2.12-2.6.0.tgz
    - tar -xzf kafka_2.12-2.6.0.tgz
    - rm kafka_2.12-2.6.0.tgz
    - export KAFKA_BOOTSTRAP=${kafka_bootstrap}
    - curl http://169.254.169.254/latest/meta-data/instance-id -o /home/ec2-user/instance-id.txt
    - aws --region ${aws_region} ec2 create-tags --resources `cat /home/ec2-user/instance-id.txt` --tags Key=KafkaInitialized,Value=true
    - cd /home/ec2-user
    - sudo pip3 install botocore
    - mkdir /var/waterstream_resources
    - echo Mounting EFS ${waterstream_resources_efs_id}
    - mount -t efs ${waterstream_resources_efs_id}:/ /var/waterstream_resources
    - echo "true" > /home/ec2-user/cloud_init_complete.txt
    - echo Downloading and building Mosquitto clients
    - curl "https://mosquitto.org/files/source/mosquitto-2.0.10.tar.gz" -o /home/ec2-user/mosquitto-2.0.10.tar.gz
    - tar -xvzf mosquitto-2.0.10.tar.gz
    - rm mosquitto-2.0.10.tar.gz
    - cd mosquitto-2.0.10
    - make install WITH_CJSON=no
    - ldconfig
    - chown -R ec2-user /home/ec2-user/mosquitto-2.0.10