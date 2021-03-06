#-------------------------------
#  Provider specific variables 
#-------------------------------
# provider "azurerm" {
#   alias = "lz"
# }

# provider "azurerm" {
#   alias = "hub"
# }

#-------------------------------
#  Common variables 
#-------------------------------
variable "prefix" {
  description = "A prefix for the resources for the landing zone network"
  default     = "lz" #(prefix for landing zone resources)
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources"
  default     = "uksouth" #(e.g. westeurope, uksouth, eastus)
  type        = string
}

variable "environment" {
  description = "Name of the environment for the Landing Zone"
  default     = "" #(e.g. dev, test, prod)
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

#-------------------------------
#  VNET specific variables 
#-------------------------------
variable "address_space" {
  description = "The address space to be used for the Azure virtual network."
  default     = ["10.0.0.0/16"]
  type        = list(string)
}

# This variable is optional
variable "dns_servers" {
  description = "List of dns servers to use for virtual network"
  default     = []
  type        = list(string)
}

#-------------------------------
#  Subnet specific variables 
#-------------------------------

# variable "subnet_names" {
#   description = "The name of the subnet. Changing this forces a new resource to be created."
#   default     = ["subnet1", "subnet2"]
#   type        = list(string)
# }

#-------------------------------
#  UDR specific variables 
#-------------------------------

variable "remote_vnet_address_prefix" {
  description = "The destination CIDR to which the route applies, such as 10.1.0.0/16"
  type = string
}

#-------------------------------
#  VNET peering specific variables 
#-------------------------------

variable "remote_virtual_network_id" {
  description = "The Azure resource ID of the remote virtual network. Changing this forces a new resource to be created."
  type        = string
   # e.g. (/subscriptions/<subId>/resourceGroups/<rgName>/providers/Microsoft.Network/virtualNetworks/<vnetName>)
}

variable "hub_resource_group_name" {
  type = string

}
variable "remote_vnet_name" {
  type = string
}

variable "subnet_prefixes" {
  type = list
  description = "The address prefix to use for the subnet."
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  #default     = ["10.0.1.0/24", "10.0.3.0/24"]
}
variable "subnet_names" {
  description = "A list of public subnets inside the vNet."
  default     = ["Subnet1", "Subnet2",  "Subnet3"]
  #default     = ["GateWaySubnet", "Subnet3"]
}
