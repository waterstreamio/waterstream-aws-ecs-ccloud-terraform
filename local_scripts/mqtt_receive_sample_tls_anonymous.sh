#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

cd $SCRIPT_DIR/..

WATERSTREAM_LB=`terraform output waterstream_lb`

cd $SCRIPT_DIR

mosquitto_sub -h $WATERSTREAM_LB -p 1883 -t "#" -i mosquitto_l_ta1 -q 0 -v \
      --cafile tls/waterstream_demo_ca.pem
