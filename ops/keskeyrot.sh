#!/bin/bash

echo '========================================================='
echo 'Re-Generating Stake Pool Operational Certificate'
echo '========================================================='
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | egrep -o '[0-9]+' | head -n 1)
SLOTS_PER_KESPERIOD=$(cat ~/node/config/genesis.json | grep slotsPerKESPeriod | egrep -o '[0-9]+')
KESP=$(expr $CTIP / $SLOTS_PER_KESPERIOD)
cardano-cli shelley node issue-op-cert \
--kes-verification-key-file ~/kc/kes.vkey \
--cold-signing-key-file ~/kc/cold.skey \
--operational-certificate-issue-counter ~/kc/cold.counter \
--kes-period $KESP --out-file ~/kc/node.cert

# Don't forget to restart your node after this - sudo systemctl restart cnode-core