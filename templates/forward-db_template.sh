#!/usr/bin/env bash
namespace=<namespace>
dspa=<dspa>
DB_SERVICE=mariadb-${dspa}
DB_PORT=3306
oc -n $namespace port-forward service/$DB_SERVICE $DB_PORT
