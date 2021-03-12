output mgmtPublicIP {
  value = google_compute_instance.f5vm01.network_interface[0].access_config[0].nat_ip
}
output mgmtPort {
  description = "Mgmt Port"
  value       = local.total_nics > 1 ? "443" : "8443"
}
output f5_username {
  value = var.f5_username
}
output bigip_password {
  value = (var.f5_password == "") ? (var.gcp_secret_manager_authentication ? data.google_secret_manager_secret_version.secret[0].secret_data : random_string.password.result) : var.f5_password
}
output public_addresses {
  value = [google_compute_instance.f5vm01.network_interface[*].access_config[*].nat_ip]
}
output private_addresses {
  value = [google_compute_instance.f5vm01.network_interface[*].network_ip]
}

output service_account {
  value = google_service_account.sa.email
}