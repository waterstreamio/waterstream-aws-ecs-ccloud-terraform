#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

cd $SCRIPT_DIR/..

WATERSTREAM_LB=`terraform output waterstream_lb`

cd $SCRIPT_DIR

mosquitto_pub -h $WATERSTREAM_LB -p 1883 -t "sample_topic" -i mosquitto_l_t2 -q 0 -m "Hello, world!" \
      --cafile tls/waterstream_demo_ca.pem \
      --cert tls/client_cl2.crt --key tls/client_cl2.pkcs8.key
