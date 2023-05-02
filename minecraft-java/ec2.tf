resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "this" {
  key_name   = "${local.name}-keypair"
  public_key = tls_private_key.this.public_key_openssh

  tags = merge(local.default_tags, {
    Name = "${local.name}-keypair"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20210623"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "server_properties" {
  template = file("${path.module}/templates/server.properties")

  vars = {
    mc_port = var.port
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/ubuntu_user_data.sh")

  vars = {
    mc_bucket         = module.s3.s3_bucket_id
    mc_backup_freq    = 60 #minutes
    mc_version        = "latest"
    mc_type           = "release"
    java_mx_mem       = "2G"
    java_ms_mem       = "2G"
    server_properties = data.template_file.server_properties.rendered
  }
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name   = local.name

  # instance
  key_name             = aws_key_pair.this.key_name
  ami                  = data.aws_ami.ubuntu.image_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.minecraft.id
  user_data            = data.template_file.user_data.rendered

  # network
  subnet_id                   = aws_subnet.this.id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = true

  tags = merge(local.default_tags, {
    Name = "${local.name}-ec2"
  })
}

resource "aws_eip" "this" {
  vpc = true

  tags = merge(local.default_tags, {
    Name = "${local.name}-eip"
  })
}

resource "aws_eip_association" "this" {
  allocation_id = aws_eip.this.id
  instance_id   = module.ec2.id
}
