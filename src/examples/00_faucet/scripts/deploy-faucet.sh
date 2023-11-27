#!/bin/bash

root="../../.."

cd $root

source .env

forge script DeployFaucetScript --broadcast --rpc-url ${RPC_URL} | grep LOG