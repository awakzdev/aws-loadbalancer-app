locals {
  json = {
    "vpc" : {
      "name" : "vpc",
      "cidr" : "192.168.0.0/16",
      "subnets" : [
        { "name" : "subnet-one", "cidr" : "192.168.1.0/24", "az" : "eu-central-1a", "private_ip" : "192.168.1.100" },
        { "name" : "subnet-two", "cidr" : "192.168.4.0/24", "az" : "eu-central-1b", "private_ip" : "192.168.4.100" }
      ]
    }
  }

  api = merge([
    for vpc in local.json : {
      for subnet in vpc.subnets :
      "${vpc.name}-${subnet.name}" => {
        vpc_name          = vpc.name
        vpc_cidr          = vpc.cidr
        subnet_name       = subnet.name
        subnet_cidr       = subnet.cidr
        subnet_az         = subnet.az
        subnet_private_ip = subnet.private_ip
      }
    }
  ]...)
}
