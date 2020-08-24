#!/bin/bash

if [[ $# -eq 1 && ! $1 == "" ]]; then nodeName=$1; else echo "ERROR - Usage: $0 {versionTag}"; exit 2; fi

export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

echo
echo '========================================================='
echo 'Building Version $1 of the Cardano Binaries'
echo '========================================================='
cd ~/ws/cardano-node
git fetch --all --tags
git checkout "tags/$1"

cabal clean
cabal update
cabal build all

echo
echo '========================================================='
echo 'Copying cardano-cli cardano-node $1 binaries to ~/.local/bin'
echo '========================================================='
cp "dist-newstyle/build/x86_64-linux/ghc-8.6.5/cardano-cli-$1/x/cardano-cli/build/cardano-cli/cardano-cli" ~/.local/bin/
cp "dist-newstyle/build/x86_64-linux/ghc-8.6.5/cardano-node-$1/x/cardano-node/build/cardano-node/cardano-node" ~/.local/bin/
