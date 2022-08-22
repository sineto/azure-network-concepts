## resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-demo"
  location = var.azure_location
}

## vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

## key pair
resource "azurerm_ssh_public_key" "keypair" {
  name                = "keypair-demo"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.rg.name
  public_key          = file(var.ssh_pub_key_path)

}

## subnet
resource "azurerm_subnet" "subnet_app" {
  name                 = var.subnets.app.name
  address_prefixes     = var.subnets.app.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "subnet_client" {
  name                 = var.subnets.client.name
  address_prefixes     = var.subnets.client.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "subnet_firewall" {
  name                 = var.subnets.firewall.name
  address_prefixes     = var.subnets.firewall.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "subnet_gateway" {
  name                 = var.subnets.gateway.name
  address_prefixes     = var.subnets.gateway.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

## vm app
resource "azurerm_network_interface" "nic_app" {
  name                = "nic-app-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic-app-internal"
    subnet_id                     = azurerm_subnet.subnet_app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "vm-app-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # az vm list-sizes -l eastus
  size                  = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.nic_app.id]

  admin_username = "azureuser"
  user_data      = filebase64("./scripts/app_user_data.sh")


  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_pub_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  # az vm image list -h
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

## vm client
resource "azurerm_network_interface" "nic_client" {
  name                = "nic-client-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dns_servers = ["1.1.1.1", "8.8.8.8"]
  # dns_servers = ["209.244.0.3", "209.244.0.4"]

  ip_configuration {
    name                          = "nic-client-internal"
    subnet_id                     = azurerm_subnet.subnet_client.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "client" {
  name                = "vm-client-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.location

  size                  = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.nic_client.id]

  admin_username                  = "azureuser"
  admin_password                  = "azureuser#TCB01"
  disable_password_authentication = false
  user_data                       = filebase64("./scripts/client_user_data.sh")

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

## vpn
resource "azurerm_public_ip" "gateway_public_ip" {
  name                = "gw-demo-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "gw-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  # https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings
  sku        = "VpnGw1"
  generation = "Generation1"

  ip_configuration {
    name                          = "gw-demo-vpn-config"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gateway_public_ip.id
    subnet_id                     = azurerm_subnet.subnet_gateway.id
  }

  vpn_client_configuration {
    address_space        = ["172.16.0.0/24"]
    vpn_client_protocols = ["IkeV2", "SSTP"]
    vpn_auth_types       = ["Certificate"]
    root_certificate {
      name             = "vpnRootCert"
      public_cert_data = file("./files/vpnRootCert.txt")
    }
  }
}

## firewall
