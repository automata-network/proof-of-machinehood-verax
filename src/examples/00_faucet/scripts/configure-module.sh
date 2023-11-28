#!/bin/bash

root="../../.."

cd $root

source .env

forge script MachinehoodModuleConfigurationScript --broadcast --rpc-url ${RPC_URL}