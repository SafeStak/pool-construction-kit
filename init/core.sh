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
 --testnet-magic 42 \
 --out-file payment.addr
cardano-cli shelley stake-address build \
 --stake-verification-key-file stake.vkey \
 --testnet-magic 42 \
 --out-file stake.addr

echo '========================================================='
echo 'Getting some loot from the faucet'
echo '========================================================='
curl -v -XPOST "https://faucet.shelley-testnet.dev.cardano.org/send-money/$(cat ~/kc/payment.addr)"

echo '========================================================='
echo 'Generating Protocol Parameters'
echo '========================================================='
cardano-cli shelley query protocol-parameters --testnet-magic 42 --out-file protocol.json

echo '========================================================='
echo 'Generating Stake Pool Registration Certificate'
echo '========================================================='
cardano-cli shelley stake-address registration-certificate --stake-verification-key-file stake.vkey --out-file stake.cert

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli shelley query utxo --address $(cat payment.addr) --testnet-magic 42 | tail -n 1)
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
TTL=$(expr $CTIP + 400)
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-in-count 1 \
--tx-out-count 1 \
--ttl $TTL --testnet-magic 42 \
--signing-key-file payment.skey \
--signing-key-file stake.skey \
--certificate-file stake.cert \
--protocol-params-file protocol.json | egrep -o '[0-9]+')
echo '========================================================='
echo 'Generating transaction for Stake Pool Registration Key Deposit'
echo '========================================================='
KEY_DEPOSIT=$(cat ~/node/config/genesis.json | grep keyDeposit | egrep -o '[0-9]+')
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
--testnet-magic 42

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
cardano-cli shelley node key-gen-KES \
--verification-key-file kes.vkey \
--signing-key-file kes.skey

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
SLOTS_PER_KESPERIOD=$(cat ~/node/config/genesis.json | grep slotsPerKESPeriod | egrep -o '[0-9]+')
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | egrep -o '[0-9]+' | head -n 1)
KESP=$(expr $CTIP / $SLOTS_PER_KESPERIOD) # SLOTS_PER_KESPERIOD=3600 at time of writing  
cardano-cli shelley node issue-op-cert \
--kes-verification-key-file kes.vkey \
--cold-signing-key-file cold.skey \
--operational-certificate-issue-counter cold.counter \
--kes-period $KESP --out-file node.cert

echo '========================================================='
echo 'Querying utxo details of payment.addr'
echo '========================================================='​
UTXO0=$(cardano-cli shelley query utxo --address $(cat payment.addr) --testnet-magic 42 | tail -n 1)
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
wget https://raw.githubusercontent.com/ptolem/sp/master/SAFE.json # Should be your JSON file
METAHASH=$(cardano-cli shelley stake-pool metadata-hash --pool-metadata-file SAFE.json)

echo '========================================================='
echo 'Generating transaction for Stake Pool Operation Certificate Pool Deposit'
echo '========================================================='
PLEDGE=1000000000000 # 1M ADA
cardano-cli shelley stake-pool registration-certificate \
--cold-verification-key-file cold.vkey \
--vrf-verification-key-file vrf.vkey \
--pool-pledge $PLEDGE --pool-cost 128000000 --pool-margin 0.064 \
--pool-reward-account-verification-key-file stake.vkey \
--pool-owner-stake-verification-key-file stake.vkey \
--single-host-pool-relay r0.eun.test.safestak.com \
--pool-relay-port 3001 \
--metadata-url https://raw.githubusercontent.com/ptolem/sp/master/SAFE.json \
--metadata-hash $(echo $METAHASH) \
--testnet-magic 42 \
--out-file pool.cert

echo '========================================================='
echo 'Calculating Fee'
echo '========================================================='
CTIP=$(cardano-cli shelley query tip --testnet-magic 42 | egrep -o '[0-9]+' | head -n 1)
TTL=$(expr $CTIP + 400)
FEE=$(cardano-cli shelley transaction calculate-min-fee \
--tx-in-count 1 \
--tx-out-count 1 \
--ttl $TTL --testnet-magic 42 \
--signing-key-file payment.skey \
--signing-key-file stake.skey \
--signing-key-file cold.skey \
--certificate-file pool.cert \
--certificate-file delegation.cert \
--protocol-params-file protocol.json | egrep -o '[0-9]+')

echo '========================================================='
echo 'Building Stake Pool Delegation Key transaction'
echo '========================================================='
POOL_DEPOSIT=$(cat ~/node/config/genesis.json | grep poolDeposit | egrep -o '[0-9]+') # 500000000 at time of writing
TXOUT=$(expr $UTXO0V - $FEE - $POOL_DEPOSIT) 
cardano-cli shelley transaction build-raw \
--certificate-file pool.cert \
--certificate-file delegation.cert \
--tx-in $(echo $UTXO0H)#$(echo $UTXO0I) --tx-out $(cat payment.addr)+$(echo $TXOUT) --ttl $TTL --fee $FEE --out-file tx.raw
echo '========================================================='
echo 'Signing transaction'
echo '========================================================='
cardano-cli shelley transaction sign \
--tx-body-file tx.raw \
--signing-key-file payment.skey \
--signing-key-file stake.skey \
--signing-key-file cold.skey \
--testnet-magic 42 \
--out-file tx.signed
echo '========================================================='
echo 'Submitting transaction'
echo '========================================================='
cardano-cli shelley transaction submit \
--tx-file tx.signed \
--testnet-magic 42
echo '========================================================='
echo 'Verify pool creation'
echo '========================================================='
cardano-cli shelley stake-pool id --verification-key-file cold.vkey
