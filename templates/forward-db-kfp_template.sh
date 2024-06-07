#!/usr/bin/env bash
namespace=<namespace>
DB_SERVICE=mysql
DB_PORT=3306
oc -n $namespace port-forward service/$DB_SERVICE $DB_PORT
