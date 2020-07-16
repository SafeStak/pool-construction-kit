# SafeStak [SAFE] Cardano Stake Pool Construction Kit

## Goals
 - Define an executable declarative representation of cloud infrastructure to host a [Cardano](https://cardano.org/en/what-is-cardano/) stake pool 
 - Write a set of scripts to setup and initialise Cardano core and relay nodes in the infrastructure
 - Document the whole process and share it with the community to expand and strengthen the Cardano blockchain network

## Prerequisites
 - **Azure CLI** [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest#install-or-update)
 - **Terraform** [here](https://www.terraform.io/downloads.html)
 - **Visual Studio Code** [here](https://code.visualstudio.com/download) and the **Remote - SSH** extension (thank me later)

## General Guide
 1. Provision the Azure infrastructure with Terraform in `/prov` after your variables in spool-vars
 2. Follow the [README](./init/README.md) in `/init` to build the cardano-node binaries
 3. Follow the [README](./ops/README.md) in `/ops` on operating the nodes

## Was this useful?
I hope this guide can help many others get their first Cardano stake pool up and running. I truly believe that the more people we have contributing to the community the quicker this ecosystem can realise its tremendous potential.

## CBF and want us to do it all for you?
Reach out to us at safestak@pm.me 

### How you can contribute
Stake to `SAFE` [SafeStak Staking Pool](https://www.safestak.com)

Donate ADA to `DdzFFzCqrhstoeh312o7AySdVMRyB5PpferbUcTEHqq6XXfs51qLGQWJeVjK3q5GovyF22wkit5eQbUKDH5u6ZrqsHtu8sSkPy1ZEQDh`
