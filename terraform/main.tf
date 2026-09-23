provider "aws" { region = var.region }

# DATA SOURCE — always resolve the newest Ubuntu 22.04 image.
# Hardcoding an AMI id breaks in another region and rots over time.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]   # Canonical's official account
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" { default = true }

# RESOURCE — upload the PUBLIC half of your keypair.
# The private key never leaves your laptop.
resource "aws_key_pair" "deployer" {
  key_name   = "cloud1"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "web" {
  name        = "cloud1-web"
  description = "SSH from admin only; HTTP/HTTPS public"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
  
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "web" {
  count                  = var.instance_count   # >1 satisfies "deploy in parallel"
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
    encrypted   = true        # encryption at rest, free, no reason not to
  }

  tags = { Name = "cloud1-${count.index}", Project = "cloud-1" }
}

# A static IP so your DNS record and inventory don't break on stop/start.
resource "aws_eip" "web" {
  count    = var.instance_count
  instance = aws_instance.web[count.index].id
  domain   = "vpc"
}