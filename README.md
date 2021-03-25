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

We can subnet_id for ec2 creation. Terraform will pick the VPC from there.

Map and Lookup. (EC2 Section)
-- Remeber, every work you do, always endeavour to make it dynamic to accomodate future changes. The AMI we have is only available in the region in we created it. But what if we change the region later, and want to dynamically pick up AMI IDs based on the available AMIs in that region? This is when we will introduce Map and Lookup
Map is a data structure type that can be set as a default type for variables. It is presented as key and value pairs


      variable "mymap" { 
      type = "map"
      default= {
 
       key1 = "value1"
      key2 = "value2" 
 
       }

        }


------------------------------------------------------------------------
Just use, subnet_id for ec2 creation. Terraform will pick the VPC from there.

--------------------------------------------------------------
`cidrsubnet`: This function works like an algorithm to dynamically create a subnet cidr per AZ. Regardless of the number of subnets created, it takes care of the cidr value per subnet.

Its parameters are cidrsubnet(prefix, newbits, netnum)

The prefix parameter must be given in CIDR notation. Just as the VPC.
The newbits parameter is the number of additional bits with which to extend the prefix. For example, if given a prefix ending in /16 and a newbits value of 4, the resulting subnet address will have length /20
The netnum parameter is a whole number that can be represented as a binary integer with no more than newbits binary digits, which will be used to populate the additional bits added to the prefix

-------------------------------------------------------------
element retrieves a single element from a list.

`element(list, index)`




Terraform documenation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule