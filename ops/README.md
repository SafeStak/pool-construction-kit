# SafeStak [SAFE] Cardano Stake Pool Operation Kit

## Running nodes
Note the public IP of the core and relay VMs from the provisioning. Ensure the topology.json of the core node only has the relay node IP address and the relay node has both the core and the Cardano relay node. Please see the topology-core.jsont and topology-relay.jsont files for reference.

### Relay
```
cardano-node run \
  --topology ~/node/config/topology.json \
  --database-path ~/node/db/ \
  --socket-path ~/node/socket/node.socket \
  --host-addr 0.0.0.0 \
  --port 3001 \
  --config ~/node/config/config.json
```
### Core (block producing node)
```
cardano-node run \
  --topology ~/node/config/topology.json \
  --database-path ~/node/db/ \
  --socket-path ~/node/socket/node.socket \
  --host-addr 0.0.0.0 \
  --port 3000 \
  --config ~/node/config/config.json \
  --shelley-kes-key ~/kc/kes.skey \
  --shelley-vrf-key ~/kc/vrf.skey \
  --shelley-operational-certificate ~/kc/node.cert
```

## Using systemd 
By registering and enabling [./cnode-core.service](cnode-core.service) and [./cnode-relay.service](cnode-relay.service) as systemd services, these nodes can run (and restart) automatically upon system boot.

### Relay
```
cp stn-relay.environment ~/node/config
sudo cp cnode-relay.service /etc/systemd/system/cnode-relay.service
sudo chmod 644 /etc/systemd/system/cnode-relay.service
sudo systemctl start cnode-relay
sudo systemctl status cnode-relay # This should look good
sudo systemctl enable cnode-relay
```

### Core
```
cp stn-core.environment ~/node/config
sudo cp cnode-core.service /etc/systemd/system/cnode-core.service
sudo chmod 644 /etc/systemd/system/cnode-core.service
sudo systemctl start cnode-core
sudo systemctl status cnode-core # This should look good
sudo systemctl enable cnode-core
```

## Checking rewards
```
cardano-cli shelley query stake-address-info --address $(cat ~/kc/stake.addr) --testnet-magic 42
```

## Troubleshooting
Some guidance from [this article](https://www.cyberciti.biz/faq/what-process-has-open-linux-port/).
### Get Process Info
`ps aux | grep cardano`
### Get Network Status
`sudo ss -tulpn | grep 3000` or `netstat -tulpn | grep 3000` or `lsof -i :3000`
