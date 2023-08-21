## *Its purpose is to serve the following configuration*
It is required to deploy a configuration consisting of the following:
1. Two ubuntu VMs that will run an application
2. An ALB that will route the domain to the ALB on port
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

## Requirements
1. You must have a registered domain.
2. Create an SSH Key.

## Configuration
- route53_zone: The primary domain managed by AWS Route53.
- domain: The specific subdomain for your website (e.g., sub.domain.com, Your application will be served on this URL).
- name_prefix: Naming prefix for your environment or resources (e.g., Staging, Dev, Production).
- ssh_key: Name of the SSH key (Note: a `.pub` extension will be added to the name).
- db_engine: Database engine choice (options: mysql, postgres, mariadb, aurora).
- db_name: Name identifier for your RDS instance.
- db_username: Database username (Note: Must start with a letter and contain only alphanumeric characters).
- db_password: Database password (Note: Minimum of 8 characters).

You may use this sample for your convenience
```
route53_zone="domain.com"
domain="example.domain.com"
name_prefix="staging"
ssh_key="id_ed25519"
db_engine="mysql"
db_name="rds"
db_username="admin"
db_password="password"
```

# Feedback and Contributions
Feedback is welcomed, issues, and pull requests! If you have any suggestions or find any bugs, please open an issue on my GitHub repository.
