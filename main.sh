#!/usr/bin/env bash

set -e

# usage:
#


if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided"
    echo "Usage: ./main.sh namespace dspa_name"
    exit 1
fi


namespace=$1
dspa=$2
vars_file=vars.yaml

oc apply -f manifests/minio-route.yaml
echo "Deployed minio route"


cp templates/vars-templates.yaml ./vars.yaml
cp templates/config-template.json configs/config.json
cp templates/artifact_script-template.sh configs/artifact_script.sh

minio_host_secure="false"
minio_host_scheme="http"
minio_bucket=mlpipeline
minio_host=$(oc -n ${namespace} get route minio -o yaml | yq .spec.host)
accesskey=$(oc -n ${namespace} get secret mlpipeline-minio-artifact  -o jsonpath='{.data.accesskey}' | base64 -d )
secretkey=$(oc -n ${namespace} get secret mlpipeline-minio-artifact  -o jsonpath='{.data.secretkey}' | base64 -d )
dbpsw=$(oc -n ${namespace} get secret ds-pipeline-db-$2  -o jsonpath='{.data.password}' | base64 -d )
ocserver=$(oc whoami --show-server | tr '//' ' ' | tr ':' ' ' | awk '{print $2}')
port=$(oc whoami --show-server | tr '//' ' ' | tr ':' ' ' | awk '{print $3}')

var=${minio_host_secure} yq -i '.secure=env(var)' ${vars_file}
var=${minio_host_scheme} yq -i '.ARTIFACT_ENDPOINT_SCHEME=env(var)' ${vars_file}
var=${minio_host} yq -i '.ARTIFACT_ENDPOINT=env(var)' ${vars_file}
var=${minio_host} yq -i '.MINIO_SERVICE_SERVICE_HOST=env(var)' ${vars_file}

var=${namespace} yq -i '.POD_NAMESPACE=env(var)' ${vars_file}
var=${accesskey} yq -i '.OBJECTSTORECONFIG_ACCESSKEY=env(var)' ${vars_file}
var=${accesskey} yq -i '.accesskey=env(var)' ${vars_file}
var=${secretkey} yq -i '.OBJECTSTORECONFIG_SECRETACCESSKEY=env(var)' ${vars_file}
var=${secretkey} yq -i '.secretkey=env(var)' ${vars_file}
var=${dbpsw} yq -i '.DBCONFIG_PASSWORD=env(var)' ${vars_file}
var=${ocserver} yq -i '.KUBERNETES_SERVICE_HOST=env(var)' ${vars_file}
var="${port}" yq -i '.KUBERNETES_SERVICE_PORT=strenv(var)' ${vars_file}
var="pipeline-runner-${dspa}" yq -i '.DEFAULTPIPELINERUNNERSERVICEACCOUNT=strenv(var)' configs/config.json  -P -o json

ocserver=$(oc whoami --show-server)
sed "s;<api_server>;${ocserver};g" templates/persistence-flags_template.txt  > persistence-flags.txt
sed "s;<namespace>;${namespace};g" templates/forward-db_template.sh  > forward-db.sh
sed -i "s;<dspa>;${dspa};g" forward-db.sh
sed "s;<namespace>;${namespace};g" templates/forward-minio_template.sh  > forward-minio.sh
sed -i "s;<dspa>;${dspa};g" forward-minio.sh

sed -i "s;<S3_ENDOINT>;${minio_host_scheme}://${minio_host};g" configs/artifact_script.sh
sed -i "s;<S3_BUCKET>;${minio_bucket};g" configs/artifact_script.sh


echo
GR='\033[0;32m'
NC='\033[0m'
echo -e "${GR}Fetching a ca.crt file from scheduledworkflow pod path  /var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
pod=$(oc get pod  -l app=minio-$2 --no-headers=true | awk '{print $1}')
oc exec -n $1 $pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > ca.crt
oc whoami --show-token > token
echo -e "Done, ensure this ca.crt file is added to /var/run/secrets/kubernetes.io/serviceaccount/ca.crt on the local filesystem to dupe apiserver."
echo sudo mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
echo sudo cp ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
echo sudo cp token /var/run/secrets/kubernetes.io/serviceaccount/token
echo -e ${NC}

echo "Run port-forward-minio, port-forward-db via configuration Run"
