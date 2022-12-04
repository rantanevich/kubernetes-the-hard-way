data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

resource "google_compute_firewall" "iap_ssh" {
  name    = format("%s-iap-ssh", var.name_prefix)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4
}

resource "google_compute_firewall" "health_checkers" {
  name    = format("%s-health-checkers", var.name_prefix)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4
  target_tags   = [format("%s-master", var.name_prefix)]
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
