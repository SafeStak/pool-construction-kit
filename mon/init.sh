#!/bin/bash
# Note: Update addresses in the Initialising Prometheus Scraping Config section
# Disclaimer: 
echo
echo '========================================================='
echo 'Applying Security Updates  / Patches'
echo '========================================================='
sudo unattended-upgrade
sudo apt-get update -y
sudo apt-get upgrade -y

echo
echo '========================================================='
echo 'Getting Prometheus'
echo '========================================================='
sudo apt-get install -y prometheus prometheus-alertmanager
sudo systemctl enable prometheus.service

echo
echo '========================================================='
echo 'Getting Grafana'
echo '========================================================='
mkdir -p ~/mon
cd ~/mon
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" > grafana.list
sudo mv grafana.list /etc/apt/sources.list.d/grafana.list
sudo apt-get update && sudo apt-get install -y grafana
sudo systemctl enable grafana-server.service

echo
echo '========================================================='
echo 'Initialising Prometheus Scraping Config'
echo '========================================================='
# REPLACE IPS WITH YOUR OWN PUBLIC IP ADDRESSES
cat > prometheus.yml << EOF
global:
  external_labels:
    monitor: 'codelab-monitor'

scrape_configs:
  - job_name: 'spool'
    scrape_interval: 10s
    static_configs:
      - targets: ['1.1.1.1:9100']
        labels:
          alias: 'core'
      - targets: ['2.2.2.2:9100']
        labels:
          alias: 'relay0'
      - targets: ['3.3.3.3:9100']
        labels:
          alias: 'relay1'
      - targets: ['localhost:9100']
        labels:
          alias: 'mond'
      - targets: ['1.1.1.1:12798']
        labels:
          alias: 'core'
      - targets: ['2.2.2.2:12798']
        labels:
          alias: 'relay0'
      - targets: ['3.3.3.3:12798']
        labels:
          alias: 'relay1'
  - job_name: 'safestats-perf'
    scrape_interval: 30s
    metrics_path: 'safestats/v1/pools/74a10b8241fc67a17e189a58421506b7edd629ac490234933afbed97/metrics'
    static_configs:
      - targets: ['api.safestak.com']
        labels:
          alias: 'SAFE-summary'
          pool: '74a10b8241fc67a17e189a58421506b7edd629ac490234933afbed97'

EOF
sudo cp prometheus.yml /etc/prometheus/prometheus.yml

sudo systemctl restart prometheus.service
sudo systemctl restart grafana-server.service