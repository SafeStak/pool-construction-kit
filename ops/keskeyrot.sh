#!/bin/bash

echo '========================================================='
echo 'Regenerating KES Key pair'
echo '========================================================='
KESCOUNTER=$(printf "%06d" $(cat ~/kc/cold.counter | jq -r .description | egrep -o '[0-9]+'))
cardano-cli shelley node key-gen-KES \
--verification-key-file kes-$KESCOUNTER.vkey \
--signing-key-file kes-$KESCOUNTER.skey

echo '========================================================='
echo 'Re-Generating Stake Pool Operational Certificate'
echo '========================================================='
SLOTS_PER_KESPERIOD=$(cat ~/node/config/sgenesis.json | jq -r .slotsPerKESPeriod)
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | jq -r .slotNo)
KESP=$(expr $CTIP / $SLOTS_PER_KESPERIOD)
cardano-cli shelley node issue-op-cert \
--kes-verification-key-file ~/kc/kes.vkey \
--cold-signing-key-file ~/kc/cold.skey \
--operational-certificate-issue-counter ~/kc/cold.counter \
--kes-period $KESP --out-file ~/kc/node.cert

cp kes-$KESCOUNTER.skey kes.skey

echo $(date --iso-8601=seconds) $KESCOUNTER >> ~/kc/keskeyop.log

# scp -i ssh.pem /home/YOURLOCALNAME/kc/SAFE/kes.skey ss@YOURIP:/home/YOURREMOTENAME/kc/ 

# Don't forget to restart your node on your remote server after this, e.g. sudo systemctl restart cnode-core