# Use modern stand-alone SG rules so the rules can depend on tunnel endpoints
# without forming a dependency cycle with EC2/EIP/VPN creation.
resource "aws_security_group" "router" {
  provider    = aws.onprem
  name        = "${var.project_name}-router-sg"
  description = "Allow VPN IKE, NAT-T, ESP from only AWS tunnel peers"
  vpc_id      = aws_vpc.onprem.id
  tags        = { Name = "${var.project_name}-router-sg" }
}

resource "aws_vpc_security_group_egress_rule" "router_all_outbound" {
  provider          = aws.onprem
  security_group_id = aws_security_group.router.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Lab router needs AWS SSM and VPN egress"
}

resource "aws_security_group" "cloud" {
  provider    = aws.cloud
  name        = "${var.project_name}-private-sg"
  description = "Allow ping and test HTTP over the VPN from onprem CIDR"
  vpc_id      = aws_vpc.cloud.id
  tags        = { Name = "${var.project_name}-cloud-private-sg" }
}

resource "aws_vpc_security_group_egress_rule" "cloud_all_outbound" {
  provider          = aws.cloud
  security_group_id = aws_security_group.cloud.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Lab outbound; subnet itself has no Internet route"
}

resource "aws_vpc_security_group_ingress_rule" "cloud_ping" {
  provider          = aws.cloud
  security_group_id = aws_security_group.cloud.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = var.onprem_vpc_cidr
  description       = "ICMP from simulated onprem CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "cloud_http" {
  provider          = aws.cloud
  security_group_id = aws_security_group.cloud.id
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.onprem_vpc_cidr
  description       = "Private HTTP lab endpoint on 8080"
}

resource "aws_vpc_security_group_ingress_rule" "router_ping" {
  provider          = aws.onprem
  security_group_id = aws_security_group.router.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = var.cloud_vpc_cidr
  description       = "ICMP from AWS cloud side over VPN"
}

# The map keys are known at plan time, while public tunnel IP values become
# known at apply time. This avoids for_each 'unknown keys' errors.
locals {
  vpn_tunnel_peers = {
    tunnel1 = aws_vpn_connection.s2s.tunnel1_address
    tunnel2 = aws_vpn_connection.s2s.tunnel2_address
  }
}

resource "aws_vpc_security_group_ingress_rule" "router_ike" {
  provider          = aws.onprem
  for_each          = local.vpn_tunnel_peers
  security_group_id = aws_security_group.router.id
  ip_protocol       = "udp"
  from_port         = 500
  to_port           = 500
  cidr_ipv4         = "${each.value}/32"
  description       = "IKE UDP 500 from ${each.key}"
}

resource "aws_vpc_security_group_ingress_rule" "router_natt" {
  provider          = aws.onprem
  for_each          = local.vpn_tunnel_peers
  security_group_id = aws_security_group.router.id
  ip_protocol       = "udp"
  from_port         = 4500
  to_port           = 4500
  cidr_ipv4         = "${each.value}/32"
  description       = "NAT-T UDP 4500 from ${each.key}"
}

resource "aws_vpc_security_group_ingress_rule" "router_esp" {
  provider          = aws.onprem
  for_each          = local.vpn_tunnel_peers
  security_group_id = aws_security_group.router.id
  ip_protocol       = "50" # ESP; most EC2+EIP setups use UDP 4500 encapsulation.
  cidr_ipv4         = "${each.value}/32"
  description       = "ESP IP protocol 50 from ${each.key}"
}
