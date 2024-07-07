#!/usr/bin/env bash
namespace=<namespace>
dspa=<dspa>
DB_SERVICE=minio-service
DB_PORT=9000
oc -n $namespace port-forward service/$DB_SERVICE $DB_PORT
