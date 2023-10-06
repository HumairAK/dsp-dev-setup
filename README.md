# Set up Local DSP Dev Env

## Prerequisites
* Have a Dev OCP 4.11+ cluster with cluster admin
* Install OpenShift Pipelines 1.9+ on this cluster from OLM
* Be logged in to cluster as cluster admin via OC
* kubectl -> [sudo yum install -y kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management)
* yq -> `wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - |\
  tar xz && mv ${BINARY} /usr/bin/yq`

### Setup

Clone relevant Git repos
```bash
DEV_SETUP_REPO=dsp-dev-setup
DSP_REPO=data-science-pipelines
DSPO_REPO=data-science-pipelines-operator
git clone git@github.com:HumairAK/dsp-dev-setup.git ${DEV_SETUP_REPO}
git clone git@github.com:opendatahub-io/data-science-pipelines.git ${DSP_REPO}
git clone git@github.com:opendatahub-io/data-science-pipelines-operator.git ${DSPO_REPO}
```

Configure `go env`
```bash
go env -w GO111MODULE=on
go env -w GOPROXY="https://proxy.golang.org,direct"
```

Deploy a DSPO
```bash
pushd ${DSPO_REPO}
oc new-project odh-applications
make deploy
popd
```

Deploy DSPA
```bash
pushd ${DSPO_REPO}
oc new-project dspa
oc -n dspa apply -f config/samples/dspa_simple.yaml
popd
```

### Locally run each component

Based on the components you want to run locally, the steps are different. For each component, assume a fresh dspo/dsp 
install from _Setup_ instructions above.

#### API Server

Scale down api server: 
```
oc scale --replicas=0 deployment/ds-pipeline-sample
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
```
This simulates an in cluster config similar to what API Server sees, when running inside a Pod.

API Server needs to hook into a db/s3, we can port forward minio/mariadb for this.

Open 2 separate 2 terminals, and in each run the following:

```bash
# Terminal 1
cd ${DEV_SETUP_REPO}
./output/forward-minio.sh

# Terminal 2
cd ${DEV_SETUP_REPO}
./output/forward-db.sh
```

Now run API Server
```bash
cd ${DEV_SETUP_REPO}

export ARTIFACT_SCRIPT=$(cat output/artifact_script.sh)
export $(cat output/vars.env | xargs)

cd ${DSP_REPO}
go build -o bin/apiserver backend/src/apiserver/*.go
./bin/apiserver --config=${DEV_SETUP_REPO}/output --sampleconfig=${DEV_SETUP_REPO}/output/sample_config.json -logtostderr=true
```

The `ARTIFACT_SCRIPT` is a bit tricky, as it has to store the entire artifact script, but because it's concatenated into one line, it may not work due to whitespacing issues. 
This means pipelines passing artifacts into s3 may not work properly, we'd need to figure out how to properly export the script as an env var (like we do in the server pods).


[DSP]: https://github.com/opendatahub-io/data-science-pipelines
[DSPO]: https://github.com/opendatahub-io/data-science-pipelines-operator
