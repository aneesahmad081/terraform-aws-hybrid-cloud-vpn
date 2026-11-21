resource "aws_instance" "router" {
  provider                    = aws.onprem
  ami                         = data.aws_ssm_parameter.onprem_al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.onprem_public.id
  private_ip                  = var.router_private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.router.id]
  iam_instance_profile        = aws_iam_instance_profile.router.name
  source_dest_check           = false # Required if EC2 routes traffic for other hosts.
  user_data                   = file("${path.module}/templates/router-userdata.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 12
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-libreswan-router-us-east-1" }

  depends_on = [
    aws_route_table_association.onprem_public,
    aws_route.onprem_internet,
    aws_iam_role_policy_attachment.router_ssm_core
  ]
}

resource "aws_eip" "router" {
  provider   = aws.onprem
  domain     = "vpc"
  instance   = aws_instance.router.id
  tags       = { Name = "${var.project_name}-router-eip" }
  depends_on = [aws_internet_gateway.onprem]
}

resource "aws_instance" "cloud_server" {
  provider                    = aws.cloud
  ami                         = data.aws_ssm_parameter.cloud_al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.cloud_private.id
  private_ip                  = var.cloud_server_private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.cloud.id]
  user_data                   = file("${path.module}/templates/private-userdata.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-private-web-eu-north-1" }

  depends_on = [aws_route_table_association.cloud_private]
}
