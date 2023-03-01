# Configure the AWS Provider
provider "aws" {
    region = "eu-central-1"
}

variable  vpc_cidr_block {}
variable  private_subnet_cidr_block {}
variable  public_subnet_cidr_block {}

# Declare the data source
data "aws_availability_zones" "azs" {
  #state = "available"
}


# create vpc using existing module
module "my-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "my-vpc"
  cidr = var.vpc_cidr_block
  #A list of private subnets inside the VPC
  private_subnets = var.private_subnet_cidr_block
  # A list of public subnets inside the VPC
  public_subnets = var.public_subnet_cidr_block
  #A list of availability zones names or ids in the region
  azs = data.aws_availability_zones.azs.names
  enable_nat_gateway = true     #Should be true if you want to provision NAT Gateways for each of your private networks
  single_nat_gateway = true     #All private subnets will route their Internet traffic through this single Nate Gateway 
  enable_dns_hostnames = true   #Should be true to enable DNS hostnames in the VPC that will assign public and private dns names for any upcoming instance that will resolve the private and public ip of instance 

  # label our rsources using tags that can reference components from other components ,
  # so basically in eks cluster when you create the control-plane that has kubernetes cloud controller manager that orchestrate connecting to vpcs, connectiong to subnets , connecting to the worker nodes 
  # so it talk to resources in our aws-account, so  kubernetes cloud controller manager needs to know resources in our account to know which resources talk to? , which VPCs should be used?,  which subnets should be used?
  # because we want to tell the control-plane for aws use specific vpc and specific subnets for specific cluster 

  # label the VPC so Cloud controller manager can identify this vpc is belongs to "my-eks-cluster"
  tags = {
      "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
  # label the public subnet so Cloud controller manager can identify this public subnet is belongs to "my-eks-cluster"
  public_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"   
    # when we create LoadBalancer service in kubernetes , Kubernetes will provision cloud native loadBalancer for that service however it will provision that cloud loadBalancer in the public subnet because the loadBalancer is actually an entrypoint to the cluster 
    # So loadBalancer should be accessible from outside and it gets external Ip Add so we can communicate it from outside , So we want to differeniate between which is public subnet and which is private subnet by creating these tags 
    "kubernetes.io/role/elb" = 1
  }
  # label the private subnet so Cloud controller manager can identify this private subnet that belongs to "my-eks-cluster"
  private_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared" 
    "kubernetes.io/role/internal-elb" = 1
  }
}