#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

cd $SCRIPT_DIR/..

WATERSTREAM_LB=`terraform output -raw waterstream_lb_hostname`

cd $SCRIPT_DIR

echo lb=$WATERSTREAM_LB
mosquitto_sub -h $WATERSTREAM_LB -p 1883 -t "#" -i mosquitto_l_p1 -q 0 -v
