#!/bin/bash

root="../../.."
path="$root/lib/proof-of-machinehood-contracts"
lib_path="$path/script/deployment/script.sh"

source $root/.env
source $lib_path

cd $path

# Foundry only reads .env from the project directory
env_content="PRIVATE_KEY=$PRIVATE_KEY"
echo $env_content > .env

echo "Deploying the libraries..."
deploy
echo "Please update .env file before deploying POM."