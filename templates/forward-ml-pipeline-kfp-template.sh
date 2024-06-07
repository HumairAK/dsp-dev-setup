#!/usr/bin/env bash
namespace=<namespace>
SERVICE=ml-pipeline
GRPC_PORT=8887
oc -n $namespace port-forward service/$SERVICE $GRPC_PORT
