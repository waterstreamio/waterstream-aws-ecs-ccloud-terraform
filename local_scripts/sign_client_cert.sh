#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`


CLIENT_NAME=$1

cd $SCRIPT_DIR/..

TESTBOX=`terraform output waterstream_testbox`

cd $SCRIPT_DIR


echo "********** Signing Client $CLIENT_NAME Certificate **********"

#scp ec2-user@$TESTBOX:/home/ec2-user/tls/root/waterstream_demo_ca.pem tls

CLIENT_KEY=$SCRIPT_DIR/tls/client_${CLIENT_NAME}.key
CLIENT_PKCS8_KEY=$SCRIPT_DIR/tls/client_${CLIENT_NAME}.pkcs8.key
CLIENT_CSR_NAME=client_${CLIENT_NAME}.csr
CLIENT_CSR=$SCRIPT_DIR/tls/$CLIENT_CSR_NAME
CLIENT_CRT_NAME=client_${CLIENT_NAME}.crt
CLIENT_CRT=$SCRIPT_DIR/tls/$CLIENT_CRT_NAME


REMOTE_SIGN_FOLDER=/home/ec2-user/tls/client_sign

REMOTE_TLS_BASE_FOLDER=/home/ec2-user/tls

REMOTE_ROOT_CA_FOLDER=$REMOTE_TLS_BASE_FOLDER/root
REMOTE_ROOT_CA_KEY=$REMOTE_ROOT_CA_FOLDER/waterstream_demo_ca.key
REMOTE_ROOT_CA_CERT=$REMOTE_ROOT_CA_FOLDER/waterstream_demo_ca.pem


ssh ec2-user@$TESTBOX mkdir -p $REMOTE_SIGN_FOLDER
scp $CLIENT_CSR ec2-user@$TESTBOX:$REMOTE_SIGN_FOLDER/$CLIENT_CSR_NAME
ssh ec2-user@$TESTBOX openssl x509 -req -in $REMOTE_SIGN_FOLDER/$CLIENT_CSR_NAME -CA $REMOTE_ROOT_CA_CERT -CAkey $REMOTE_ROOT_CA_KEY -CAcreateserial -out $REMOTE_SIGN_FOLDER/$CLIENT_CRT_NAME -days 500 -sha256
scp ec2-user@$TESTBOX:$REMOTE_SIGN_FOLDER/$CLIENT_CRT_NAME $CLIENT_CRT

## generate key
#openssl genrsa -out $CLIENT_KEY 2048
### convert the key to PKCS#8
#openssl pkcs8 -topk8 -inform PEM -outform PEM -in $CLIENT_KEY -out $CLIENT_PKCS8_KEY -nocrypt
### generate Certificate Signing Request
#openssl req -new -key $CLIENT_KEY -out $CLIENT_CSR -subj "/C=IT/O=SimpleMatter/OU=WaterstreamTest/CN=${CLIENT_NAME}"
## sign CSR with Root CA key
#openssl x509 -req -in $CLIENT_CSR -CA $ROOT_CA_CERT -CAkey $ROOT_CA_KEY -CAcreateserial -out $CLIENT_CRT -days 500 -sha256



