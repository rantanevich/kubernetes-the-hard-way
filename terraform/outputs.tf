output "api_ipv4" {
  value = google_compute_global_address.kube_api.address
}

output "masters_hostname" {
  value = [for i in google_compute_instance.master : i.name]
}

output "masters_ipv4" {
  value = google_compute_instance.master[*].network_interface[0].network_ip
}

output "workers_hostname" {
  value = [for i in google_compute_instance.worker : i.name]
}

output "workers_ipv4" {
  value = google_compute_instance.worker[*].network_interface[0].network_ip
}

output "workers_public_ipv4" {
  value = google_compute_address.worker[*].address
}
