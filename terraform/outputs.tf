output "kube_api_ipv4" {
  value = google_compute_global_address.kube_api.address
}
