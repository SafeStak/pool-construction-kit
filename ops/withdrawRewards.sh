#!/bin/bash
# Handy testnet script for withdrawing rewards using file name conventions
# Note: Not recommended for mainnet where key signing needs to be done offline+air-gapped 
# Usage: ./withdrawRewards.sh {PAYMENT_KEY_AND_ADDR_PREFIX} {STAKE_KEY_AND_ADDR_PREFIX}
# Gets rewards from {STAKE_KEY_AND_ADDR_PREFIX}.addr, sends to {PAYMENT_KEY_AND_ADDR_PREFIX}.addr and signs with {STAKE_KEY_AND_ADDR_PREFIX}.skey + {PAYMENT_KEY_AND_ADDR_PREFIX}.skey
# e.g. ./withdrawRewards.sh payment stake -> stake.addr rewards goes to payment.addr using top UTxO from that address and signed with stake.skey and payment.skey

MAGIC=1097911063 # Change for different testnet envs

echo '========================================================='
echo 'Getting latest protocol.json'
echo '========================================================='
cardano-cli query protocol-parameters --testnet-magic $MAGIC --out-file protocol.json 

echo '========================================================='
echo "Querying reward details of staking address $2.addr"
echo '========================================================='
REWARDAMOUNT=$(cardano-cli query stake-address-info --testnet-magic $MAGIC --address $(< $2.addr) | jq .[0].rewardAccountBalance)
echo Rewards: $REWARDAMOUNT

echo '========================================================='
echo "Querying first UTXO of $1.addr"
echo '========================================================='
UTXO0=$(cardano-cli query utxo --address $(< $1.addr) --testnet-magic $MAGIC | sed -n 3p) 
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo UTXO0H: $UTXO0H
echo UTXO0I: $UTXO0I
echo UTXO0V: $UTXO0V

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
rm withdraw_rewards.txraw 2> /dev/null
NEWBAL=$(expr $UTXO0V + $UTXO1V + $REWARDAMOUNT)
cardano-cli transaction build-raw \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $(< $1.addr)+$NEWBAL \
    --withdrawal $(< $2.addr)+$REWARDAMOUNT \
    --ttl 0 \
    --fee 0 \
    --out-file withdraw_rewards.txraw
FEE=$(cardano-cli transaction calculate-min-fee \
    --testnet-magic $MAGIC \
    --tx-body-file withdraw_rewards.txraw  \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 1 \
    --protocol-params-file protocol.json | egrep -o '[0-9]+')
echo Fee: $FEE

echo '========================================================='
echo 'Building transaction'
echo '========================================================='
CTIP=$(cardano-cli query tip --testnet-magic $MAGIC | jq -r .slot)
TTL=$(expr $CTIP + 900) # 15 mins TTL in real world time
NEWBAL=$(expr $UTXO0V + $UTXO1V + $REWARDAMOUNT - $FEE)
echo Current Tip: $CTIP
echo TTL: $TTL
echo New Balance: $NEWBAL
cardano-cli transaction build-raw \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $(< $1.addr)+$NEWBAL \
    --withdrawal $(< $2.addr)+$REWARDAMOUNT \
    --ttl $TTL \
    --fee $FEE \
    --out-file withdraw_rewards.txraw

# This process should be done offline on air-gapped machine with signing keys outside of testnets
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli transaction sign \
    --testnet-magic $MAGIC \
    --tx-body-file withdraw_rewards.txraw  \
    --signing-key-file $1.skey \
    --signing-key-file $2.skey \
    --out-file withdraw_rewards.txsigned

echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli transaction submit \
    --testnet-magic $MAGIC \
    --tx-file withdraw_rewards.txsigned

# Cleanup
rm withdraw_rewards.txraw 2> /dev/null    
rm withdraw_rewards.txsigned 2> /dev/null
