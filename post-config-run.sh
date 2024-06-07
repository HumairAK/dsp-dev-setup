#!/usr/bin/env bash

set -e
output_dir=$1
namespace=$2
read -p "This script will copy files to /var/run/secrets/kubernetes.io/* and /var/run/secrets/kubeflow, this requires sudo access, are you sure you want to continue? (y/n)" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

set -x
sudo mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
sudo cp $output_dir/ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
sudo cp $output_dir/token /var/run/secrets/kubernetes.io/serviceaccount/token
sudo mkdir -p /var/run/secrets/$2/tokens
sudo cp $output_dir/token /var/run/secrets/$2/tokens/persistenceagent-sa-token
sudo cp $output_dir/namespace /var/run/secrets/kubernetes.io/serviceaccount/namespace

sudo mkdir -p /var/run/secrets/kubeflow/tokens
sudo cp $output_dir/token /var/run/secrets/kubeflow/tokens/persistenceagent-sa-token
