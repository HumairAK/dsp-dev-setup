#!/usr/bin/env bash
namespace=<namespace>
dspa=<dspa>
SERVICE=ds-pipeline-md-${dspa}
PORT=9090
oc -n $namespace port-forward service/$SERVICE $PORT
