# azure-network-concepts

This project aims to study some concepts of Network provisioning on Azure using Terraform.

> **This project is in work in progress and will be updated without notice.**

## Branches Versions

- **`v1`** - provisioning two private Virtual Machine with remote access by VPN
- **`v2`** **[WIP]** - same as `v1` with additional purpose of allow a specific website domain by Firewall policies

## First steps

### 0. Configure Azure CLI on your local environment

See official documentation: [Get started with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli)

### 1. Generate and export certificates to P2S configuration

```bash
# run script to generate certificate
./generate-certificate.sh
```

You will see `caCert.pem`, `caKey.pem`, `clientCert.pem`, `clientKey.pem`, `client.p12` and `files/vpnRootCert.txt` files created. Some those files will be very import to Point-to-site configuration. See official documentation: [Install certificates](https://docs.microsoft.com/en-us/azure/vpn-gateway/point-to-site-vpn-client-cert-linux#install-certificates).

**_NOTE: please, read the content of the script_**

### 2. Create `demo.tfvars` files

```bash
mkdir envs && touch envs/demo.tfvars
```

After that, edit the content of `demo.tfvars` with:

```tfvars
ssh_pub_key_path = "~/.ssh/id_rsa.pub"
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
    name             = "GatewaySubnet", # do not rename
    address_prefixes = ["10.0.0.0/24"]
  }
}

```

## Running Terraform commands

### 1. Init

```bash
terraform init
```

### 2. Plan

```bash
terraform plan -var-file=envs/demo.tfvars
```

### 3. Apply

```bash
terraform apply -var-file=envs/demo.tfvars

# or
terrafor appy -auto-approve -var-file=envs/demo.tfvars

```

## Terraform Reference

- https://registry.terraform.io/providers/hashicorp/azurerm/3.19.1
