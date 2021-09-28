#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

cd $SCRIPT_DIR/..

TESTBOX=`terraform output waterstream_testbox`

cd $SCRIPT_DIR

scp -i $SCRIPT_DIR/../ssh_keypair/waterstream-key ec2-user@$TESTBOX:/home/ec2-user/tls/root/waterstream_demo_ca.pem tls
