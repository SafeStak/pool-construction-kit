# Setting up Monitoring

## Pre-requisites and Best Practices
Your monitoring node should be physically separate from the rest of your stake pool nodes with a firewall rule allowing the monitoring node's source IP access to the prometheus metrics ports. 

## Instructions
* Note the address of your stake pool nodes and modify the scraping config in [init.sh](./init.sh)
* For performance summary metrics, say hi on telegram @knutty and I will give your monitoring node access to the stats (at least until I make it fully production ready) 
* Run `bash init.sh` on a fresh machine
* Import [SAFEBOARD.json](./SAFEBOARD.json) into Grafana as a dashboard
