#!/usr/bin/env bash
namespace=<namespace>
SERVICE=metadata-grpc-service
PORT=8080
oc -n $namespace port-forward service/$SERVICE $PORT
