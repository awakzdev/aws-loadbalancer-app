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

## Setting credentials 
 ##### _Credentials key file is set within ~/.aws/credentials - Please [refer to documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)_ or use `aws configure` as a different approach.
*Your credentials file should look like this*
 ```
 [default]
# This key identifies your AWS account.
aws_access_key_id = foo
# Treat this secret key like a password. Never share it or store it in source
# control. If your secret key is ever disclosed, immediately use IAM to delete
# the key pair and create a new one.
aws_secret_access_key = foo
 ```
 ## Generating an SSH Key
 `ssh-keygen -t ed25519` > You'll need to rename it to 'key' otherwise please edit the resource aws_key_pair under main.tf.


## Installation
Creating your terraform.tfvars
```
cat <<EOF > terraform.tfvars
route53_zone = "<your-route53_zone-domain_name_here>"
sub_domain = "<your-domain-subname_here>"
EOF
```
