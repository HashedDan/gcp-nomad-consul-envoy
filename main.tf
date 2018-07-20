provider "google" {
  project = "${var.gcp_project}"
  region  = "${var.gcp_region}"
}

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD SERVER NODES
# Note that we use the consul-cluster module to deploy both the Nomad and Consul nodes on the same servers
# ---------------------------------------------------------------------------------------------------------------------

module "servers" {
  source = "modules/server-cluster"

  gcp_zone = "${var.gcp_zone}"

  cluster_name     = "${var.server_cluster_name}"
  cluster_size     = "${var.server_cluster_size}"
  cluster_tag_name = "${var.server_cluster_name}"
  machine_type     = "${var.server_cluster_machine_type}"

  source_image   = "${var.server_source_image}"
  startup_script = "${data.template_file.startup_script_server.rendered}"

  # WARNING!
  # In a production setting, we strongly recommend only launching a Nomad/Consul Server cluster as private nodes.
  # Note that the only way to reach private nodes via SSH is to first SSH into another node that is not private.
  assign_public_ip_addresses = true

  # To enable external access to the Nomad Cluster, enter the approved CIDR Blocks below.
  allowed_inbound_cidr_blocks_http_api = ["0.0.0.0/0"]

  # Enable the Nomad clients to reach the Nomad/Consul Server Cluster
  allowed_inbound_tags_http_api = ["${var.client_cluster_name}"]
  allowed_inbound_tags_dns      = ["${var.client_cluster_name}"]
}

# Enable Firewall Rules to open up Nomad-specific ports
module "firewall_rules" {
  source = "modules/nomad-firewall-rules"

  gcp_zone         = "${var.gcp_zone}"
  cluster_name     = "${var.server_cluster_name}"
  cluster_tag_name = "${var.server_cluster_name}"

  http_port = 4646
  rpc_port  = 4647
  serf_port = 4648

  allowed_inbound_cidr_blocks_http = ["0.0.0.0/0"]
}

# Render the Startup Script that will run on each Nomad Instance on boot. This script will configure and start Nomad.
data "template_file" "startup_script_server" {
  template = "${file("${path.module}/scripts/startup-script-server.sh")}"

  vars {
    num_servers             = "${var.server_cluster_size}"
    server_cluster_tag_name = "${var.server_cluster_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD CLIENT NODES
# ---------------------------------------------------------------------------------------------------------------------

module "clients" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-google-nomad.git//modules/nomad-cluster?ref=v0.0.1"
  source = "modules/nomad-cluster"

  gcp_zone = "${var.gcp_zone}"

  cluster_name     = "${var.client_cluster_name}"
  cluster_size     = "${var.client_cluster_size}"
  cluster_tag_name = "${var.client_cluster_name}"
  machine_type     = "${var.client_machine_type}"

  source_image   = "${var.client_source_image}"
  startup_script = "${data.template_file.startup_script_client.rendered}"

  # We strongly recommend setting this to "false" in a production setting. Your Nomad cluster has no reason to be
  # publicly accessible! However, for testing and demo purposes, it is more convenient to launch a publicly accessible
  # Nomad cluster.
  assign_public_ip_addresses = true

  # These inbound clients need only receive requests from Nomad Server and Consul
  allowed_inbound_cidr_blocks_http = []
  allowed_inbound_tags_http        = ["${var.server_cluster_name}"]
  allowed_inbound_tags_rpc         = ["${var.server_cluster_name}"]
  allowed_inbound_tags_serf        = ["${var.server_cluster_name}"]
}

# Render the Startup Script that will configure and run both Consul and Nomad in client mode.
data "template_file" "startup_script_client" {
  template = "${file("${path.module}/scripts/startup-script-client.sh")}"

  vars {
    server_cluster_tag_name = "${var.server_cluster_name}"
  }
}
