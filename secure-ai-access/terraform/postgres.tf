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

resource "aws_eip" "postgres_eip" {
  domain   = "vpc"
  instance = aws_instance.postgres.id
  
  tags = {
    Name = "${var.demo_tag_prefix}-postgres-eip"
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

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl enable --now docker
              
              docker run -d \
                --name company-db \
                -e POSTGRES_PASSWORD=your_secure_password \
                -p 5432:5432 \
                --restart always \
                assafhazan/postgres-companydb:17-alpine
              EOF

  tags = {
    Name = "${var.demo_tag_prefix}-postgres"
  }

  lifecycle {
    ignore_changes = [
      tags,
      tags_all,
      root_block_device[0].tags,
    ]
  }
}