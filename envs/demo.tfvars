ssh_pub_key_path = "~/.ssh/id_rsa_tfsandbox_app.pub"
subnets = {
  "app" = {
    name             = "subnet-app-demo",
    address_prefixes = ["10.0.1.0/24"]
  },
  "client" = {
    name             = "subnet-client-demo",
    address_prefixes = ["10.0.2.0/24"]
  },
  "gateway" = {
    name             = "GatewaySubnet",
    address_prefixes = ["10.0.0.0/24"]
  },
  "firewall" = {
    name             = "AzureFirewallSubnet",
    address_prefixes = ["10.0.3.0/24"]
  }
}
