resource "google_service_account" "kubernetes" {
  account_id = format("%s-kubernetes", var.name_prefix)
}

resource "google_project_iam_member" "kubernetes" {
  project = var.google_project
  role    = "roles/compute.viewer"
  member  = format("serviceAccount:%s", google_service_account.kubernetes.email)
}
