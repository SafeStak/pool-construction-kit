#!/bin/bash
# Note: One-off execution only! Do not run more than once in case of failures

sudo unattended-upgrade
sudo apt-get update -y
sudo apt-get upgrade -y

echo
echo '========================================================='
echo 'Getting Prometheus'
echo '========================================================='
sudo apt-get install -y prometheus prometheus-alertmanager
sudo systemctl enable prometheus.service

# To be run on core/relay nodes
# sudo apt-get install -y prometheus-node-exporter 
# sudo systemctl enable prometheus-node-exporter.service

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
          alias: 'c0-ne'
      - targets: ['2.2.2.2:9100']
        labels:
          alias: 'r0-ne'
      - targets: ['3.3.3.3:9100']
        labels:
          alias: 'r1-ne'
      - targets: ['localhost:9100']
        labels:
          alias: 'm0-ne'
      - targets: ['1.1.1.1:12798']
        labels:
          alias: 'c0-cn'
      - targets: ['2.2.2.2:12798']
        labels:
          alias: 'r0-cn'
      - targets: ['3.3.3.3:12798']
        labels:
          alias: 'r1-cn'
EOF
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo systemctl restart grafana-server.service
sudo systemctl restart prometheus.service