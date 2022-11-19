resource "google_compute_global_address" "kube_api" {
  name = format("%s-kube-api", var.name_prefix)
}

resource "google_compute_global_forwarding_rule" "kube_api" {
  name                  = format("%s-kube-api", var.name_prefix)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = 6443
  target                = google_compute_target_tcp_proxy.kube_api.id
  ip_address            = google_compute_global_address.kube_api.id
}

resource "google_compute_target_tcp_proxy" "kube_api" {
  name            = format("%s-kube-api", var.name_prefix)
  backend_service = google_compute_backend_service.kube_api.id
}

resource "google_compute_backend_service" "kube_api" {
  name                  = format("%s-kube-api", var.name_prefix)
  protocol              = "TCP"
  port_name             = "kube-api"
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_health_check.kube_api.id]

  backend {
    group          = google_compute_instance_group.master.self_link
    balancing_mode = "UTILIZATION"
  }
}

resource "google_compute_health_check" "kube_api" {
  name               = format("%s-kube-api", var.name_prefix)
  check_interval_sec = 10
  timeout_sec        = 5

  tcp_health_check {
    port = 6443
  }
}
