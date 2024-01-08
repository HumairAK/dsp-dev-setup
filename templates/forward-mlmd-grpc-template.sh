#!/usr/bin/env bash
namespace=<namespace>
dspa=<dspa>
SERVICE=ds-pipeline-metadata-grpc-${dspa}
PORT=8080
oc -n $namespace port-forward service/$SERVICE $PORT
