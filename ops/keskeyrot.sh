#!/bin/bash

echo '========================================================='
echo 'Regenerating KES Key pair'
echo '========================================================='
KESCOUNTER=$(printf "%06d" $(cat cold.counter | jq -r .description | egrep -o '[0-9]+'))
cardano-cli node key-gen-KES \
    --verification-key-file kes-$KESCOUNTER.vkey \
    --signing-key-file kes-$KESCOUNTER.skey

echo '========================================================='
echo 'Re-Generating Stake Pool Operational Certificate'
echo '========================================================='
# Following 3 commands has to run separately on a hot node TODO: Use https://github.com/gitmachtl/scripts/blob/master/cardano/mainnet-release-candidate/0x_showCurrentEpochKES.sh for offline
SLOTS_PER_KESPERIOD=$(cat ~/node/config/sgenesis.json | jq -r .slotsPerKESPeriod)
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot) 
KESP=$(expr $CTIP / $SLOTS_PER_KESPERIOD)
cardano-cli node issue-op-cert \
    --kes-verification-key-file kes-$KESCOUNTER.vkey \
    --cold-signing-key-file cold.skey \
    --operational-certificate-issue-counter cold.counter \
    --kes-period $KESP \
    --out-file node.cert

cp kes-$KESCOUNTER.skey kes.skey

echo $(date --iso-8601=seconds) $KESCOUNTER >> keskeyop.log

# scp -i ssh.pem /home/YOURLOCALNAME/PATH/kes.skey /home/YOURLOCALNAME/PATH/node.cert YOURREMOTENAME@YOURIP:/home/YOURREMOTENAME/kc/ # See wfly

# Don't forget to chmod 400 your kes.skey and node.cert files after scp transfer and restart your node on your remote server after this, e.g. sudo systemctl restart cnode-core