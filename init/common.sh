#!/bin/bash
# Note: One-off execution only! Do not run more than once in case of failures
echo
echo '========================================================='
echo 'Applying Security Upda  / Patches'
echo '========================================================='
sudo unattended-upgrade

echo
echo '========================================================='
echo 'Main Dependencies'
echo '========================================================='
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git jq wget curl bc make automake g++ build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev libncursesw5 libncurses-dev libtinfo5 libtool autoconf htop net-tools chrony prometheus-node-exporter -y

echo
echo '========================================================='
echo 'Ensuring the pool construction kit exists'
echo '========================================================='
mkdir -p ~/git
cd ~/git
[ ! -d "pool-construction-kit" ] && git clone https://github.com/SafeStak/pool-construction-kit

echo
echo '========================================================='
echo 'Optimising sysctl.conf and chrony'
echo '========================================================='
sudo cp ~/git/pool-construction-kit/init/sysctl.conf /etc/sysctl.conf
sudo cp ~/git/pool-construction-kit/init/chrony.conf /etc/chrony/chrony.conf
sudo sysctl --system
sudo systemctl restart chrony

echo
echo '========================================================='
echo 'Installing Cabal'
echo '========================================================='
mkdir -p ~/setup/cabal
cd ~/setup/cabal
wget https://downloads.haskell.org/cabal/cabal-install-3.4.0.0/cabal-install-3.4.0.0-x86_64-ubuntu-16.04.tar.xz
tar -xf cabal-install-3.4.0.0-x86_64-ubuntu-16.04.tar.xz
mkdir -p ~/.local/bin
cp cabal ~/.local/bin/
~/.local/bin/cabal update
~/.local/bin/cabal user-config update
sed -i 's/overwrite-policy:/overwrite-policy: always/g' ~/.cabal/config

echo
echo '========================================================='
echo 'Installing GHC'
echo '========================================================='
mkdir -p ~/setup/ghc
cd ~/setup/ghc
wget https://downloads.haskell.org/~ghc/8.10.4/ghc-8.10.4-x86_64-deb10-linux.tar.xz
tar -xf ghc-8.10.4-x86_64-deb10-linux.tar.xz
cd ghc-8.10.4
./configure
sudo make install

echo
echo '========================================================='
echo 'Building and Publishing libsodium Dependency'
echo '=========================================================\n\n\n\n'
cd ~/git/
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

echo
echo '========================================================='
echo 'Building and Publishing Cardano Binaries'
echo '========================================================='
cd ~/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --tags
git checkout tags/1.26.1
echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" > cabal.project.local
~/.local/bin/cabal build all
cp dist-newstyle/build/x86_64-linux/ghc-8.10.2/cardano-cli-1.26.1/x/cardano-cli/build/cardano-cli/cardano-cli ~/.local/bin/
cp dist-newstyle/build/x86_64-linux/ghc-8.10.2/cardano-node-1.26.1/x/cardano-node/build/cardano-node/cardano-node ~/.local/bin/

echo
echo '========================================================='
echo 'Generating node artefacts - genesis, config and topology'
echo '========================================================='
mkdir -p ~/node/config
mkdir -p ~/node/socket
cd ~/node/config
#wget -O config.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-config.json
#wget -O bgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-byron-genesis.json
#wget -O sgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-shelley-genesis.json
#wget -O topology.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-topology.json
wget -O config.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-config.json
wget -O bgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-byron-genesis.json
wget -O sgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-shelley-genesis.json
wget -O topology.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-topology.json
sed -i 's/"TraceBlockFetchDecisions": false/"TraceBlockFetchDecisions": true/g' config.json
sed -i 's/mainnet-shelley-genesis/sgenesis/g' config.json
sed -i 's/mainnet-byron-genesis/bgenesis/g' config.json

echo
echo '========================================================='
echo 'Updating PATH to binaries and setting socket env variable'
echo '========================================================='
echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
echo 'export PATH="~/.cabal/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="~/.local/bin:$PATH"' >> ~/.bashrc
echo 'export CARDANO_NODE_SOCKET_PATH=/home/ss/node/socket/node.socket' >> ~/.bashrc