# Managed AWS VPN endpoint in eu-north-1, attached to VPC-A.
resource "aws_vpn_gateway" "cloud" {
  provider        = aws.cloud
  vpc_id          = aws_vpc.cloud.id
  amazon_side_asn = 64512
  tags            = { Name = "${var.project_name}-cloud-vgw" }
}

# An Elastic IP on EC2 in us-east-1 acts as the simulated datacenter edge.
resource "aws_customer_gateway" "router" {
  provider   = aws.cloud
  bgp_asn    = 65000 # Required CGW metadata; this example uses static routes.
  ip_address = aws_eip.router.public_ip
  type       = "ipsec.1"
  tags       = { Name = "${var.project_name}-customer-gateway" }
}

resource "aws_vpn_connection" "s2s" {
  provider            = aws.cloud
  type                = "ipsec.1"
  vpn_gateway_id      = aws_vpn_gateway.cloud.id
  customer_gateway_id = aws_customer_gateway.router.id
  static_routes_only  = true

  local_ipv4_network_cidr  = var.onprem_vpc_cidr # Customer gateway side.
  remote_ipv4_network_cidr = var.cloud_vpc_cidr  # AWS side.

  # Match these IKEv2 proposals on the Libreswan side.
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = { Name = "${var.project_name}-site-to-site-vpn" }
}

resource "aws_vpn_connection_route" "onprem_to_cloud" {
  provider               = aws.cloud
  vpn_connection_id      = aws_vpn_connection.s2s.id
  destination_cidr_block = var.onprem_vpc_cidr
}

# Propagate the static VPN route 10.200.0.0/16 into cloud private subnet RT.
resource "aws_vpn_gateway_route_propagation" "cloud_private" {
  provider       = aws.cloud
  vpn_gateway_id = aws_vpn_gateway.cloud.id
  route_table_id = aws_route_table.cloud_private.id
  depends_on     = [aws_vpn_connection_route.onprem_to_cloud]
}
