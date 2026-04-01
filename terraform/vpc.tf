# 1. VPC (Virtual Private Cloud)
# Create the Private Network with Cloud isolation

resource "aws_vpc" "main_vpc" {
    cidr_block           = "10.0.0.0/16"  #
    enable_dns_support   = true           # Requirement for EKS
    enable_dns_hostnames = true           # Requirement for EKS

    tags = {
        Name = "api-python-vpc"
    }
}

# 2. INTERNET GATEWAY

resource "aws_internet_gatewaay" "igw" {
    vp_id = aws_vpc.main_vpc.id  # Conneting to our VPC

    tags = {
        Name = "api-python-igw"
    }
}

# 3. PUBLIC SUBNETS