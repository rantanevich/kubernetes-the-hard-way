data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

resource "google_compute_firewall" "kube_api" {
  name    = format("%s-kube-api", var.name_prefix)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = concat(
    data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4,
    data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4,
  )

  target_tags = [format("%s-master", var.name_prefix)]
}

resource "google_compute_firewall" "internal" {
  name    = format("%s-internal", var.name_prefix)
  network = google_compute_network.main.name

  dynamic "allow" {
    for_each = ["tcp", "udp", "icmp"]

    content {
      protocol = allow.value
    }
  }

  source_tags = ["kubernetes"]
  target_tags = ["kubernetes"]
}

resource "google_compute_firewall" "worker_nodeport" {
  name    = format("%s-worker-nodeport", var.name_prefix)
  network = google_compute_network.main.name

  dynamic "allow" {
    for_each = ["tcp", "udp", "sctp"]

    content {
      protocol = allow.value
      ports    = ["30000-32767"]
    }
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [format("%s-worker", var.name_prefix)]
}
