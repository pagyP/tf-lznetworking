module "landingZoneNetworking" {
  source = "./modules/networking" #indicates a local path
  location = var.location
  address_space = var.address_space
  prefix    = var.prefix
  environment = var.environment
  subnet_names = var.subnet_names
  remote_virtual_network_id = var.remote_virtual_network_id
  remote_vnet_address_prefix = var.remote_vnet_address_prefix
  hub_resource_group_name = var.hub_resource_group_name
  remote_vnet_name = var.remote_vnet_name
  dns_servers = var.dns_servers
  providers = {
    azurerm.lz = azurerm.lz
    azurerm.hub = azurerm.hub
  }
  tags = {
    ProjectName = "MyProject"
    Env         = "dev"
    CostCentre  = "123"
  }
}

