#!/usr/bin/env bash

set -e

if [ $# != 4 ]; then
    >&2 echo "4 arguments required"
    echo "Usage: ./main.sh namespace dspa_name kube_config_path output_dir"
    exit 1
fi


namespace=$1
dspa=$2
kube_config_path=$3
output_dir=$4

if [ ! -d "${output_dir}" ];
then
 echo "Directory ${output_dir} DOES NOT exists."
 exit
fi

vars_file=${output_dir}/vars.yaml

oc apply -f manifests/minio-route.yaml
echo "Deployed minio route"

cp templates/vars-templates.yaml ${vars_file}
cp templates/config-template.json ${output_dir}/config.json
cp templates/artifact_script-template.sh ${output_dir}/artifact_script.sh
cp templates/converter.py ${output_dir}/converter.py
cp templates/sample_config.json ${output_dir}/sample_config.json



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
var="pipeline-runner-${dspa}" yq -i '.DEFAULTPIPELINERUNNERSERVICEACCOUNT=strenv(var)' ${output_dir}/config.json  -P -o json

ocserver=$(oc whoami --show-server)
sed "s;<api_server>;${ocserver};g" templates/persistence-flags_template.txt  > ${output_dir}/persistence-flags.txt
sed -i "s;<namespace>;${namespace};g" ${output_dir}/persistence-flags.txt
sed "s;<namespace>;${namespace};g" templates/forward-db_template.sh  > ${output_dir}/forward-db.sh
sed -i "s;<dspa>;${dspa};g" ${output_dir}/forward-db.sh
sed "s;<namespace>;${namespace};g" templates/forward-minio_template.sh  > ${output_dir}/forward-minio.sh
sed -i "s;<dspa>;${dspa};g" ${output_dir}/forward-minio.sh
sed -i "s;<S3_ENDOINT>;${minio_host_scheme}://${minio_host};g" ${output_dir}/artifact_script.sh
sed -i "s;<S3_BUCKET>;${minio_bucket};g" ${output_dir}/artifact_script.sh
sed -i "s;<kube_config>;${kube_config_path};g" ${output_dir}/persistence-flags.txt

cp ${vars_file} ${output_dir}/vars.env

cat ${vars_file} | yq 'to_entries | map(.key + "=" + .value) | .[]' > ${output_dir}/vars.env

chmod +x ${output_dir}/forward-*.sh

echo
GR='\033[0;32m'
NC='\033[0m'
echo -e "${GR}Fetching a ca.crt file from scheduledworkflow pod path  /var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
pod=$(oc get pod  -l app=minio-$2 --no-headers=true | awk '{print $1}')
oc exec -n $1 $pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > ${output_dir}/ca.crt
oc whoami --show-token > ${output_dir}/token
echo -e "Done, ensure this ca.crt file is added to /var/run/secrets/kubernetes.io/serviceaccount/ca.crt on the local filesystem to dupe apiserver."
echo sudo mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
echo sudo cp ${output_dir}/ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
echo sudo cp ${output_dir}/token /var/run/secrets/kubernetes.io/serviceaccount/token
echo -e ${NC}

echo "Run port-forward-minio, port-forward-db via configuration Run"
