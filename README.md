# Set up Local DSP Dev Env

## Prerequisites
* Have a Dev OCP 4.10+ cluster with cluster admin
* Install OpenShift Pipelines 1.9 on this cluster from OLM
* Be logged in to cluster as cluster admin via OC

### Setup

Clone relevant Git repos
```bash
WORKING_DIR=${REPLACE_THIS}
git clone git@github.com:HumairAK/dsp-dev-setup.git ${WORKING_DIR}/dsp-dev-setup
git clone git@github.com:opendatahub-io/data-science-pipelines.git ${WORKING_DIR}/data-science-pipelines
git clone git@github.com:opendatahub-io/data-science-pipelines-operator.git ${WORKING_DIR}/data-science-pipelines-operator
```

Deploy a DSPO
```bash
cd ${WORKING_DIR}/data-science-pipelines-operator
make deploy
```

Deploy DSPA
```bash
cd ${WORKING_DIR}/data-science-pipelines
oc new-project dspa
oc -n dspa apply -f config/samples/dspa_simple.yaml
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
cd ${WORKING_DIR}/dsp-dev-setup
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
cd ${WORKING_DIR}/dsp-dev-setup
./output/forward-minio.sh

# Terminal 2
cd ${WORKING_DIR}/dsp-dev-setup
./output/forward-db.sh
```

Now run API Server



[DSP]: https://github.com/opendatahub-io/data-science-pipelines
[DSPO]: https://github.com/opendatahub-io/data-science-pipelines-operator