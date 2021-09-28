#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

echo "********** Generating JWT keypair **********"

PRIVATE_KEY=jwt_private.pem
PRIVATE_PKCS8_KEY=jwt_private.pkcs8.pem
PUBLIC_KEY=jwt_public.pem

mkdir -p $SCRIPT_DIR/jwt
cd $SCRIPT_DIR/jwt

openssl genrsa -out $PRIVATE_KEY 2048
openssl pkcs8 -topk8 -inform PEM -in $PRIVATE_KEY -out $PRIVATE_PKCS8_KEY -nocrypt
openssl rsa -in $PRIVATE_KEY -outform PEM -pubout -out $PUBLIC_KEY

