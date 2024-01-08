# Set up Local DSP Dev Env

## Prerequisites
* Have a Dev OCP 4.11+ cluster with cluster admin
* Be logged in to cluster as cluster admin via OC
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management)  
```bash
sudo yum install -y kubectl
```
* yq
```bash
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - |\
  tar xz && mv ${BINARY} /usr/bin/yq
```


### Setup

Setup env
```bash
DEV_SETUP_REPO=dsp-dev-setup
DSP_REPO=data-science-pipelines
DSPO_REPO=data-science-pipelines-operator
DSPA_NS=dspa
OPERATOR_NS=odh-applications
git clone git@github.com:HumairAK/dsp-dev-setup.git ${DEV_SETUP_REPO}
git clone git@github.com:opendatahub-io/data-science-pipelines.git ${DSP_REPO}
git clone git@github.com:opendatahub-io/data-science-pipelines-operator.git ${DSPO_REPO}
```

Deploy a DSPO
```bash
pushd ${DSPO_REPO}
oc new-project ${OPERATOR_NS}
make deploy OPERATOR_NS=${OPERATOR_NS}
popd
```

Deploy DSPA
```bash
pushd ${DSPO_REPO}
oc new-project ${DSPA_NS}
oc -n ${DSPA_NS} apply -f config/samples/dspa_simple.yaml
popd
```

### Locally run each component

Based on the components you want to run locally, the steps are different. For each component, assume a fresh dspo/dsp 
install from _Setup_ instructions above.

#### API Server

Scale down api server: 
```
oc -n ${DSPA_NS} scale --replicas=0 deployment/ds-pipeline-sample
```

```bash
cd ${DEV_SETUP_REPO}
mkdir output
./main.sh dspa sample /home/hukhan/.kube/config output
```
This will generate all the files required to configure API Server deployment.

API Server creats a k8sclient connection using in cluster config, so to emulate this, the above script pulls cluster 
certs, and your OC user token in the `output` folder. Please don't paste the contents of this folder anywhere public for
your own security.

Copy the creds to the following locations on your file system: 
```bash
sudo mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
sudo cp output/ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
sudo cp output/token /var/run/secrets/kubernetes.io/serviceaccount/token

sudo mkdir -p /var/run/secrets/kubeflow/tokens
sudo cp output/token /var/run/secrets/kubeflow/tokens/persistenceagent-sa-token
```
This simulates an in cluster config similar to what API Server sees, when running inside a Pod.

API Server needs to hook into the db and mlmd, we can port forward both services to allow this:
```bash
cd ${DEV_SETUP_REPO}
./output/forward-db.sh
./output/forward-mlmd-grpc.sh
```

Now run API Server
```bash
export $(cat output/vars.env | xargs)

cd ${DSP_REPO}
go build -o bin/apiserver backend/src/apiserver/*.go
./bin/apiserver --config=../${DEV_SETUP_REPO}/output --sampleconfig=../${DEV_SETUP_REPO}/output/sample_config.json -logtostderr=true
```

#### Persistence Agent

To run PA run the following: 

Scale down: 
```bash
oc -n ${DSPA_NS} scale --replicas=0 deployment/ds-pipeline-persistenceagent-sample
```

Export env vars:
```bash
export $(cat output/vars.env | xargs)
```

Build and run:
```
go build -o bin/pa backend/src/agent/persistence/*.go

./bin/pa --kubeconfig=/home/hukhan/.kube/config \
    --master=https://api.hukhan-3.dev.datahub.redhat.com:6443 \
    --mlPipelineAPIServerName=localhost \
    --mlPipelineServiceHttpPort=8888 \
    --mlPipelineServiceGRPCPort=8887 \
    --namespace=${DSPA_NS}
```

# Troubleshooting

### Go Env issues
Configure `go env`
```bash
go env -w GO111MODULE=on
go env -w GOPROXY="https://proxy.golang.org,direct"
```


[DSP]: https://github.com/opendatahub-io/data-science-pipelines
[DSPO]: https://github.com/opendatahub-io/data-science-pipelines-operator
