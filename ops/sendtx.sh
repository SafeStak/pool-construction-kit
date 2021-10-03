#!/bin/bash
# Usage: ./sendtx.sh {ADDR} {AMOUNT} {PAYER}
# Looks for {PAYER}.addr and {PAYER}.skey

echo '========================================================='
echo "Sending $2 from $3.addr to $1 signed by $3.skey"
echo '========================================================='

echo '========================================================='
echo 'Getting latest protocol.json'
echo '========================================================='
cardano-cli query protocol-parameters --mainnet --out-file protocol.json 

echo '========================================================='
echo "Querying utxo details of $3.addr"
echo '========================================================='​
UTXO0=$(cardano-cli query utxo --address $(cat $3.addr) --testnet-magic $MAGIC | sed -n 3p) # Only takes the first entry (3rd line) which works for faucet UTxOs 
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
rm draft.txraw 2> /dev/null
CHANGE=$(expr $UTXO0V - $2)
cardano-cli transaction build-raw \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $1+$2 \
    --tx-out $(cat payment.addr)+$CHANGE \
    --ttl 0 \
    --fee 0 \
    --out-file draft.txraw
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file draft.txraw \
    --tx-in-count 1 \
    --tx-out-count 2 \
    --witness-count 1 \
    --mainnet \
    --protocol-params-file protocol.json | egrep -o '[0-9]+')
echo Fee: $FEE

echo '========================================================='
echo 'Building transaction'
echo '========================================================='
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot)
TTL=$(expr $CTIP + 900)
CHANGE=$(expr $UTXO0V - $FEE - $2) 
# echo "--tx-in $UTXO0H#$UTXO0I --tx-out $1+$2 --tx-out $(cat $3.addr)+$CHANGE --ttl $TTL --fee $FEE --out-file sendtx.txraw"
cardano-cli  transaction build-raw \
    --tx-in $UTXO0H#$UTXO0I \
    --tx-out $1+$2 \
    --tx-out $(cat payment.addr)+$CHANGE \
    --ttl $TTL \
    --fee $FEE \
    --out-file sendtx.txraw

# # SHOULD BE DONE OFFLINE FOR VALUABLE KEYS 
# echo '========================================================='
# echo 'Signing transaction'
# echo '========================================================='
# cardano-cli transaction sign \
#     --tx-body-file sendtx.txraw \
#     --signing-key-file $3.skey \
#     --mainnet \
#     --out-file sendtx.txsigned

# # SHOULD BE DONE ONLINE
# echo '========================================================='
# echo 'Submitting transaction'
# echo '========================================================='
# cardano-cli transaction submit \
#     --tx-file sendtx.txsigned \
#     --cardano-mode \
#     --mainnet