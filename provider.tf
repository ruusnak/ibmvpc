

provider "ibm" {
  ibmcloud_timeout = 300
  iaas_classic_username = "${var.slusername}"
  ibmcloud_api_key = "${var.slapikey}"
  generation = "1"
  region = "eu-de"
  resource_group = "test"
}
