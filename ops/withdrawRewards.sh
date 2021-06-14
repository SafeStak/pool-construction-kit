#!/bin/bash
# Note: Run where the payment addr and skey files reside
# Don't forget to run `source ~/.bashrc` and `export CARDANO_NODE_SOCKET_PATH=~/node/socket/node.socket`

echo '========================================================='
echo 'Querying reward details of stake.addr'
echo '========================================================='
REWARDAMOUNT=$(cardano-cli query stake-address-info --mainnet --address $(cat stake.addr) | jq .[0].rewardAccountBalance)
echo Rewards $REWARDAMOUNT

echo '========================================================='
echo 'Querying payment address and calculating new balance'
echo '========================================================='
UTXO0=$(cardano-cli query utxo --address $(cat payment.addr) --mainnet | sed -n 3p) # Only takes the first entry (3rd line) which works for faucet. TODO parse response to derive multiple txin 
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo UTXO0H $UTXO0H
echo UTXO0I $UTXO0I
echo UTXO0V $UTXO0V

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
rm withdraw_rewards.txraw 2> /dev/null
NEWBAL=$(expr $UTXO0V + $REWARDAMOUNT)
cardano-cli transaction build-raw --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+$NEWBAL --withdrawal $(cat stake.addr)+$REWARDAMOUNT \
--ttl 0 \
--fee 0 \
--out-file withdraw_rewards.txraw
FEE=$(cardano-cli transaction calculate-min-fee \
--mainnet \
--tx-body-file withdraw_rewards.txraw  \
--tx-in-count 1 \
--tx-out-count 1 \
--witness-count 1 \
--byron-witness-count 0 \
--protocol-params-file protocol.json | egrep -o '[0-9]+')
echo Fee $FEE

echo '========================================================='
echo 'Building transaction'
echo '========================================================='
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot)
TTL=$(expr $CTIP + 1200)
NEWBAL=$(expr $UTXO0V + $REWARDAMOUNT - $FEE)
echo Current Tip $CTIP
echo TTL $TTL
echo NEWBAL $NEWBAL
cardano-cli  transaction build-raw \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+$NEWBAL --withdrawal $(cat stake.addr)+$REWARDAMOUNT --ttl $TTL --fee $FEE --out-file withdraw_rewards.txraw

# SHOULD BE DONE OFFLINE 
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli transaction sign \
--mainnet \
--tx-body-file withdraw_rewards.txraw  \
--signing-key-file payment.skey \
--signing-key-file stake.skey \
--out-file withdraw_rewards.txsigned

# SHOULD BE DONE ONLINE
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli transaction submit \
--mainnet \
--tx-file withdraw_rewards.txsigned