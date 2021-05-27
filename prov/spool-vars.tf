variable "ssh-whitelist" {
  type        = list(string)
  description = "Whitelist IP(s) for SSH access to the nodes. Helpful at the start but strongly recommended for removal later."
}
variable "mon-whitelist" {
  type        = list(string)
  description = "Whitelist IP(s) for monitoring agents access to nodes via Prometheus metrics data."
}
variable "pool-location" {
  type        = string
  description = "Stake Pool location from verified location list (az account list-locations -o table)"
}
variable "resource-prefix" {
  type        = string
  description = "Prefix to apply to all Stake Pool resources"
}
variable "storage-prefix" {
  type        = string
  description = "Prefix (shorthand) to apply to storage account"
}
variable "vm-username" {
  type        = string
  description = "VM username for all nodes"
}
variable "corevm-size" {
  type        = string
  description = "Stake Pool core node VM size (az vm list-sizes --location $pool-location -o table)"
}
variable "corevm-nic-accelerated-networking" {
  type        = string
  description = "Enable accelerated networking for core node NIC. Ensure it is supported by VM size."
}
variable "corevm-comp-name" {
  type        = string
  description = "Stake Pool core node VM computer name"
}
variable "corevm-node-port" {
  type        = string
  description = "Port to run the core cardano-node on"
}
variable "relayvm-size" {
  type        = string
  description = "Stake Pool relay node VM size (az vm list-sizes --location $pool-location -o table)"
}
variable "relayvm-nic-accelerated-networking" {
  type        = string
  description = "Enable accelerated networking for relay node NIC. Ensure it is supported by VM size."
}
variable "relayvm-comp-name" {
  type        = string
  description = "Stake Pool relay node VM computer name prefix"
}
variable "relayvm-node-port" {
  type        = string
  description = "Port to run the relay cardano-node on"
}
variable "monvm-size" {
  type        = string
  description = "Monitoring node VM size (az vm list-sizes --location $pool-location -o table)"
}
variable "monvm-nic-accelerated-networking" {
  type        = string
  description = "Enable accelerated networking for monitoring node NIC. Ensure it is supported by VM size."
}
variable "monvm-comp-name" {
  type        = string
  description = "Monitoring node VM computer name"
}
variable "monvm-node-port" {
  type        = string
  description = "Port to run the monitoring cardano-node on"
}
variable "monvm-graf-port" {
  type        = string
  description = "Port to expose the monitoring grafana on"
}
variable "tag-platform" {
  type        = string
  description = "Platform tag assigned to all resources"
}
variable "tag-stage" {
  type        = string
  description = "Stage tag assigned to all resources"
}
variable "tag-data-classification" {
  type        = string
  description = "Data classification tag assigned to all resources"
}