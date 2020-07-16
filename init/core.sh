#!/bin/bash
# Note: One-off execution only! Do not run more than once even in case of failures
# Don't forget to run `source ~/.bashrc` when running for the first time!`

echo '========================================================='
echo 'Generating Core Keys and Addresses'
echo '========================================================='
cd $HOME
mkdir -p kc
cd kc
cardano-cli shelley address key-gen --verification-key-file payment.vkey --signing-key-file payment.skey
cardano-cli shelley stake-address key-gen --verification-key-file stake.vkey --signing-key-file stake.skey
cardano-cli shelley address build \
 --payment-verification-key-file payment.vkey \
 --stake-verification-key-file stake.vkey \
 --mainnet \
 --out-file payment.addr
cardano-cli shelley stake-address build \
 --stake-verification-key-file stake.vkey \
 --mainnet \
 --out-file stake.addr

echo '========================================================='
echo 'Generating Protocol Parameters'
echo '========================================================='
cardano-cli shelley query protocol-parameters --testnet-magic 42 --cardano-mode --out-file protocol.json 

echo '========================================================='
echo 'Generating Staking Registration Certificate'
echo '========================================================='
cardano-cli shelley stake-address registration-certificate --stake-verification-key-file stake.vkey --out-file stake.cert

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli shelley query utxo --address $(cat payment.addr) --testnet-magic 42 --cardano-mode | tail -n 1)
UTXO0H=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 1p)
UTXO0I=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 2p)
UTXO0V=$(echo $UTXO0 | egrep -o '[a-z0-9]+' | sed -n 3p)
echo $UTXO0

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | jq -r .slotNo)
TTL=$(expr $CTIP + 1000)
rm dummy.txbody 2> /dev/null
cardano-cli shelley transaction build-raw --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+0 --ttl ${TTL} --fee 0 --certificate stake.cert --out-file dummy.txbody
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-body-file dummy.txbody \
--tx-in-count 1 \
--tx-out-count 1 \
--witness-count 2 \
--byron-witness-count 0 \
--testnet-magic 42 \
--protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Generating transaction for Stake Pool Registration Key Deposit'
echo '========================================================='
KEY_DEPOSIT=$(cat protocol.json | grep keyDeposit | egrep -o '[0-9]+')
TXOUT=$(expr $UTXO0V - $FEE - $KEY_DEPOSIT) # KEY_DEPOSIT=400000 at time of writing 
cardano-cli shelley transaction build-raw \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --certificate-file stake.cert --out-file tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli shelley transaction sign \
--tx-body-file tx.raw \
--signing-key-file payment.skey \
--signing-key-file stake.skey \
--testnet-magic 42 \
--out-file tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli shelley transaction submit \
--tx-file tx.signed \
--testnet-magic 42 \
--cardano-mode

echo '========================================================='
echo 'Generating Cold Keys and a Cold Counter'
echo '========================================================='
cardano-cli shelley node key-gen \
--cold-verification-key-file cold.vkey \
--cold-signing-key-file cold.skey \
--operational-certificate-issue-counter-file cold.counter

echo '========================================================='
echo 'Generating VRF Key pair'
echo '========================================================='
cardano-cli shelley node key-gen-VRF \
--verification-key-file vrf.vkey \
--signing-key-file vrf.skey

echo '========================================================='
echo 'Generating KES Key pair'
echo '========================================================='
KESCOUNTER=$(printf "%06d" $(cat ~/kc/cold.counter | jq -r .description | egrep -o '[0-9]+'))
cardano-cli shelley node key-gen-KES \
--verification-key-file kes-$KESCOUNTER.vkey \
--signing-key-file kes-$KESCOUNTER.skey

echo '========================================================='
echo 'Generating Stake Pool Delegation Certificate (Pledge)'
echo '========================================================='
cardano-cli shelley stake-address delegation-certificate \
--stake-verification-key-file stake.vkey \
--cold-verification-key-file cold.vkey \
--out-file delegation.cert

echo '========================================================='
echo 'Generating Stake Pool Operational Certificate'
echo '========================================================='
SLOTS_PER_KESPERIOD=$(cat ~/node/config/sgenesis.json | jq -r .slotsPerKESPeriod)
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | jq -r .slotNo)
KESP=$(expr $CTIP / $SLOTS_PER_KESPERIOD) # SLOTS_PER_KESPERIOD=3600 at time of writing  
cardano-cli shelley node issue-op-cert \
--hot-kes-verification-key-file kes-$KESCOUNTER.vkey \
--cold-signing-key-file cold.skey \
--operational-certificate-issue-counter cold.counter \
--kes-period $KESP --out-file node.cert
cp kes-$KESCOUNTER.skey kes.skey
echo $(date --iso-8601=seconds) $KESCOUNTER >> ~/kc/keskeyop.log

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli shelley query utxo --address $(cat payment.addr) --testnet-magic 42 --cardano-mode | tail -n 1)
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
wget https://www.safestak.com/SAFE.json # Should be your JSON file
METAHASH=$(cardano-cli shelley stake-pool metadata-hash --pool-metadata-file SAFE.json)

echo '========================================================='
echo 'Generating transaction for Stake Pool Operation Certificate Pool Deposit'
echo '========================================================='
PLEDGE=500000000000 # 0.5M ADA
cardano-cli shelley stake-pool registration-certificate \
--cold-verification-key-file cold.vkey \
--vrf-verification-key-file vrf.vkey \
--pool-pledge $PLEDGE --pool-cost 228000000 --pool-margin 0.046 \
--pool-reward-account-verification-key-file stake.vkey \
--pool-owner-stake-verification-key-file stake.vkey \
--single-host-pool-relay r0.eun.mnc.safestak.com \
--pool-relay-port 3001 \
--single-host-pool-relay r1.eun.mnc.safestak.com \
--pool-relay-port 3001 \
--metadata-url https://www.safestak.com/SAFE.json \
--metadata-hash $(echo $METAHASH) \
--testnet-magic 42 \
--out-file pool.cert

echo '========================================================='
echo 'Calculating minimum fee'
echo '========================================================='
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | jq -r .slotNo)
TTL=$(expr $CTIP + 1000)
rm dummy.txbody 2> /dev/null
cardano-cli shelley transaction build-raw --tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+0 --ttl ${TTL} --fee 0 --certificate-file pool.cert --certificate-file delegation.cert --out-file dummy.txbody
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-body-file dummy.txbody \
--tx-in-count 1 \
--tx-out-count 1 \
--witness-count 2 \
--byron-witness-count 0 \
--testnet-magic 42 \
--protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Building Stake Pool Delegation Key transaction'
echo '========================================================='
POOL_DEPOSIT=$(cat protocol.json | jq -r .poolDeposit)
TXOUT=$(expr $UTXO0V - $FEE - $POOL_DEPOSIT) 
cardano-cli shelley transaction build-raw \
--certificate-file pool.cert \
--certificate-file delegation.cert \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file SAFE.tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli shelley transaction sign \
--tx-body-file SAFE.tx.raw \
--signing-key-file cold.skey \
--signing-key-file payment.skey \
--signing-key-file stake.skey \
--testnet-magic 42 \
--out-file SAFE.tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli shelley transaction submit \
--tx-file SAFE.tx.signed \
--cardano-mode \
--testnet-magic 42
echo '========================================================='
echo 'Verify pool creation'
echo '========================================================='
cardano-cli shelley stake-pool id --verification-key-file cold.vkey
