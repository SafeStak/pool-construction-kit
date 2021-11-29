#!/bin/bash
# Note: One-off execution only! Do not run more than once in case of failures
echo
echo '========================================================='
echo 'Applying Security Update / Patches'
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

# GHCUP makes ghc and cabal versioning maintenance easier but requires user interaction
# mkdir -p ~/setup/ghcup
# cd ~/setup/ghcup
# curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh # Option 1 Interactive
# wget https://downloads.haskell.org/~ghcup/0.1.14.1/x86_64-linux-ghcup-0.1.14.1 # Option 2 Binary to be added to $PATH see https://gitlab.haskell.org/haskell/ghcup-hs#manual-install

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
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

echo
echo '========================================================='
echo 'Building and Publishing Cardano Binaries'
echo '========================================================='
cd ~/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/1.31.0
~/.local/bin/cabal configure --with-compiler=ghc-8.10.4
echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" >> cabal.project.local
~/.local/bin/cabal build all
cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/
cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/

echo
echo '========================================================='
echo 'Generating node artefacts - genesis, config and topology'
echo '========================================================='
# mkdir -p ~/testnet-node/config
# mkdir -p ~/testnet-node/socket
# cd ~/testnet-node/config
mkdir -p ~/node/config
mkdir -p ~/node/socket
cd ~/node/config
# wget -O config.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-config.json
# wget -O bgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-byron-genesis.json
# wget -O sgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-shelley-genesis.json
# wget -O agenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-alonzo-genesis.json
# wget -O topology.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-topology.json
wget -O config.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-config.json
wget -O bgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-byron-genesis.json
wget -O sgenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-shelley-genesis.json
wget -O agenesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-alonzo-genesis.json
wget -O topology.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-topology.json
sed -i 's/"TraceBlockFetchDecisions": false/"TraceBlockFetchDecisions": true/g' config.json
# sed -i 's/testnet-shelley-genesis/sgenesis/g' config.json
# sed -i 's/testnet-byron-genesis/bgenesis/g' config.json
# sed -i 's/testnet-alonzo-genesis/agenesis/g' config.json
sed -i 's/mainnet-shelley-genesis/sgenesis/g' config.json
sed -i 's/mainnet-byron-genesis/bgenesis/g' config.json
sed -i 's/mainnet-alonzo-genesis/agenesis/g' config.json

echo
echo '========================================================='
echo 'Updating PATH to binaries and setting socket env variable'
echo '========================================================='
echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.bashrc
echo 'export PATH="~/.cabal/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="~/.local/bin:$PATH"' >> ~/.bashrc
#echo 'export NODE_HOME="$HOME/testnet-node"' >> ~/.bashrc
echo 'export NODE_HOME="$HOME/node"' >> ~/.bashrc
#echo 'export CARDANO_NODE_SOCKET_PATH="$HOME/testnet-node/socket/node.socket"' >> ~/.bashrc
echo 'export CARDANO_NODE_SOCKET_PATH="$HOME/node/socket/node.socket"' >> ~/.bashrc