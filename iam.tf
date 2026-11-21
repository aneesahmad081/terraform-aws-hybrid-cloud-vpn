data "aws_iam_policy_document" "ec2_assume_role" {
  provider = aws.onprem
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "router" {
  provider           = aws.onprem
  name               = "${var.project_name}-router-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "router_ssm_core" {
  provider   = aws.onprem
  role       = aws_iam_role.router.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "router" {
  provider = aws.onprem
  name     = "${var.project_name}-router-profile"
  role     = aws_iam_role.router.name
}

# Instance permission to fetch only the two encrypted lab PSKs from SSM.
# AWS-managed aws/ssm KMS key is used by the SecureString parameters.
resource "aws_iam_role_policy" "router_read_psks" {
  provider = aws.onprem
  name     = "${var.project_name}-read-tunnel-psks"
  role     = aws_iam_role.router.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = [aws_ssm_parameter.tunnel1_psk.arn, aws_ssm_parameter.tunnel2_psk.arn]
    }]
  })
}
