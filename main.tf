provider "aws" {
  region = "us-east-1"
}
 
# Create VPC
resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
 
# Subnets
resource "aws_subnet" "medusa_subnet_1" {
  vpc_id                  = aws_vpc.medusa_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
 
resource "aws_subnet" "medusa_subnet_2" {
  vpc_id                  = aws_vpc.medusa_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
}
 
# Internet Gateway
resource "aws_internet_gateway" "medusa_igw" {
  vpc_id = aws_vpc.medusa_vpc.id
}
 
# Route Table
resource "aws_route_table" "medusa_rt" {
  vpc_id = aws_vpc.medusa_vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.medusa_igw.id
  }
}
 
# Route Table Associations
resource "aws_route_table_association" "medusa_rta_1" {
  subnet_id      = aws_subnet.medusa_subnet_1.id
  route_table_id = aws_route_table.medusa_rt.id
}
 
resource "aws_route_table_association" "medusa_rta_2" {
  subnet_id      = aws_subnet.medusa_subnet_2.id
  route_table_id = aws_route_table.medusa_rt.id
}
 
# Security Group
resource "aws_security_group" "medusa_sg" {
  name        = "medusa-sg"
  description = "Allow SSH and PostgreSQL"
  vpc_id      = aws_vpc.medusa_vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# Key Pair
resource "aws_key_pair" "medusa_key" {
  key_name   = "medusa-key"
  public_key =  <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCn/BDX485MNO0IxsaeMEzBQfkUODaxGdqob3jpfluWnMsOsHTKbiJP+1/nUuLvfhlAz2wJVLD69RtJHPvr8OxbzITDia1KLB5dMCydKbhacYUUjs2i+Qlahz4B0QPM1PrGtXmSw6VzyY3MprrPeaYZPu5t9SAH34YOxYQQFlajkUrfHxT4f294250wt8lHvzWEl+7d+FRvV6VQ8Owa1MsWlGD8Vy+APADw8Ra1o0+Ate/qjLbTDAjmY1nQfsjewOSXHSmc1p96IJdoR2cyq7qlD3gnzT7X7l43Z6raEk+ERkAbixFd1X7iaASsCfThsNSVDWWo6+qV4bkXHN6aU+TmGl5DIb42jppPhyZDAJiLi1BOTw9ZiE4Uvr6axZtpLklkSkUotzU2lDxgAAdGMSJARf1mY0xL4r4hs0CUBM8upqwwj9Lg20SRkOea0m7Ztk11n28c39HPBRtsfmQlqyP/s7YAfcY0hk7eOpFBK+kZUbUdeuNMA4S2Fw2knkid8l0= root@ip-172-31-80-197.ec2.internal
EOF

}
 
# EC2 instance
resource "aws_instance" "medusa" {
  ami           = "ami-00a929b66ed6e0de6"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.medusa_key.key_name
  subnet_id     = aws_subnet.medusa_subnet_1.id
  vpc_security_group_ids = [aws_security_group.medusa_sg.id]
 
  tags = {
    Name = "medusa-ec2"
  }
}
 
# DB Subnet Group
 resource "aws_db_subnet_group" "medusa_db_subnet" {
  name = "medusa-db-subnet-new" # 
  description = "Subnet group for Medusa RDS instance"
  subnet_ids = [
    aws_subnet.medusa_subnet_1.id,
    aws_subnet.medusa_subnet_2.id
  ]
  tags = {
    Name = "medusa-db-subnet-group"
  }
}
 
# RDS Instance
resource "aws_db_instance" "medusa_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t3.micro"
  db_name              = "medusadb"
  username             = "Sarath"
  password             = "MedusaStrongPassword123"
  publicly_accessible  = true
  skip_final_snapshot  = true
 
  vpc_security_group_ids = [aws_security_group.medusa_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.medusa_db_subnet.name
 
  tags = {
    Name = "medusa-postgres"
  }
}
 
# S3 Bucket
resource "random_id" "bucket_id" {
  byte_length = 4
}
 
resource "aws_s3_bucket" "medusa_bucket" {
  bucket        = "medusa-bucket-${random_id.bucket_id.hex}"
  force_destroy = true
}
 