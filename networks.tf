#create VPC in US-east-1
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    name = "master-vpc-jenkins"
    Env  = "Terraform Lab"
  }
}
#create VPC in US-west-2
resource "aws_vpc" "vpc_oregon" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    name = "worker-vpc-jenkins"
    Env  = "Terraform Lab"
  }
}

#create IGW in us-east-1
resource "aws_internet_gateway" "igw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  tags = {
    Env = "Terraform Lab"
  }
}

#create IGW in us-west 2-1
resource "aws_internet_gateway" "igw-oregon" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_oregon.id
  tags = {
    Env = "Terraform Lab"
  }
}

#get all available AZ's in the VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

#create subnet in #1 unb us-east-1
resource "aws_subnet" "subnet-1" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Env = "Terraform Lab"
  }
}

#create subnet in #1 unb us-west-2
resource "aws_subnet" "subnet-1-oregon" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_oregon.id
  cidr_block = "192.168.1.0/24"
  tags = {
    Env = "Terraform Lab"
  }
}