resource "aws_vpc" "minecraft_ec2_launcher" {
  tags       = merge(local.tf_global_tags, local.project_name_tag)
  cidr_block = "10.2.0.0/16"
}

# imported, I think this was created automatically with the VPC...
# https://www.terraform.io/docs/providers/aws/r/route_table.html
# "Note that the default route, mapping the VPC's CIDR block to "local", is created implicitly and cannot be specified."
resource "aws_route_table" "minecraft_ec2_launcher" {
  tags   = merge(local.tf_global_tags, local.project_name_tag)
  vpc_id = aws_vpc.minecraft_ec2_launcher.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_ec2_launcher.id
  }
}

resource "aws_subnet" "minecraft_subnet_e1a" {
  tags              = merge(local.tf_global_tags, local.project_name_tag)
  vpc_id            = aws_vpc.minecraft_ec2_launcher.id
  cidr_block        = "10.2.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "minecraft_subnet_e1b" {
  tags              = merge(local.tf_global_tags, local.project_name_tag)
  vpc_id            = aws_vpc.minecraft_ec2_launcher.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "minecraft_ec2_launcher" {
  tags   = merge(local.tf_global_tags, local.project_name_tag)
  vpc_id = aws_vpc.minecraft_ec2_launcher.id
}

resource "aws_security_group" "minecraft_ec2_instance" {
  tags        = merge(local.tf_global_tags, local.project_name_tag)
  name        = "minecraft_ec2_instance"
  description = "rules for minecraft ec2 instance"
  vpc_id      = aws_vpc.minecraft_ec2_launcher.id

  ingress {
    description = "Minecraft Clients"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS over VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.minecraft_ec2_launcher.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "NFS over VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.minecraft_ec2_launcher.cidr_block]
  }

  # Created by aws, but removed by tf by default (security). Needs added manually.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_efs_file_system" "cincicraft" {
  file_system_id = "fs-dbe70e5a"
}

output "minecraft_subnet_e1a_id" {
  value = aws_subnet.minecraft_subnet_e1a.id
}

output "minecraft_subnet_e1b_id" {
  value = aws_subnet.minecraft_subnet_e1b.id
}

resource "aws_launch_template" "minecraft_ec2_launcher" {
  tags       = merge(local.tf_global_tags, local.project_name_tag)
  name = "minecraft_ec2_launcher"
  image_id = "ami-0b3a9e69eed330e50" # TODO: Replace with data resource if possible
  instance_type = "c5.xlarge"
  key_name = "ec2-c5-minecraft-1" # TODO: Replace with data resource if possible
  instance_initiated_shutdown_behavior = "terminate"
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
      instance_interruption_behavior = "terminate"
      #block_duration_minutes = 240 # TODO: experimental, how much more expensive is this?
    }
  }
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = ["sg-0b7bda22c5bdd763c"]  # TODO: Replace with new vpc data resource
    subnet_id = "subnet-02a15fd16de359f31" # TODO: replace with new vpc data resource
  }
  ebs_optimized = true
  # TODO: Is this block device used? Why do I have a snapshot_id and an image_id...
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp2"
      delete_on_termination = "true"
      snapshot_id = "snap-08f211225913672c4" # TODO: replace with data resource if possible
    }
  }
}
