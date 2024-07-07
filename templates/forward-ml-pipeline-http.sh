#!/usr/bin/env bash
namespace=<namespace>
dspa=<dspa>
SERVICE=ds-pipeline-${dspa}
HTTP_PORT=8888
oc -n $namespace port-forward service/$SERVICE $HTTP_PORT
