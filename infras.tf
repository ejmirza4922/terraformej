terraform {
  required_version = "~>1.6.5"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.49.0"
    }
  }
}

provider "aws" {
    profile = "Hitesh"
    region = "us-east-1"
  # Configuration options
}


#VPC
resource "aws_vpc" "terraform-vpc" {
  cidr_block = "11.11.0.0/16"
}

#Public subnets

resource "aws_subnet" "Public-sub" {
  vpc_id     = aws_vpc.terraform-vpc
  cidr_block = "11.11.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public-sub"
  }
}
#Private Sub
resource "aws_subnet" "Private-sub" {
  vpc_id     = aws_vpc.terraform-vpc
  cidr_block = "11.11.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-sub"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform-vpc

  tags = {
    Name = "IGW"
  }
}

#elastic ip

resource "aws_eip" "eip" {
    vpc      = true
}

#NAT Gateway

resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.eip
  subnet_id     = aws_subnet.Public-sub 

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}



#Route Tables

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.terraform-vpc

 

  tags = {
    Name = "public-rt"
  }
}


resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.terraform-vpc

 

  tags = {
    Name = "private-rt"
  }
}


#Routes in route table

resource "aws_route" "public-route" {
  route_table_id            = aws_route_table.public-rt
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw
  depends_on = [ aws_route_table.public-rt ]
  
}

resource "aws_route" "Private-route" {
  route_table_id            = aws_route_table.private-rt
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.NAT
  depends_on = [ aws_route_table.private-rt ]
  
}


# subnet association 

resource "aws_route_table_association" "c-rt-asso" {
  subnet_id      = aws_subnet.Public-sub
  route_table_id = aws_route_table.public-rt
}

resource "aws_route_table_association" "private-rt-asso" {
  subnet_id      = aws_subnet.Private-sub
  route_table_id = aws_route_table.private-rt
}

#Security Group

resource "aws_security_group" "Public-sg" {
  name        = "ALl allow"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.terraform-vpc

  tags = {
    Name = "All Allow"
  }
}

resource "aws_vpc_security_group_ingress_rule" "SSH" {
  security_group_id = aws_security_group.Public-sg
  cidr_ipv4         = ["0.0.0.0/0"]
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "HTTP" {
  security_group_id = aws_security_group.Public-sg
  cidr_ipv4         = ["0.0.0.0/0"]
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}



resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.Public-sg
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#private sg 
resource "aws_security_group" "Private-sg" {
  name        = "SSH allow"
  description = "Allow SSH "
  vpc_id      = aws_vpc.terraform-vpc

  tags = {
    Name = "SSH allow"
  }
}


resource "aws_vpc_security_group_ingress_rule" "SSH" {
  security_group_id = aws_security_group.Private-sg
  cidr_ipv4         = ["11.11.1.0/24"]
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}




resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.Private-sg
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#instance


resource "aws_instance" "Public-ec2" {
  ami           = 
  instance_type = "t3.micro"
  subnet_id = aws_subnet.Public-sub
  key_name = "terraform-keypair"
  depends_on = [ aws_vpc.terraform-vpc ]
  user_data =file("bin.txt")

  tags = {
    Name = "Public-ec2"
  }
}


resource "aws_instance" "Private-ec2" {
  ami           = 
  instance_type = "t3.micro"
  subnet_id = aws_subnet.Private-sub
  key_name = "terraform-keypair"
  depends_on = [ aws_vpc.terraform-vpc ]
  

  tags = {
    Name = "Private-ec2"
  }
}






