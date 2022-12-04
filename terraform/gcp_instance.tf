resource "google_compute_instance" "master" {
  count = var.master_nodes

  name           = format("%s-master-%d", var.name_prefix, count.index)
  machine_type   = var.machine_type
  zone           = data.google_compute_zones.available.names[0]
  can_ip_forward = true

  tags = ["kubernetes", format("%s-master", var.name_prefix)]

  boot_disk {
    auto_delete = true

    initialize_params {
      size  = 100
      type  = "pd-standard"
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.name
    network_ip = format(var.master_network_ip_template, count.index)
  }

  service_account {
    email  = google_service_account.kubernetes.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = file("./userdata/startup.sh")
}

resource "google_compute_instance" "worker" {
  count = var.worker_nodes

  name           = format("%s-worker-%d", var.name_prefix, count.index)
  machine_type   = var.machine_type
  zone           = data.google_compute_zones.available.names[0]
  can_ip_forward = true

  tags = ["kubernetes", format("%s-worker", var.name_prefix)]

  boot_disk {
    auto_delete = true

    initialize_params {
      size  = 100
      type  = "pd-standard"
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.name
    network_ip = format(var.worker_network_ip_template, count.index)

    access_config {
      nat_ip = google_compute_global_address.worker[count.index].address
    }
  }

  service_account {
    email  = google_service_account.kubernetes.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    pods-network = format(var.pods_network_template, count.index)
  }

  metadata_startup_script = file("./userdata/startup.sh")
}

resource "google_compute_instance_group" "master" {
  name      = format("%s-master", var.name_prefix)
  zone      = data.google_compute_zones.available.names[0]
  instances = google_compute_instance.master.*.id

  named_port {
    name = "kube-api"
    port = 6443
  }
}

resource "google_compute_instance_group" "worker" {
  name      = format("%s-worker", var.name_prefix)
  zone      = data.google_compute_zones.available.names[0]
  instances = google_compute_instance.worker.*.id
}
