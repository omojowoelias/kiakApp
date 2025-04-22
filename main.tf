# Create VPC
# Create Internet Gateway
# Create Route Table
# Create Public Subnet
# Associate Route Table with subnet
# Create Security Group to allow port 80, 22, 443
# Create a Network Interface with an IP in the subnet that was created
# Assign an elastic IP to the network interface
# Create an Ubuntu Server install Apache2 and bootstrap with a webpage
# Output the Ip address of the Server (Public and Private address)



provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.example.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
#   }

  tags = {
    Name = "example"
  }
}

# Create Public Subnet
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

# Associate Route Table with subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Create Security Group to allow port 80, 22, 443
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  # Allow HTTPS (Port 443) from anywhere
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = aws_vpc.main.cidr_block
  }

  # Allow HTTP (Port 80) from anywhere
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = aws_vpc.main.cidr_block
  }
    # Allow SSH (Port 22) from anywhere
    ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22    
    protocol    = "tcp"
    cidr_blocks = aws_vpc.main.cidr_block
    }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
