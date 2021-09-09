#!/bin/bash

if [[ $# -eq 1 && ! $1 == "" ]]; then nodeName=$1; else echo "ERROR - Usage: $0 {versionTag}"; exit 2; fi

sudo apt-get update -y
sudo apt-get upgrade -y
sudo unattended-upgrade

echo
echo '========================================================='
echo "Backing up to ~/backup/$(date --iso-8601)"
echo '========================================================='
mkdir -p ~/backup/$(date --iso-8601)
cd ~/backup/$(date --iso-8601)
cp ~/.local/bin/cardano-node ./
cp ~/.local/bin/cardano-cli ./

# Helps to upgrade using ghcup if it exists
# curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
# ghcup upgrade
# ghcup install ghc 8.10.4
# ghcup set ghc 8.10.4
# ghcup install cabal 3.4.0.0
# ghcup set cabal 3.4.0.0

echo
echo '========================================================='
echo 'Building Version $1 of the Cardano Binaries'
echo '========================================================='
cd ~/git/cardano-node
git fetch --all --tags
git checkout "tags/$1"

cabal clean
cabal update
cabal build all

echo
echo '========================================================='
echo 'Copying cardano-cli cardano-node $1 binaries to ~/.local/bin'
echo '========================================================='
cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/
cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/

