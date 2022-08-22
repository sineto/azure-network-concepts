variable "azure_location" {
  type    = string
  default = "East US"
}

variable "ssh_pub_key_path" {
  type        = string
  description = "Path to a SSH public key"
}

variable "subnets" {
  type = map(any)
}
