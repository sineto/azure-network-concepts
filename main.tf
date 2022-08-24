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

  depends_on = [
    azurerm_resource_group.rg
  ]
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

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet_client" {
  name                 = var.subnets.client.name
  address_prefixes     = var.subnets.client.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet_gateway" {
  name                 = var.subnets.gateway.name
  address_prefixes     = var.subnets.gateway.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet_firewall" {
  name                 = var.subnets.firewall.name
  address_prefixes     = var.subnets.firewall.address_prefixes
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [
    azurerm_virtual_network.vnet
  ]
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

  depends_on = [
    azurerm_subnet.subnet_app
  ]
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

  depends_on = [
    azurerm_network_interface.nic_app
  ]
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

  depends_on = [
    azurerm_subnet.subnet_client
  ]
}

resource "azurerm_linux_virtual_machine" "client" {
  name                = "vm-client-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  depends_on = [
    azurerm_network_interface.nic_client
  ]
}

## vpn
resource "azurerm_public_ip" "gateway_public_ip" {
  name                = "gw-demo-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  depends_on = [
    azurerm_virtual_network.vnet
  ]
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

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_public_ip.gateway_public_ip
  ]
}

## firewall
resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "fw-demo-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "fw-demo-policy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_firewall" "firewall" {
  name                = "fw-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name           = "AZFW_VNet"
  sku_tier           = "Standard"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id

  ip_configuration {
    name                 = "fw-demo-ip-config"
    subnet_id            = azurerm_subnet.subnet_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_public_ip.firewall_public_ip,
    azurerm_firewall_policy.firewall_policy
  ]
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_collections" {
  name               = "fw-demo-policy-collections"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 200

  application_rule_collection {
    name     = "fw-demo-application-coll"
    priority = 300
    action   = "Allow"

    rule {
      name = "allow-duckgo"

      source_addresses  = azurerm_subnet.subnet_client.address_prefixes
      destination_fqdns = ["*.duckduckgo.com", "duckduckgo.com"]

      protocols {
        port = 80
        type = "Http"
      }

      protocols {
        port = 443
        type = "Https"
      }
    }
  }

  network_rule_collection {
    name     = "fw-demo-network-coll"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      protocols             = ["TCP", "UDP"]
      source_addresses      = azurerm_subnet.subnet_client.address_prefixes
      destination_ports     = ["53"]
      destination_addresses = ["1.1.1.1", "8.8.8.8"]
    }
  }

  nat_rule_collection {
    name     = "fw-demo-dnat-coll"
    priority = 100
    action   = "Dnat"

    rule {
      name                = "rdp"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_ports   = ["3389"]
      destination_address = azurerm_public_ip.firewall_public_ip.ip_address
      translated_port     = "3389"
      translated_address  = azurerm_linux_virtual_machine.client.private_ip_address
    }
  }

  depends_on = [
    azurerm_linux_virtual_machine.client,
    azurerm_subnet.subnet_client,
    azurerm_firewall_policy.firewall_policy,
    azurerm_public_ip.firewall_public_ip,
    azurerm_firewall.firewall
  ]
}

## route table
resource "azurerm_route_table" "route_table" {
  name                          = "rt-demo"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "rt-demo-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  depends_on = [
    azurerm_firewall.firewall
  ]
}

resource "azurerm_subnet_route_table_association" "route_table_association" {
  subnet_id      = azurerm_subnet.subnet_client.id
  route_table_id = azurerm_route_table.route_table.id

  depends_on = [
    azurerm_subnet.subnet_firewall,
    azurerm_route_table.route_table
  ]
}
