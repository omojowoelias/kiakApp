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
resource "aws_vpc" "elias_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "elias_vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "elias_gw" {
  vpc_id = aws_vpc.elias_vpc.id

  tags = {
    Name = "elias_gw"
  }
}

# Create Route Table
resource "aws_route_table" "elias_rt" {
  vpc_id = aws_vpc.elias_vpc.id
  # Create a route to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.elias_gw.id
  }

  #   route {
  #     ipv6_cidr_block        = "::/0"
  #     egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  #   }

  tags = {
    Name = "elias_rt"
  }
}

# Create Public Subnet
resource "aws_subnet" "elias_subnet" {
  vpc_id     = aws_vpc.elias_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

# Associate Route Table with subnet
resource "aws_route_table_association" "elias_association" {
  subnet_id      = aws_subnet.elias_subnet.id
  route_table_id = aws_route_table.elias_rt.id
}

# Create Security Group to allow port 80, 22, 443
resource "aws_security_group" "elias_sg" {
  name        = "elias_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.elias_vpc.id

  # Allow HTTPS (Port 443) from anywhere
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow HTTP (Port 80) from anywhere
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  # Allow SSH (Port 22) from anywhere
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elias_sg"
  }
}

# Create a Network Interface with an IP in the subnet that was created
resource "aws_network_interface" "elias_network_interface" {
  subnet_id       = aws_subnet.elias_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.elias_sg.id]
}

# Assign an elastic IP to the network interface
resource "aws_eip" "elias_eip" {
  network_interface         = aws_network_interface.elias_network_interface.id
  associate_with_private_ip = aws_network_interface.elias_network_interface.private_ip
  # Removed deprecated 'vpc' argument

  tags = {
    Name = "elias_eip"
  }
}

# Create an Ubuntu Server install Apache2 and bootstrap with a webpage
resource "aws_instance" "elias_server" {
  ami           = "ami-0dcc1e21636832c5d"
  instance_type = "t3.micro"
  network_interface {
    network_interface_id = aws_network_interface.elias_network_interface.id
    device_index         = 0
  }
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              echo "<h1>Hello, World!</h1>" > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2
              EOF 
  tags = {
    Name = "web"
  }
}
output "instance_public_ip_addr" {
  # The public IP address of the instance
  value = aws_eip.elias_eip.public_ip
}
output "instance_private_ip_addr" {
  value = aws_eip.elias_eip.private_ip
}