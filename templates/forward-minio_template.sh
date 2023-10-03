#!/usr/bin/env bash

namespace=<namespace>
dspa=<dspa>
MINIO_SERVICE=minio-${dspa}
MINIO_PORT=9000
oc -n $namespace port-forward service/$MINIO_SERVICE $MINIO_PORT