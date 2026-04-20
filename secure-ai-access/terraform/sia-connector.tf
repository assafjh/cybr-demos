data "aws_ami" "al2023_x86" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "sia_connector" {
  ami                    = data.aws_ami.al2023_x86.id
  instance_type          = "t3.small"
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
    Name = "${var.demo_tag_prefix}-sia-connector"
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
