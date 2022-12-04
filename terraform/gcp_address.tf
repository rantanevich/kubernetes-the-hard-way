resource "google_compute_global_address" "kube_api" {
  name = format("%s-kube-api", var.name_prefix)
}

resource "google_compute_global_address" "worker" {
  count = var.worker_nodes

  name = format("%s-worker-%d", var.name_prefix, count.index)
}
