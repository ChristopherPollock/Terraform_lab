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

#create subnet #1  us-east-1
resource "aws_subnet" "subnet-1" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Env = "Terraform Lab"
  }
}

#create subnet #2 us-east-1
resource "aws_subnet" "subnet-2" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Env = "Terraform Lab"
  }
}

#create subnet us-west-2
resource "aws_subnet" "subnet-1-oregon" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_oregon.id
  cidr_block = "192.168.1.0/24"
  tags = {
    Env = "Terraform Lab"
  }
}

#initiate Peering connection request from us-east-1
resource "aws_vpc_peering_connection" "vpc-useast1-uswest2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_oregon.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
  tags = {
    Env = "Terraform Lab"
  }
}

#Accept VPC Peering connection request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc-useast1-uswest2.id
  auto_accept               = true
  tags = {
    Env = "Terraform Lab"
  }
}

#Create router table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc-useast1-uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
    Env  = "Terraform Lab"
  }
}
#Overwrite the default route table of the VPC (Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

#Create router table in us-west-2
resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_oregon.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-oregon.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc-useast1-uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
    Env  = "Terraform Lab"
  }
}

#Overwrite the default route table of the VPC (Master) with our route table entries
resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_oregon.id
  route_table_id = aws_route_table.internet_route_oregon.id
}