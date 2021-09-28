#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

cd $SCRIPT_DIR/..

WATERSTREAM_LB=`terraform output -raw waterstream_lb_hostname`

cd $SCRIPT_DIR

mosquitto_pub -h $WATERSTREAM_LB -p 1883 -t "sample_topic" -i mosquitto_l_p2 -q 0 -m "Hello, world!"
