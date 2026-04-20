data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_instance" "postgres" {
  ami                    = data.aws_ami.al2023_arm.id
  instance_type          = "t4g.small"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name != "" ? var.key_name : null

  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.demo_tag_prefix}-postgres"
  }

  lifecycle {
    ignore_changes = [
      tags,
      tags_all,
      user_data,
      root_block_device[0].tags,
    ]
  }
}
