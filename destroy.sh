#!/bin/sh
set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

terraform destroy -auto-approve
