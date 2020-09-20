# Setting up Monitoring and Alerting

## Goals
* Create a single view of your stake pool's health and performance 
* Be alerted in Telegram for any of the following (configurable) conditions:
  - CPU% utilisation exceeds 70% for any node
  - Memory% utilisation exceeds 70% for any node
  - Disk space drops below 20GB for any node
  - KES key is nearing expiry (2 days)
  - Elected to mint a block but missed
  - Number of peers drop below 2 for any node

## Pre-requisites 

### Prometheus and Grafana
[This tutorial for monitoring the stake pool](https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/logging-monitoring). Much of which can be set up with [init.sh](./init.sh) after a few tweaks.

### Performance Stats
Much of the top area of the dashboard showing stake pool performance stats relies [on a custom prometheus scraping job](https://github.com/SafeStak/pool-construction-kit/blob/caa122081e9376b4f3e2126bc19203652ed98a7e/mon/init.sh#L66) `safestats-perf`, powered by an API that we have built. Until it is hardened for public consumption it is only accessible by a few pool's and our own monitoring node but **feel free to Twitter DM @SafeStak or Telegram Keith on @knutty and we will allow your monitoring node IP through our firewall**. Big thanks to adapools.org for temporarily supplying the data until we finish building our own node backend.

### Telegram Alerts
Alerts are reliant on a Telegram Bot created with the following steps:
* Create a chat with the official Telegram Bot Maker `@BotFather`
* Run `/start` and `/newbot`, filling in the details for your bot's full name and username
* Note the API token of the bot
* Create a Telegram group for your Alerts and invite your bot by its @username
* Invite `@getidsbot` to the group, and note the chat ID of your Alerts group. Remove it once it has served its purpose.
* In Grafana (`http://your_grafana_address/alerting/notifications`), add notification channel `Telegram` of type Telegram with the token and chat ID from the previous steps

## Instructions
Import the [SAFEBOARD.json](./SAFEBOARD.json) dashboard into Grafana.

## Best Practices
Your monitoring node should be _physically_ separate from the rest of your stake pool nodes, in its own subnet with a permitted firewall rule allowing the monitoring node's source IP access to the prometheus metrics ports of your stake pool nodes. 