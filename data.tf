data "aws_availability_zones" "onprem" {
  provider = aws.onprem
  state    = "available"
}

data "aws_availability_zones" "cloud" {
  provider = aws.cloud
  state    = "available"
}

# Region-specific, up-to-date Amazon Linux 2023 x86-64 AMIs.
data "aws_ssm_parameter" "onprem_al2023_ami" {
  provider = aws.onprem
  name     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "cloud_al2023_ami" {
  provider = aws.cloud
  name     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
