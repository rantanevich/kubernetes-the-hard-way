data "google_compute_zones" "available" {}

resource "google_compute_network" "main" {
  name                            = format("%s-vpc", var.name_prefix)
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "main" {
  name          = format("%s-subnet", var.name_prefix)
  network       = google_compute_network.main.name
  ip_cidr_range = var.subnet_cidr
}

resource "google_compute_router" "main" {
  name    = format("%s-router", var.name_prefix)
  network = google_compute_network.main.name
}

resource "google_compute_router_nat" "main" {
  name                               = format("%s-nat", var.name_prefix)
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_route" "kubernetes" {
  count = var.worker_nodes

  name        = format("worker-%d-pods", count.index)
  dest_range  = format(var.pods_network_template, count.index)
  next_hop_ip = google_compute_instance.worker[count.index].network_interface[0].network_ip
  network     = google_compute_network.main.name
  priority    = 100
}
