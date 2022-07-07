terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.64"
    }
  }
}

provider "aws" {
  region     = "eu-west-1"
  access_key = "AKIAQFWWW3BY2JLF2PXP"
  secret_key = "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"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "my_ig" {
  vpc_id = aws_vpc.my_vpc.id
}


resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_ig.id
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = "eu-west-1a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Projet = "DevOps"
  }
}

resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}


resource "aws_security_group" "my_security_group" {
  name_prefix = "AKIAQFWWW3BY757JOLEQ"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Projet = "DevOps"
  }
}

resource "aws_security_group_rule" "my_security_group_rule_out_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
}


resource "aws_security_group_rule" "my_security_group_rule_out_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
}

resource "aws_security_group_rule" "my_security_group_rule_out_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
}


resource "aws_security_group_rule" "my_security_group_rule_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
}

resource "aws_security_group_rule" "my_security_group_rule_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
}


resource "aws_security_group_rule" "my_security_group_rule_port" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
}



# Get latest Ubuntu Linux Bionic Beaver 18.04 AMI
data "aws_ami" "ubuntu-linux-1804" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "my_instance" {
  ami                         = data.aws_ami.ubuntu-linux-1804.id
  subnet_id                   = aws_subnet.my_subnet.id
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.my_security_group.id]
  key_name                    = aws_key_pair.ssh_public_key.key_name
}

resource "aws_key_pair" "ssh_public_key" {
  key_name   = "ssh_public_key"
  public_key = var.ssh_public_key
}

resource "local_file" "my_ansible_inv" {
  content  = <<EOF
[webserver]
${aws_instance.my_instance.public_ip}
EOF
  filename = "./inventories/inv.ini"
}

output "ip" {
  value = aws_instance.my_instance.public_ip
}
