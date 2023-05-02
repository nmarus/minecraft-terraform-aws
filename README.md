# Minecraft in AWS

This repo has Terraform modules to create Minecraft servers for Bedrock or Java versions within AWS. The module will create all necessary infrastructure. 

## Example

```hcl
provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 0.15.4"
}

module "minecraft" {
  source = "./minecraft-java"
  # source = "./minecraft-bedrock"

  name_prefix        = "minecraft"
  vpc_cidr           = "10.33.0.0/28"
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
  ]
}

output "public_ip" {
  value = module.minecraft.public_ip
}

output "public_dns" {
  value = module.minecraft.public_dns
}
```
