#!/usr/bin/env bash
namespace=<namespace>
dspa=<dspa>
SERVICE=ds-pipeline-${dspa}
GRPC_PORT=8887
oc -n $namespace port-forward service/$SERVICE $GRPC_PORT
