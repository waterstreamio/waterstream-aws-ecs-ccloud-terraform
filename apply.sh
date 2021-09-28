#!/bin/sh
set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

if [ -f "$SCRIPT_DIR/ssh_keypair/waterstream-key" -a -f "$SCRIPT_DIR/ssh_keypair/waterstream-key.pub" ]; then
  echo Testbox default keypair exists, not generating it
else
  echo Generating testbox default keypair
  $SCRIPT_DIR/ssh_keypair/generate.sh
fi

if [ -f "$SCRIPT_DIR/local_scripts/jwt/jwt-public.pem" ]; then
  echo JWT default public key exists, not generating a keypair
else
  echo Generating default JWT keypair
  $SCRIPT_DIR/local_scripts/generate_jwt_keypair.sh
fi

terraform apply -auto-approve
