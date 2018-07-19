output "gcp_project" {
  value = "${var.gcp_project}"
}

output "gcp_zone" {
  value = "${var.gcp_zone}"
}

output "server_cluster_size" {
  value = "${var.server_cluster_size}"
}

output "client_cluster_size" {
  value = "${var.client_cluster_size}"
}

output "server_cluster_tag_name" {
  value = "${var.server_cluster_name}"
}

output "client_cluster_tag_name" {
  value = "${var.client_cluster_name}"
}

output "server_instance_group_id" {
  value = "${module.servers.instance_group_name}"
}

output "server_instance_group_url" {
  value = "${module.servers.instance_group_url}"
}

output "client_instance_group_id" {
  value = "${module.clients.instance_group_id}"
}

output "client_instance_group_url" {
  value = "${module.clients.instance_group_url}"
}
