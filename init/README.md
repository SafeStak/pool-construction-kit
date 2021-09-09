# SafeStak {SAFE} Cardano Stake Pool Initialisation Kit

In an effort to save time setting up the VMs to run the Cardano stake pool I have created the scripts in this folder but please use it with caution as they are possibility out-of-date! 

## Prerequisites
It is assumed that the [Terraform provisioning step](../README.md) has completed successfully and all the resulting Azure Cloud infrastructure exists in a pristine state. 

## Running init scripts
```
cd $HOME
mkdir -p git
cd git
git clone https://github.com/SafeStak/pool-construction-kit
cd pool-construction-kit/init
bash common.sh
```
## Relay nodes
Edit the topology.json file to ensure it follows the template in [topology-relay.jsont](./topology-relay.jsont) and include up to 18 other trusted relays. 

## Core nodes
Follow individual steps in [core.sh](core.sh) and edit the topology.json file to ensure it follows the template in [topology-core.jsont](./topology-core.jsont). 