#!/bin/bash
EPOCH_LEN=$(cat ~/node/config/genesis.json | grep epoch | egrep -o '[0-9]+')
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | jq -r .slotNo)
DEREG_EPOCH=$(expr $CTIP / $EPOCH_LEN  + 2) # De-register it Two epochs from now - extend if required

echo '========================================================='
echo 'Generating De-registration cert'
echo '========================================================='
cardano-cli shelley stake-pool deregistration-certificate \
--cold-verification-key-file cold.vkey \
--epoch $DEREG_EPOCH \
--out-file pool.dereg

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
TTL=$(expr $CTIP + 1000)
rm dummy.txbody 2> /dev/null
cardano-cli shelley transaction build-raw --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat paymentstn.addr)+0 --ttl ${TTL} --fee 0 --certificate-file pool.dereg --out-file dummy.txbody
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-body-file dummy.txbody \
--tx-in-count 1 \
--tx-out-count 1 \
--witness-count 1 \
--byron-witness-count 0 \
--testnet-magic 42 \
--protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Building Stake Pool De-registration Transaction'
echo '========================================================='
TXOUT=$(expr $UTXO0V - $FEE) 
cardano-cli shelley transaction build-raw \
--certificate-file pool.dereg \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat paymentstn.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file SAFE.dereg.tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli shelley transaction sign \
--tx-body-file SAFE.dereg.tx.raw \
--signing-key-file cold.skey \
--signing-key-file payment.skey \
--testnet-magic 42 \
--out-file SAFE.dereg.tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli shelley transaction submit \
--tx-file SAFE.dereg.tx.signed \
--shelley-mode \
--testnet-magic 42