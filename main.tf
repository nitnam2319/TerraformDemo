#Main Terraform Start
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

#Region Provider
provider "aws" {
  region = var.region
}

#Create Virtual Private Cloud (VPC) -
# In Virtual Private Cloud we have Internet at the top then Internet Gateway which we call (IGW) from where the flow enters the AWS VPC
# In the below mentioned code, I am creating a VPC name Linux-VPC01 with cidr 10.0.0.0 to 10.0.255.255
# 10.0.0.0 IP formatting is same as physical Office Network 192.168.1.0/24

resource "aws_vpc" "vpc01" {

  cidr_block = "10.0.0.0/16"
  tags = {
    name = "VPC01"

  } 
}

#Now we will create subnet, if VPC is a city then subnet is a street

resource "aws_subnet" "publicsubnet01" {
  vpc_id = aws_vpc.vpc01.id #main linkage with the vpc
  cidr_block =  "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true # This means whenever an EC2 is launched in this subnet, assign a public IP to it
  tags = {

    name = "Public Subnet 01"
  }
}

#Now we are adding Internet Gateway to it, imaging we have a house but no door, IGW is a door for the AWS network to connect to the internet

resource "aws_internet_gateway" "internetgateway01" {
  
  vpc_id = aws_vpc.vpc01.id #main linkage with the vpc
  tags = {
    name = "Internet Gateway 01" 
  }
}


#Now create a route table - which means where to send the traffic, in our case we are sending Anything to internet

resource "aws_route_table" "routetable01" {
  vpc_id = aws_vpc.vpc01.id #main linkage with vpc
  route {
    cidr_block = "0.0.0.0/0" # this means anywhere
    gateway_id = aws_internet_gateway.internetgateway01.id #linking gateway ID with Route Table
  }
  tags = {
    name = "Route Table"

  }
}

#Now association between Subnet and the Route Table is required

resource "aws_route_table_association" "routetablesubnetassociation01" {
  subnet_id = aws_subnet.publicsubnet01.id
  route_table_id = aws_route_table.routetable01.id
}

#Now security group is required - how and who can make a connection
#this is like a firewall for AWS connections

resource "aws_security_group" "securitygroup01" {
  
  name = "SecurityGroup-01"
  vpc_id = aws_vpc.vpc01.id

  ingress { #inbound traffic mostly restrictive

    description = "SSH"
    from_port = 22
    to_port =22
    protocol = "tcp"

    cidr_blocks = ["80.209.154.51/32", "81.111.21.226/32", "80.4.95.78/32"] # I am using my laptop public IP for now, you can use here [0.0.0.0/0] for eveyone in the world to connect
  }

  egress { #outbound traffic mostly open

    from_port = 0
    to_port = 0
    protocol = "-1" #any protocla tcp/udp
    cidr_blocks = ["0.0.0.0/0"] # for eveyone in the world to connect, to download updates, access repositiories etc
  }

  tags = {
    name = "Security Group 01"
  }
}

#Now create a security Key Pair  - AWS doesnlt allow password login by default 

resource "aws_key_pair" "linuxkey01" {
  key_name = "terraform-linux-key"
  public_key = file("terraform-linux.pub")
}

#Now creat an EC2 instance with all the settings we have done

resource "aws_instance" "LinuxSRV01" {
  
  ami = "ami-0506d85c3cdb18989"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.publicsubnet01.id

  vpc_security_group_ids = [
    aws_security_group.securitygroup01.id
  ]

  key_name = aws_key_pair.linuxkey01.key_name

  tags = {
    name = "Linux Server01"
  }
}