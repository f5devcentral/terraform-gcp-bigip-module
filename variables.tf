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
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-16-0-1-1-0-0-6-payg-good-25mbps-210129040032"
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

## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable DO_URL {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.21.0/f5-declarative-onboarding-1.21.0-3.noarch.rpm"
}
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable AS3_URL {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.28.0/f5-appsvcs-3.28.0-3.noarch.rpm"
}

## Please check and update the latest TS URL from https://github.com/F5Networks/f5-telemetry-streaming/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable TS_URL {
  description = "URL to download the BIG-IP Telemetry Streaming module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.20.0/f5-telemetry-1.20.0-3.noarch.rpm"
}

## Please check and update the latest Failover Extension URL from https://github.com/f5devcentral/f5-cloud-failover-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable CFE_URL {
  description = "URL to download the BIG-IP Cloud Failover Extension module"
  type        = string
  default     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.8.0/f5-cloud-failover-1.8.0-0.noarch.rpm"
}

## Please check and update the latest FAST URL from https://github.com/F5Networks/f5-appsvcs-templates/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable FAST_URL {
  description = "URL to download the BIG-IP FAST module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.9.0/f5-appsvcs-templates-1.9.0-1.noarch.rpm"
}
## Please check and update the latest runtime init URL from https://github.com/F5Networks/f5-bigip-runtime-init/releases/latest
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable INIT_URL {
  description = "URL to download the BIG-IP runtime init"
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.2.1/dist/f5-bigip-runtime-init-1.2.1-1.gz.run"
}

variable labels {
  description = "An optional map of key:value labels to add to the instance"
  type        = map(string)
  default     = {}
}

variable service_account {
  description = "service account email to use with BIG-IP vms"
  type        = string
}

variable f5_ssh_publickey {
  description = "Path to the public key to be used for ssh access to the VM.  Only used with non-Windows vms and can be left as-is even if using Windows vms. If specifying a path to a certification on a Windows machine to provision a linux vm use the / in the path versus backslash. e.g. c:/home/id_rsa.pub"
  default     = "~/.ssh/id_rsa.pub"
}

