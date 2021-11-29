#!/bin/bash
# Note: Only useful as a step by step guide - DO NOT RUN in its entirety
# For Mainnet GENERATE AND STORE KEYS OFFLINE IN AN AIRTIGHT COLD ENVIRONMENT
echo '========================================================='
echo 'Generating Core Keys and Addresses'
echo '========================================================='
mkdir -p ~/node/kc
cd ~/node/kc
cardano-cli address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey
chmod 400 payment.skey payment.vkey

cardano-cli stake-address key-gen \
    --verification-key-file stake.vkey \
    --signing-key-file stake.skey
chmod 400 stake.skey stake.vkey

cardano-cli address build \
    --payment-verification-key-file payment.vkey \
    --mainnet \
    --out-file payment.addr
chmod 400 payment.addr

cardano-cli stake-address build \
    --stake-verification-key-file stake.vkey \
    --mainnet \
    --out-file stake.addr
chmod 400 stake.addr

echo '========================================================='
echo 'Generating Protocol Parameters'
echo '========================================================='
cardano-cli query protocol-parameters \
    --mainnet --out-file protocol.json

echo '========================================================='
echo 'Generating Staking Registration Certificate'
echo '========================================================='
cardano-cli stake-address registration-certificate \
    --stake-verification-key-file stake.vkey --out-file stake.cert
chmod 400 stake.cert

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli query utxo --address $(cat payment.addr) --mainnet | tail -n 1)
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

echo '========================================================='
echo 'Calculating minimum fee for stake registration'
echo '========================================================='
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot)
TTL=$(expr $CTIP + 600)
rm stakereg.draft.txraw 2> /dev/null
cardano-cli transaction build-raw \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $(cat payment.addr)+0 \
    --ttl $TTL \
    --fee 0 \
    --certificate stake.cert \
    --out-file stakereg.draft.txraw
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file stakereg.draft.txraw \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 2 \
    --mainnet \
    --protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Generating transaction for Staking Key Deposit'
echo '========================================================='
STAKE_DEPOSIT=$(cat protocol.json | grep stakeAddressDeposit | egrep -o '[0-9]+')
TXOUT=$(expr $UTXO0V - $FEE - $STAKE_DEPOSIT) # STAKE_DEPOSIT=2000000 at time of writing 
cardano-cli transaction build-raw \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $(cat payment.addr)+$TXOUT \
    --ttl $TTL \
    --fee $FEE \
    --certificate-file stake.cert \
    --out-file stakereg.txraw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli transaction sign \
    --tx-body-file stakereg.txraw \
    --signing-key-file payment.skey \
    --signing-key-file stake.skey \
    --mainnet \
    --out-file stakereg.txsigned
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli transaction submit \
    --tx-file stakereg.txsigned \
    --mainnet \

echo '========================================================='
echo 'Generating Cold Keys and a Cold Counter'
echo '========================================================='
    cardano-cli node key-gen \
    --cold-verification-key-file cold.vkey \
    --cold-signing-key-file cold.skey \
    --operational-certificate-issue-counter-file cold.counter
chmod 400 cold.skey

echo '========================================================='
echo 'Generating VRF Key pair'
echo '========================================================='
cardano-cli node key-gen-VRF \
    --verification-key-file vrf.vkey \
    --signing-key-file vrf.skey

echo '========================================================='
echo 'Generating KES Key pair'
echo '========================================================='
KESCOUNTER=$(printf "%06d" $(cat cold.counter | jq -r .description | egrep -o '[0-9]+'))
cardano-cli node key-gen-KES \
    --verification-key-file kes-$KESCOUNTER.vkey \
    --signing-key-file kes-$KESCOUNTER.skey

echo '========================================================='
echo 'Generating Stake Pool Delegation Certificate (Pledge)'
echo '========================================================='
cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file stake.vkey \
    --cold-verification-key-file cold.vkey \
    --out-file delegation.cert

echo '========================================================='
echo 'Generating Stake Pool Operational Certificate'
echo '========================================================='
SLOTS_PER_KESPERIOD=$(cat ~/node/config/sgenesis.json | jq -r .slotsPerKESPeriod)
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot)
KESP=$(expr $CTIP / $SLOTS_PER_KESPERIOD) # SLOTS_PER_KESPERIOD=3600 at time of writing  
cardano-cli node issue-op-cert \
    --hot-kes-verification-key-file kes-$KESCOUNTER.vkey \
    --cold-signing-key-file cold.skey \
    --operational-certificate-issue-counter cold.counter \
    --kes-period $KESP --out-file node.cert
cp kes-$KESCOUNTER.skey kes.skey
echo $(date --iso-8601=seconds) $KESCOUNTER >> keskeyop.log

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli query utxo --address $(cat payment.addr) --mainnet | tail -n 1)
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

###############################################################
# NOTE: edit the parameters below based on what is required
#
###############################################################
echo '========================================================='
echo 'Generating Stake Pool Metadata'
echo '========================================================='
wget https://www.safestak.com/SAFE.json 
METAHASH=$(cardano-cli stake-pool metadata-hash --pool-metadata-file SAFE.json)

echo '========================================================='
echo 'Generating transaction for Stake Pool Operation Certificate Pool Deposit'
echo '========================================================='
PLEDGE=550000000000 # 550K ADA
cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file cold.vkey \
    --vrf-verification-key-file vrf.vkey \
    --pool-pledge $PLEDGE --pool-cost 340000000 --pool-margin 0.028 \
    --pool-reward-account-verification-key-file stake.vkey \
    --pool-owner-stake-verification-key-file stake.vkey \
    --single-host-pool-relay r0.eun.live.safestak.com \
    --pool-relay-port 3001 \
    --single-host-pool-relay r1.eun.live.safestak.com \
    --pool-relay-port 3001 \
    --metadata-url https://www.safestak.com/SAFE.json \
    --metadata-hash $METAHASH) \
    --mainnet \
    --out-file pool.cert

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot)
TTL=$(expr $CTIP + 1200)
rm dummy.txbody 2> /dev/null
cardano-cli transaction build-raw \
    --certificate-file pool.cert \
    --certificate-file delegation.cert \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $(cat payment.addr)+0 \
    --ttl ${TTL} \
    --fee 0 \
    --out-file dummy.txbody
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file dummy.txbody \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 2 \
    --mainnet \
    --protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Building Stake Pool Delegation Key transaction'
echo '========================================================='
POOL_DEPOSIT=$(cat protocol.json | jq -r .stakePoolDeposit)
TXOUT=$(expr $UTXO0V - $FEE - $POOL_DEPOSIT) 
cardano-cli transaction build-raw \
    --certificate-file pool.cert \
    --certificate-file delegation.cert \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $(cat payment.addr)+$TXOUT \
    --ttl $TTL \
    --fee $FEE \
    --out-file SAFE.tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli transaction sign \
    --tx-body-file SAFE.tx.raw \
    --signing-key-file cold.skey \
    --signing-key-file payment.skey \
    --signing-key-file stake.skey \
    --mainnet \
    --out-file SAFE.tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli transaction submit \
    --tx-file SAFE.tx.signed \
    --mainnet

echo '========================================================='
echo 'Verify pool creation'
echo '========================================================='
cardano-cli stake-pool id --cold-verification-key-file cold.vkey
