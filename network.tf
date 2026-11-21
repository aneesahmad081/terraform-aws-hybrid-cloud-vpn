# ===================== us-east-1: simulated on-premises =====================
resource "aws_vpc" "onprem" {
  provider             = aws.onprem
  cidr_block           = var.onprem_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-onprem-vpc" }
}

resource "aws_subnet" "onprem_public" {
  provider                = aws.onprem
  vpc_id                  = aws_vpc.onprem.id
  cidr_block              = var.onprem_subnet_cidr
  availability_zone       = data.aws_availability_zones.onprem.names[0]
  map_public_ip_on_launch = false # VPN EC2 gets a stable Elastic IP explicitly.
  tags                    = { Name = "${var.project_name}-onprem-public-subnet" }
}

resource "aws_internet_gateway" "onprem" {
  provider = aws.onprem
  vpc_id   = aws_vpc.onprem.id
  tags     = { Name = "${var.project_name}-onprem-igw" }
}

resource "aws_route_table" "onprem_public" {
  provider = aws.onprem
  vpc_id   = aws_vpc.onprem.id
  tags     = { Name = "${var.project_name}-onprem-public-rt" }
}

resource "aws_route" "onprem_internet" {
  provider               = aws.onprem
  route_table_id         = aws_route_table.onprem_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.onprem.id
}

resource "aws_route_table_association" "onprem_public" {
  provider       = aws.onprem
  subnet_id      = aws_subnet.onprem_public.id
  route_table_id = aws_route_table.onprem_public.id
}

# ===================== eu-north-1: AWS cloud side ===========================
resource "aws_vpc" "cloud" {
  provider             = aws.cloud
  cidr_block           = var.cloud_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-cloud-vpc" }
}

resource "aws_subnet" "cloud_private" {
  provider                = aws.cloud
  vpc_id                  = aws_vpc.cloud.id
  cidr_block              = var.cloud_subnet_cidr
  availability_zone       = data.aws_availability_zones.cloud.names[0]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.project_name}-cloud-private-subnet" }
}

resource "aws_route_table" "cloud_private" {
  provider = aws.cloud
  vpc_id   = aws_vpc.cloud.id
  tags     = { Name = "${var.project_name}-cloud-private-rt" }
}

resource "aws_route_table_association" "cloud_private" {
  provider       = aws.cloud
  subnet_id      = aws_subnet.cloud_private.id
  route_table_id = aws_route_table.cloud_private.id
}

# This lab intentionally has NO Internet Gateway or NAT Gateway in the cloud
# VPC. Test the private web server over the encrypted VPN from the router.
