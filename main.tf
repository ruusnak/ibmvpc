resource "random_id" "name1" {
  byte_length = 2
}

resource "random_id" "name2" {
  byte_length = 2
}

locals {
     ZONE1     = "${var.region}-1"
     ZONE2     = "${var.region}-2"
   }

resource "ibm_is_vpc" "vpc1" {
  name = "vpc-${random_id.name1.hex}"
}

resource "ibm_is_subnet" "subnet1" {
  name            = "subnet-vpc-${random_id.name1.hex}"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${local.ZONE1}"
  total_ipv4_address_count = 256

  provisioner "local-exec" {
    command = "sleep 300"
    when    = "destroy"
  }
}

resource "ibm_is_vpn_gateway" "VPNGateway1" {
  name   = "vpn-${random_id.name1.hex}"
  subnet = "${ibm_is_subnet.subnet1.id}"
}

#resource "ibm_is_vpn_gateway_connection" "VPNGatewayConnection1" {
#  name          = "vpnconn-${random_id.name1.hex}"
#  vpn_gateway   = "${ibm_is_vpn_gateway.VPNGateway1.id}"
#  peer_address  = "${ibm_is_vpn_gateway.VPNGateway1.public_ip_address}"
#  preshared_key = "VPNDemoPassword"
#  local_cidrs   = ["${ibm_is_subnet.subnet1.ipv4_cidr_block}"]
#  ipsec_policy  = "${ibm_is_ipsec_policy.example.id}"
#}

resource "ibm_is_ssh_key" "sshkey_vpc" {
  name       = "${var.ssh_key_name}-${random_id.name1.hex}"
  public_key = "${var.ssh_public_key}"
}

resource "ibm_is_instance" "instance1" {
  name    = "instance-${random_id.name1.hex}"
  image   = "cfdaf1a0-5350-4350-fcbc-97173b510843"
  profile = "${var.profile}"

  primary_network_interface = {
#    port_speed = "1000"
    subnet     = "${ibm_is_subnet.subnet1.id}"
  }

  vpc       = "${ibm_is_vpc.vpc1.id}"
  zone      = "${local.ZONE1}"
  keys      = ["${ibm_is_ssh_key.sshkey_vpc.id}"]
#  user_data = "${file("nginx.sh")}"
}

resource "ibm_is_floating_ip" "floatingip1" {
  name   = "fip-${random_id.name1.hex}"
  target = "${ibm_is_instance.instance1.primary_network_interface.0.id}"
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip1"]
  group      = "${ibm_is_vpc.vpc1.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg1_icmp_rule" {
  depends_on = ["ibm_is_floating_ip.floatingip1"]
  group      = "${ibm_is_vpc.vpc1.default_security_group}"
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  icmp = {
    code = 0
    type = 8
  }
}

resource "ibm_is_ipsec_policy" "example" {
  name                     = "test-ipsec-${random_id.name2.hex}"
  authentication_algorithm = "md5"
  encryption_algorithm     = "3des"
  pfs                      = "disabled"
}

resource "ibm_is_ike_policy" "example" {
  name                     = "test-ike-${random_id.name2.hex}"
  authentication_algorithm = "md5"
  encryption_algorithm     = "3des"
  dh_group                 = 2
  ike_version              = 1
}
