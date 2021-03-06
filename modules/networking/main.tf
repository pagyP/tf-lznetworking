#-------------------------------
# Resource group creation
#-------------------------------

resource "azurerm_resource_group" "lz-network-rg" {
  name     = "${var.prefix}-resource-group"
  location = var.location
  provider = azurerm.lz
  tags     = merge({"ResourceGroup" = format("%s", var.prefix)}, var.tags)
}

#-------------------------------
# Virtual network creation
#-------------------------------

resource "azurerm_virtual_network" "lz-vnet" {
  name                = "${var.prefix}-${var.environment}-vnet"
  location            = lower(azurerm_resource_group.lz-network-rg.location)
  resource_group_name = lower(azurerm_resource_group.lz-network-rg.name)
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  provider            = azurerm.lz
  tags                = merge(var.tags)
}

#-------------------------------
# Subnet creation by specifying a list of subnet names
#-------------------------------

# resource "azurerm_subnet" "lz-subnet" {
#   count                = length(var.subnet_names)
#   name                 = "${var.prefix}-${var.subnet_names[count.index]}"
#   resource_group_name  = azurerm_resource_group.lz-network-rg.name
#   virtual_network_name = azurerm_virtual_network.lz-vnet.name
#   address_prefixes     = [cidrsubnet(element(azurerm_virtual_network.lz-vnet.address_space,0),3,count.index)]
#   provider             = azurerm.lz
# }

resource "azurerm_subnet" "lz-subnet" {
  name                 = var.subnet_names[count.index]
  virtual_network_name = azurerm_virtual_network.lz-vnet.name
  resource_group_name  = azurerm_resource_group.lz-network-rg.name
  #address_prefix       = var.subnet_prefixes[count.index]
  address_prefixes = [var.subnet_prefixes[count.index]]
  count                = length(var.subnet_names)
  provider             = azurerm.lz
}

resource "azurerm_subnet" "app-gw-lz-subnet" {
  count = var.appgw ? 1 : 0
  name                 = var.appgw_subnet_name
  virtual_network_name = azurerm_virtual_network.lz-vnet.name
  resource_group_name  = azurerm_resource_group.lz-network-rg.name
  #address_prefix       = var.subnet_prefixes[count.index]
  address_prefix = var.appgw_subnet_prefix
  //count                = length(var.subnet_names)
  provider             = azurerm.lz
}

/* This is not utilised currently

locals {
  azurerm_subnets = {
    for index, subnet in azurerm_subnet.lz-subnet :
    subnet.name   => subnet.id
  }
} 
*/

#Network security group creation 
resource "azurerm_network_security_group" "lz-default-nsg" {
  count               = length(var.subnet_names)
  //name                = "${var.prefix}-default-nsg"
 // name                = "${var.subnet_names}.[count.index]-NSG"
 //name                 = var.subnet_names[count.index]
 name                 = "${var.subnet_names[count.index]}-NSG"
  location            = azurerm_resource_group.lz-network-rg.location
  resource_group_name = azurerm_resource_group.lz-network-rg.name
  provider            = azurerm.lz
}

# Network security group association with subnet
resource "azurerm_subnet_network_security_group_association" "lz-vnet-nsg-association" {
  count                     = length(var.subnet_names)
  subnet_id                 = azurerm_subnet.lz-subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.lz-default-nsg[count.index].id
  provider                  = azurerm.lz
}

/* Below resources will be created as part of the peering connection to the Hub network :
  i) User defnied RT creation to the Hub virtual network
  ii) VNET peering to and from the Hub network
*/

resource "azurerm_route_table" "rt" {
  name                          = "${var.prefix}-routetable"
  location                      = azurerm_resource_group.lz-network-rg.location
  resource_group_name           = azurerm_resource_group.lz-network-rg.name
  disable_bgp_route_propagation = true
  route {
    name                        = "routetoHub"
    address_prefix              = var.remote_vnet_address_prefix
    next_hop_type               = "VirtualAppliance" #(the type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.)
    next_hop_in_ip_address      = "10.172.250.4"
  }
  route {
    name = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type               = "VirtualAppliance" #(the type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.)
    next_hop_in_ip_address      = "10.172.250.4"
  }
  provider = azurerm.lz
  tags     = merge(var.tags)
}

resource "azurerm_subnet_route_table_association" "rt-assoc" {
  count          = length(var.subnet_names)
  subnet_id      = azurerm_subnet.lz-subnet[count.index].id
  route_table_id = azurerm_route_table.rt.id
  provider       = azurerm.lz
}

resource "azurerm_virtual_network_peering" "lz-to-hub-peering"{
  name                      = "${var.prefix}-peering-to-hub"
  resource_group_name       = azurerm_resource_group.lz-network-rg.name
  virtual_network_name      = azurerm_virtual_network.lz-vnet.name
  remote_virtual_network_id = var.remote_virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
 // use_remote_gateways          = true
  provider                  = azurerm.lz
}

resource "azurerm_virtual_network_peering" "hub-to-lz-peering" {
  name                      = "hub-peering-to-${var.prefix}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.remote_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.lz-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  provider                  = azurerm.hub
}