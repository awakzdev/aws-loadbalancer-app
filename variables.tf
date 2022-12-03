locals {
  json = jsondecode(file("API.json"))

  api = merge([
    for vpc in local.json : {
      for subnet in vpc.subnets :
      "${vpc.name}-${subnet.name}" => {
        vpc_name          = vpc.name
        vpc_cidr          = vpc.cidr
        subnet_name       = subnet.name
        subnet_cidr       = subnet.cidr
        subnet_az         = subnet.az
        subnet_private_ip = subnet.private
      }
    }
  ]...)
}
