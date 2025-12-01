output "network_name" {
  description = "Nombre de la VPC creada"
  value       = google_compute_network.vpc.name
}

output "public_subnet" {
  description = "Subred pública"
  value       = google_compute_subnetwork.public_subnet.ip_cidr_range
}

output "private_subnet" {
  description = "Subred privada"
  value       = google_compute_subnetwork.private_subnet.ip_cidr_range
}

output "web_vm_internal_ip" {
  description = "IP interna de la VM web"
  value       = google_compute_instance.web_vm.network_interface[0].network_ip
}

output "db_vm_internal_ip" {
  description = "IP interna de la VM de base de datos"
  value       = google_compute_instance.db_vm.network_interface[0].network_ip
}
