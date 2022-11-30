data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

resource "google_compute_firewall" "external" {
  name    = format("%s-external", var.name_prefix)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = concat(
    data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4,
    data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4,
  )
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
}
