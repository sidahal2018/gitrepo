# Terraform
Project-2

This project is pretty much a replica of what we have done maunally on AWS console.

Create the following in AWS Console,

1 VPC 
4 subnets - 2 private - 2 public.
1 load balancer
1 ec2 instance in each public subnet with Apache running on it.
The load balancer’s DNS name should resolve to Apache running on the instances

Use Application Load Balancer to route content based traffic to different servers.

Access to the loadbalancer should only be from your Public IP address. 

1 ec2 instance in each private subnet
The ec2 instances in the private subnet should be able to download updates from the internet.


The only difference is you'll be doing it via Terraform.

So,
1. Create a repository in GitHub.
2. Write up a terraform template to create the exact same set of resources with the exact same configuration.
3. When completed; post the link to your GitHub repository so the code can be reviewed.


configured your terraform code for 5 servers - 
1 bastion, 2 web-servers and 2 db-servers. 
And also serving the contents from ALB at paths for example /images and /data folders. You can give any name for these folders. This would be a huge learning curve not only in regards to Terraform but Linux and Git.
Your ALB DNS name should resolve to different contents/folders and hence will do the path-based routing, as you configured manually in AWS. e.g. <ALB-DNS-name>/images or <ALB-DNS-name>/data

Your ALB DNS name should resolve to different contents/folders and hence will do the path-based routing, as you configured manually in AWS. e.g. <ALB-DNS-name>/images or <ALB-DNS-name>/data

We can ubnet_id for ec2 creation. Terraform will pick the VPC from there.

Terraform documenation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule