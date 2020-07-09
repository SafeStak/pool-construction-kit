#!/bin/bash
# Note: One-off execution only! Do not run more than once even in case of failures
# Don't forget to run `source ~/.bashrc` and `export CARDANO_NODE_SOCKET_PATH=~/node/socket/node.socket`

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli shelley query utxo --address $(cat ~/kc/payment.addr) --testnet-magic 42 | sed -n 3p) # Only takes the first entry (3rd line) which works for faucet. TODO parse response to derive multiple txin 
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

echo '========================================================='
echo 'Querying the tip of the blockchain'
echo '========================================================='
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | egrep -o '[0-9]+' | head -n 1)

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
TTL=$(expr $CTIP + 1200)
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-in-count 1 \
--tx-out-count 2 \
--ttl $TTL --testnet-magic 42 \
--signing-key-file ~/kc/payment.skey \
--protocol-params-file protocol.json | egrep -o '[0-9]+')
echo '========================================================='
echo 'Building transaction'
echo '========================================================='
TXOUT=$(expr $UTXO0V - $FEE - $2) 
# echo "params are --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(echo $1)+$(echo $2) --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file tx.raw"
cardano-cli shelley transaction build-raw \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(echo $1)+$(echo $2) --tx-out $(cat ~/kc/payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli shelley transaction sign \
--tx-body-file tx.raw \
--signing-key-file ~/kc/payment.skey \
--testnet-magic 42 \
--out-file tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli shelley transaction submit \
--tx-file tx.signed \
--testnet-magic 42