# Set up Local DSP Dev Env

## Prerequisites
* Have a Dev OCP 4.10+ cluster with cluster admin
* Install OpenShift Pipelines 1.9 on this cluster from OLM
* Be logged in to cluster as cluster admin via OC

### Setup

Deploy a DSPO and DSPA

```bash
git clone git@github.com:HumairAK/dsp-dev-setup.git
git clone git@github.com:opendatahub-io/data-science-pipelines.git
git clone git@github.com:opendatahub-io/data-science-pipelines-operator.git
pushd data-science-pipelines-operator
make deploy
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
pushd dsp-dev-setup
./main.sh
popd
```

In a new terminal run: 
```

```






[DSP]: https://github.com/opendatahub-io/data-science-pipelines
[DSPO]: https://github.com/opendatahub-io/data-science-pipelines-operator