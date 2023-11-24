#!/bin/bash

root="../../.."
path="$root/lib/machinehood-contracts"
pom_path="$path/script/script.sh"

source .env
source $pom_path

cd $path

# Foundry only reads .env from the project directory
env_content=$'PRIVATE_KEY='"$PRIVATE_KEY"$'\nSIG_VERIFY_LIB='"$SIG_VERIFY_LIB"$'\nDER_PARSER='"$DER_PARSER"
echo -e "$env_content" > .env

echo "Deploying POM..."
deploy 
echo "Device Attestation POM On-Chain Verification contracts have been deployed successfully."