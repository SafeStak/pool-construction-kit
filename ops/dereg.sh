#!/bin/bash
EPOCH_LEN=$(cat ~/node/config/sgenesis.json | grep epoch | egrep -o '[0-9]+')
CTIP=$(cardano-cli shelley query tip --mainnet | jq -r .slotNo)
DEREG_EPOCH=$(expr $CTIP / $EPOCH_LEN  + 2) # De-register it Two epochs from now - extend if required

echo '========================================================='
echo 'Generating De-registration cert'
echo '========================================================='
cardano-cli shelley stake-pool deregistration-certificate \
--cold-verification-key-file cold.vkey \
--epoch 20 \
--out-file pool.dereg

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli shelley query utxo --address $(cat payment.addr) --mainnet | sed -n 3p) # Only takes the first entry (3rd line) which works for faucet. TODO parse response to derive multiple txin 
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
TTL=$(expr $CTIP + 1000)
rm dummy.txbody 2> /dev/null
cardano-cli shelley transaction build-raw --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+0 --ttl ${TTL} --fee 0 --certificate-file pool.dereg --out-file dummy.txbody
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-body-file dummy.txbody \
--tx-in-count 1 \
--tx-out-count 1 \
--witness-count 1 \
--byron-witness-count 0 \
--mainnet \
--protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Building Stake Pool De-registration Transaction'
echo '========================================================='
TXOUT=$(expr $UTXO0V - $FEE) 
cardano-cli shelley transaction build-raw \
--certificate-file pool.dereg \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file SAFE.dereg.tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli shelley transaction sign \
--tx-body-file SAFE.dereg.tx.raw \
--signing-key-file cold.skey \
--signing-key-file payment.skey \
--mainnet \
--out-file SAFE.dereg.tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli shelley transaction submit \
--tx-file SAFE.dereg.tx.signed \
--cardano-mode \
--mainnet