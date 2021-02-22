variable prefix {
  description = "Prefix for resources created by this module"
}
variable project_id {
  type        = string
  description = "The GCP project identifier where the cluster will be created."
}

variable zone {
  type        = string
  description = "The compute zones which will host the BIG-IP VMs"
}

variable min_cpu_platform {
  type        = string
  default     = "Intel Skylake"
  description = "Minimum CPU platform for the VM instance such as Intel Haswell or Intel Skylake"
}

variable machine_type {
  type        = string
  default     = "n1-standard-4"
  description = "The machine type to create,if you want to update this value (resize the VM) after initial creation, you must set allow_stopping_for_update to true"
}

variable "automatic_restart" {
  type        = bool
  default     = true
  description = "Specifies if the instance should be restarted if it was terminated by Compute Engine (not a user),defaults to true."
}

variable "preemptible" {
  type        = string
  default     = false
  description = "Specifies if the instance is preemptible. If this field is set to true, then automatic_restart must be set to false,defaults to false."
}

variable "image" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-2-0-0-9-payg-good-5gbps-201110225418"
  description = "This can be one of: the image's self_link, projects/{project}/global/images/{image}, projects/{project}/global/images/family/{family}, global/images/{image}, global/images/family/{family}, family/{family}, {project}/{family}, {project}/{image}, {family}, or {image}."
}

variable "disk_type" {
  type        = string
  default     = "pd-ssd"
  description = "The GCE disk type. May be set to pd-standard, pd-balanced or pd-ssd."
}

variable "disk_size_gb" {
  type        = number
  default     = null
  description = " The size of the image in gigabytes. If not specified, it will inherit the size of its base image."
}

variable mgmt_subnet_ids {
  description = "List of maps of subnetids of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id          = string
    public_ip          = bool
    private_ip_primary = string
  }))
  default = [{ "subnet_id" = null, "public_ip" = null, "private_ip_primary" = null }]
}

variable external_subnet_ids {
  description = "List of maps of subnetids of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id            = string
    public_ip            = bool
    private_ip_primary   = string
    private_ip_secondary = string
  }))
  default = [{ "subnet_id" = null, "public_ip" = null, "private_ip_primary" = null, "private_ip_secondary" = null }]
}

variable internal_subnet_ids {
  description = "List of maps of subnetids of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id          = string
    public_ip          = bool
    private_ip_primary = string
  }))
  default = [{ "subnet_id" = null, "public_ip" = null, "private_ip_primary" = null }]
}

variable f5_username {
  description = "The admin username of the F5 Bigip that will be deployed"
  default     = "bigipuser"
}

variable f5_password {
  description = "The admin password of the F5 Bigip that will be deployed"
  default     = ""
}

variable onboard_log {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  default     = "/var/log/startup-script.log"
  type        = string
}

variable libs_dir {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  default     = "/config/cloud/gcp/node_modules"
  type        = string
}

variable gcp_secret_manager_authentication {
  description = "Whether to use secret manager to pass authentication"
  type        = bool
  default     = false
}

variable gcp_secret_name {
  description = "The secret to get the secret version for"
  type        = string
  default     = ""
}

variable gcp_secret_version {
  description = "(Optional)The version of the secret to get. If it is not provided, the latest version is retrieved."
  type        = string
  default     = "latest"
}

