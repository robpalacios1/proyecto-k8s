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

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id  # Conneting to our VPC

    tags = {
        Name = "api-python-igw"
    }
}

# 3. PUBLIC SUBNETS
resource "aws_subnet" "public_subnet_1" {
    vpc_id                   = aws_vpc.main_vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name                     = "public-us-east-1a"
        "kubernetes.io/role/elb" = "1"
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id                   = aws_vpc.main_vpc.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = true

    tags = {
        Name                     = "public-us-east-1b"
        "kubernetes.io/role/elb" = "1"
    }
}

# 4. Route Table

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "api-python-public_rt"
    }
}

# 5. Table Association

resource "aws_route_table_association" "public_1_assoc" {
    subnet_id      = "aws_subnet.public_subnet_1.id"
    route_table_id = "aws_route_table.public_rt.id"
}

resource "aws_route_table_association" "public_2_assoc" {
    subnet_id      = "aws_subnet.public_subnet_2.id"
    route_table_id = "aws_route_table.public_rt.id"
}
