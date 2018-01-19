#!/usr/bin/env bash

# DOCKER_IP="$(ip addr show docker0 2>/dev/null | grep -Po 'inet \K[\d.]+' 2>/dev/null)"
#
# DOCKER_IP=${DOCKER_IP:-"127.0.0.1"}
# PUBLIC_IP=${PUBLIC_IP:-$DOCKER_IP}
# HOSTNAME=${PUBLIC_IP}.nip.io
# ROUTING_SUFFIX="${HOSTNAME}"
# ORIGIN_IMAGE=${ORIGIN_IMAGE:-"docker.io/openshift/origin"}
# ORIGIN_VERSION=${ORIGIN_VERSION:-"latest"}
#
# oc cluster up --image=${ORIGIN_IMAGE} \
#     --version=${ORIGIN_VERSION} \
#     --service-catalog=true \
#     --routing-suffix=${ROUTING_SUFFIX} \
#     --public-hostname=${HOSTNAME}

minishift config set openshift-version v3.7.1
minishift config set image-caching true

export MINISHIFT_ENABLE_EXPERIMENTAL=y
minishift start --service-catalog

oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin

oc new-project ansible-service-broker

TEMPLATE_URL=${TEMPLATE_URL:-"https://raw.githubusercontent.com/openshift/ansible-service-broker/master/templates/deploy-ansible-service-broker.template.yaml"}
DOCKERHUB_ORG=${DOCKERHUB_ORG:-"ansibleplaybookbundle"} # DocherHub org where APBs can be found, default 'ansibleplaybookbundle'
ENABLE_BASIC_AUTH="false"
VARS="-p BROKER_CA_CERT=$(oc get secret -n kube-service-catalog -o go-template='{{ range .items }}{{ if eq .type "kubernetes.io/service-account-token" }}{{ index .data "service-ca.crt" }}{{end}}{{"\n"}}{{end}}' | tail -n 1)"

# Creating openssl certs to use.
ETCD_DIR=~/Temp/etcd-cert
mkdir -p ${ETCD_DIR}
openssl req -nodes -x509 -newkey rsa:4096 -keyout ${ETCD_DIR}/key.pem -out ${ETCD_DIR}/cert.pem -days 365 -subj "/CN=asb-etcd.ansible-service-broker.svc"
openssl genrsa -out ${ETCD_DIR}/MyClient1.key 2048 \
&& openssl req -new -key ${ETCD_DIR}/MyClient1.key -out ${ETCD_DIR}/MyClient1.csr -subj "/CN=client" \
&& openssl x509 -req -in ${ETCD_DIR}/MyClient1.csr -CA ${ETCD_DIR}/cert.pem -CAkey ${ETCD_DIR}/key.pem -CAcreateserial -out ${ETCD_DIR}/MyClient1.pem -days 1024

ETCD_CA_CERT=$(cat /tmp/etcd-cert/cert.pem | base64)
BROKER_CLIENT_CERT=$(cat /tmp/etcd-cert/MyClient1.pem | base64)
BROKER_CLIENT_KEY=$(cat /tmp/etcd-cert/MyClient1.key | base64)

curl -s $TEMPLATE_URL \
  | oc process \
  -n ansible-service-broker \
  -p DOCKERHUB_ORG="$DOCKERHUB_ORG" \
  -p ENABLE_BASIC_AUTH="$ENABLE_BASIC_AUTH" \
  -p ETCD_TRUSTED_CA_FILE=/var/run/etcd-auth-secret/ca.crt \
  -p BROKER_CLIENT_CERT_PATH=/var/run/asb-etcd-auth/client.crt \
  -p BROKER_CLIENT_KEY_PATH=/var/run/asb-etcd-auth/client.key \
  -p ETCD_TRUSTED_CA="$ETCD_CA_CERT" \
  -p BROKER_CLIENT_CERT="$BROKER_CLIENT_CERT" \
  -p BROKER_CLIENT_KEY="$BROKER_CLIENT_KEY" \
  -p NAMESPACE=ansible-service-broker \
  $VARS -f - | oc create -f -
if [ "$?" -ne 0 ]; then
  echo "Error processing template and creating deployment"
  exit
fi
