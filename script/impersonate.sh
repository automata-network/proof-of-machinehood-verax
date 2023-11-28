#!/bin/bash

source .env

echo "Begin impersonation..."

ADDR=$(cast wallet address $PRIVATE_KEY)
PORTAL_REGISTRY_OWNER=$(cast call $PORTAL_REGISTRY_ADDRESS "owner()(address)" --rpc-url $RPC_URL)

cast rpc anvil_impersonateAccount $PORTAL_REGISTRY_OWNER

cast send $PORTAL_REGISTRY_ADDRESS "setIssuer(address)" $ADDR --unlocked --from $PORTAL_REGISTRY_OWNER --rpc-url $RPC_URL

echo "Impersonation completed..."