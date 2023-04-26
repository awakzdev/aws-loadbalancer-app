## *Its purpose is to serve the following configuration*
It is required to deploy a configuration consisting of the following:
1. Two ubuntu VMs that will run an application
2. An ALB that will route the domain modules.cclab.cloud-castles.com to the ALB on port
443, with an SSL certificate served by the ALB and a single target group containing both
VMs listening on port 80.
3. An RDS database running mysql for the application to access.
All components should run in a VPC, in separate subnets, and for the VMs and the load
balancer internals, the subnets should be in separate AZs.
The configuration should be secured so that the only connectivity allowed is the following:
1. SSH from the internet to the VMs
2. Port 80 between the load balancer internal IPs to the VMs
3. Port s 80 and 443 from the internet to the load balancer (with port 80 automatically
redirecting to 443)
4. Port 3306 from the VMs to the RDS

![image](https://user-images.githubusercontent.com/96201125/205367561-8ea50bfc-5520-4439-a7e8-0e3ec86c360a.png)

All this should be setup with terraform, in a modular fashion.
There should be a module for each of the components:
1. Networking - VPC and subnets.
2. ALB, with DNS configuration, certificate and target group.
3. VMs
4. RDS

Each module should configure its own security groups, using arguments from other modules'
output.

## Result
Once terraform is done running your Sub domain should return an Apache template with a TLS Certificate.
![chrome_D1yxqirAJY](https://user-images.githubusercontent.com/96201125/234573009-264794f0-539b-4b6b-853a-dc7cfbf997d5.png)

 ## Generating an SSH Key
 `ssh-keygen -t ed25519` > You'll need to rename it to 'key' otherwise please edit the resource `aws_key_pair` under `main.tf`.

## Creating terraform.tfvars
```
cat <<EOF > terraform.tfvars
route53_zone = "<Route53-Zone>" # Example - domain.com
sub_domain = "<your-domain-subname-here>" # Example - foo.domain.com
name_prefix = "<Resource-Naming-Prefix>" # Example - Staging
EOF
```
