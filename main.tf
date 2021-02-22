terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.51.0"
    }
  }
}
#
# Create a random id
#
resource random_id module_id {
  byte_length = 2
}

locals {
  bigip_map = {
    "mgmt_subnet_ids"     = var.mgmt_subnet_ids
    "external_subnet_ids" = var.external_subnet_ids
    "internal_subnet_ids" = var.internal_subnet_ids
  }
  mgmt_public_subnet_id = [
    for subnet in local.bigip_map["mgmt_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  mgmt_private_subnet_id = [
    for subnet in local.bigip_map["mgmt_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  mgmt_public_private_ip_primary = [
    for private in local.bigip_map["mgmt_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == true
  ]
  mgmt_private_ip_primary = [
    for private in local.bigip_map["mgmt_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == false
  ]
  external_public_subnet_id = [
    for subnet in local.bigip_map["external_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  external_private_subnet_id = [
    for subnet in local.bigip_map["external_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  internal_public_subnet_id = [
    for subnet in local.bigip_map["internal_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  internal_private_subnet_id = [
    for subnet in local.bigip_map["internal_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  internal_private_ip_primary = [
    for private in local.bigip_map["internal_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == false
  ]
  external_private_ip_primary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == false
  ]
  external_private_ip_secondary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_secondary"]
    if private["public_ip"] == false
  ]
  external_public_private_ip_primary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == true
  ]
  external_public_private_ip_secondary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_secondary"]
    if private["public_ip"] == true
  ]
  total_nics      = length(concat(local.mgmt_public_subnet_id, local.mgmt_private_subnet_id, local.external_public_subnet_id, local.external_private_subnet_id, local.internal_public_subnet_id, local.internal_private_subnet_id))
  instance_prefix = format("%s-%s", var.prefix, random_id.module_id.hex)
}

resource random_string password {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

resource random_string sa_role {
  length      = 16
  min_lower   = 1
  number      = false
  upper       = false
  special     = false
}

data "template_file" "startup_script" {
  template = file("${path.module}/startup-script.tpl")
  vars = {
    onboard_log                       = var.onboard_log
    libs_dir                          = var.libs_dir
    bigip_username                    = var.f5_username
    gcp_secret_manager_authentication = var.gcp_secret_manager_authentication
    bigip_password                    = (var.f5_password == "") ? (var.gcp_secret_manager_authentication ? var.gcp_secret_name : random_string.password.result) : var.f5_password
  }
}
data "google_secret_manager_secret_version" "secret" {
  count   = var.gcp_secret_manager_authentication ? 1 : 0
  secret  = var.gcp_secret_name
  version = var.gcp_secret_version
}

resource "google_service_account" "sa" {
  account_id   = format("%s", random_string.sa_role.result)
  display_name = format("%s", random_string.sa_role.result)
  description = "Service accounts for GCP IAM authentication"
}

resource "google_project_iam_member" "gcp_role_member_assignment" {
  count   = var.gcp_secret_manager_authentication ? 1 : 0
  project = var.project_id
  role    = format("projects/${var.project_id}/roles/%s",random_string.sa_role.result)
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_custom_role" "gcp_custom_roles" {
  count       = var.gcp_secret_manager_authentication ? 1 : 0
  role_id     = random_string.sa_role.result
  title       = random_string.sa_role.result
  description = "IAM for authentication"
  permissions = ["secretmanager.versions.access"]
}


resource google_compute_address mgmt_public_ip {
  count = length(local.mgmt_public_subnet_id)
  name  = format("%s-mgmt-publicip-%s", var.prefix, random_id.module_id.hex)
}
resource google_compute_address external_public_ip {
  count = length(local.external_public_subnet_id)
  name  = format("%s-ext-publicip-%s-%s", var.prefix, count.index, random_id.module_id.hex)
}

resource google_compute_instance f5vm01 {
  //project = var.project_id
  name = format("%s-f5vm01", local.instance_prefix)
  zone = var.zone
  # Scheduling options
  min_cpu_platform = var.min_cpu_platform
  machine_type     = var.machine_type
  scheduling {
    automatic_restart = var.automatic_restart
    preemptible       = var.preemptible
  }
  boot_disk {
    auto_delete = true
    initialize_params {
      type  = var.disk_type
      size  = var.disk_size_gb
      image = var.image
    }
  }
  service_account {
    email  = google_service_account.sa.email
    scopes = ["cloud-platform"]
  }
  can_ip_forward = true
  #Assign Public IP to Management Nic
  dynamic network_interface {
    for_each = local.mgmt_public_subnet_id
    content {
      subnetwork = network_interface.value
      access_config {
        nat_ip = google_compute_address.mgmt_public_ip[tonumber(network_interface.key)].address
      }
    }
  }
  dynamic network_interface {
    for_each = local.mgmt_private_subnet_id
    content {
      subnetwork = network_interface.value
      network_ip = local.mgmt_private_ip_primary[tonumber(network_interface.key)]
      //network_ip = length(local.mgmt_private_ip_primary) > 0 ? local.mgmt_private_ip_primary[0]: ""
    }
  }

  #Assign Public IP to external Nic
  dynamic network_interface {
    for_each = local.external_public_subnet_id
    content {
      subnetwork = network_interface.value
      access_config {
        nat_ip = google_compute_address.external_public_ip[tonumber(network_interface.key)].address
      }
      alias_ip_range {
        ip_cidr_range = local.external_public_private_ip_secondary[tonumber(network_interface.key)] != "" ? local.external_public_private_ip_secondary[tonumber(network_interface.key)] : "/32"
      }
    }
  }
  #Create External NIC with Private IP Static/Dynamic
  dynamic network_interface {
    for_each = local.external_private_subnet_id
    content {
      subnetwork = network_interface.value
      network_ip = local.external_private_ip_primary[tonumber(network_interface.key)]
      alias_ip_range {
        ip_cidr_range = local.external_private_ip_secondary[tonumber(network_interface.key)] != "" ? local.external_private_ip_secondary[tonumber(network_interface.key)] : "/32"
      }
    }
  }
  dynamic network_interface {
    for_each = local.internal_public_subnet_id
    content {
      subnetwork = network_interface.value
      network_ip = local.internal_public_private_ip_primary[tonumber(network_interface.key)]
      //network_ip = length(local.internal_public_private_ip_primary) > 0 ? local.internal_public_private_ip_primary[0]: ""
      access_config {
      }
    }
  }
  #Create Internal Nic with Dynamic Private IP/Static Private IP
  dynamic network_interface {
    for_each = local.internal_private_subnet_id
    content {
      subnetwork = network_interface.value
      network_ip = local.internal_private_ip_primary[tonumber(network_interface.key)]
    }
  }
  metadata_startup_script = data.template_file.startup_script.rendered
  provisioner "local-exec" {
    command = "sleep 100"
  }
}
