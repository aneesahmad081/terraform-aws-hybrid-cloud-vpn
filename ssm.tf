# PSKs are created by AWS and copied into SecureString parameters in us-east-1.
# IMPORTANT: VPN resource PSKs AND SecureString values can still exist in
# terraform.tfstate; treat the state as sensitive, do not commit or share it.
resource "aws_ssm_parameter" "tunnel1_psk" {
  provider    = aws.onprem
  name        = "/${var.project_name}/vpn/tunnel1-psk"
  description = "Lab Tunnel 1 PSK; do not disclose or export to Git"
  type        = "SecureString"
  value       = aws_vpn_connection.s2s.tunnel1_preshared_key
  tags        = { Name = "${var.project_name}-tunnel1-psk" }
}

resource "aws_ssm_parameter" "tunnel2_psk" {
  provider    = aws.onprem
  name        = "/${var.project_name}/vpn/tunnel2-psk"
  description = "Lab Tunnel 2 PSK; do not disclose or export to Git"
  type        = "SecureString"
  value       = aws_vpn_connection.s2s.tunnel2_preshared_key
  tags        = { Name = "${var.project_name}-tunnel2-psk" }
}

# SSM runs a generated, idempotent shell script on the EC2 router AFTER VPN
# and secret parameters exist. Avoids the EC2<->VPN user_data dependency cycle.
resource "aws_ssm_association" "configure_router" {
  provider         = aws.onprem
  association_name = "${var.project_name}-configure-libreswan"
  name             = "AWS-RunShellScript"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.router.id]
  }

  parameters = {
    commands = templatefile("${path.module}/templates/configure-libreswan.sh.tftpl", {
      region          = "us-east-1"
      tunnel1_psk_ssm = aws_ssm_parameter.tunnel1_psk.name
      tunnel2_psk_ssm = aws_ssm_parameter.tunnel2_psk.name
      tunnel1_ip      = aws_vpn_connection.s2s.tunnel1_address
      tunnel2_ip      = aws_vpn_connection.s2s.tunnel2_address
      router_eip      = aws_eip.router.public_ip
      onprem_cidr     = var.onprem_vpc_cidr
      cloud_cidr      = var.cloud_vpc_cidr
    })
    executionTimeout = "3600"
  }

  # SSM Agent / package installations may need a little time to start on boot.
  wait_for_success_timeout_seconds = 900

  depends_on = [
    aws_eip.router,
    aws_route.onprem_internet,
    aws_iam_role_policy.router_read_psks,
    aws_iam_role_policy_attachment.router_ssm_core,
    aws_vpc_security_group_ingress_rule.router_ike,
    aws_vpc_security_group_ingress_rule.router_natt,
    aws_vpn_gateway_route_propagation.cloud_private
  ]
}
