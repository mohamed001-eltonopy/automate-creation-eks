# eks cluster needs to authenticate with master node of kubernetes to create some resources 
provider "kubernetes" {
  # we don't need kubernetes to load default kubeconfig file in "/.kube/config" as we will create a new one 
  #load_config_file = false
  host                   = data.aws_eks_cluster.my-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.my-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.my-cluster.token
}

# use data source of eks cluster to identify the name of eks
data "aws_eks_cluster" "my-cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "my-cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  # Download the resource from terraform registery
  source  = "terraform-aws-modules/eks/aws"
  version = "18.21.0"

  cluster_name = "my-eks-cluster"
  cluster_version = "1.22"

  # calling subnets and vpc that you want to connect with the cluster 
  # a list of subnets that we want a worker nodes started in , but as we have 6 subnets 3 for private and 3 for public , and private subnets are for workloads that need to be scheduled
  #  and public subnets for external resources like loadbalancer , but for a workload we want to be in a private subnets becouse it not exposed to the internet 
  subnet_ids = module.my-vpc.private_subnets 
  vpc_id = module.my-vpc.vpc_id

  tags = {
    environmet = "development"
    application = "my-apps"
  }
  
  # manage instances using node_groups 
/*  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t2.small"]
    }
}
*/  
    eks_managed_node_groups = {
    general = {
      desired_size = 1
      min_size     = 1
      max_size     = 3

      labels = {
        role = "general"
      }

      instance_types = ["t2.small"]
      capacity_type  = "ON_DEMAND"
    }
  }
}