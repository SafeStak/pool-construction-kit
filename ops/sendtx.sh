#!/bin/bash
# Note: Run where the payment addr and skey files reside
# Don't forget to run `source ~/.bashrc` and `export CARDANO_NODE_SOCKET_PATH=~/node/socket/node.socket`
# Usage: ./sendtx.sh {ADDR} {AMOUNT}

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli query utxo --address $(cat payment.addr) --mainnet | sed -n 3p) # Only takes the first entry (3rd line) which works for faucet. TODO parse response to derive multiple txin 
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
rm draft.txraw 2> /dev/null
cardano-cli transaction build-raw --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out addr1v9jg2sctezx6cceczxr4rmahmdwjm7wdnrsv4zp6rj3l8rqc5y74f+10 --tx-out $(cat payment.addr)+1000000 --ttl 0 --fee 0 --out-file draft.txraw
FEE=$(cardano-cli transaction calculate-min-fee \
--tx-body-file draft.txraw \
--tx-in-count 1 \
--tx-out-count 2 \
--witness-count 1 \
--byron-witness-count 0 \
--mainnet \
--protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Building transaction'
echo '========================================================='
CTIP=$(cardano-cli query tip --mainnet | jq -r .slot)
TTL=$(expr $CTIP + 1200)
TXOUT=$(expr $UTXO0V - $FEE - 10) 
# echo "--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out addr1v9jg2sctezx6cceczxr4rmahmdwjm7wdnrsv4zp6rj3l8rqc5y74f+10 --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file sendtx.txraw"
cardano-cli  transaction build-raw \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out addr1v9jg2sctezx6cceczxr4rmahmdwjm7wdnrsv4zp6rj3l8rqc5y74f+10 --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file sendtx.txraw

# SHOULD BE DONE OFFLINE FOR VALUABLE KEYS 
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli transaction sign \
--tx-body-file sendtx.txraw \
--signing-key-file payment.skey \
--mainnet \
--out-file sendtx.txsigned

# SHOULD BE DONE ONLINE
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli transaction submit \
--tx-file sendtx.txsigned \
--cardano-mode \
--mainnet