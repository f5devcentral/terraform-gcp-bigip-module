## Deploys BIG-IP in Gcp Cloud

This Terraform module deploys N-nic F5 BIG-IP in Gcp cloud,and with module count feature we can also deploy multiple instances of BIG-IP.

## Prerequisites

Getting Started with the Google Provider ( https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started )

This module is supported from Terraform 0.13 version onwards.

Below templates are tested and worked in the following version 

Terraform v0.14.0

+ provider registry.terraform.io/hashicorp/google v3.51.0
+ provider registry.terraform.io/hashicorp/null v2.1.2
+ provider registry.terraform.io/hashicorp/random v3.0.1
+ provider registry.terraform.io/hashicorp/template v2.2.0

## Releases and Versioning

This module is supported in the following bigip and terraform version

| BIGIP version | Terraform 0.14 |
|---------------|----------------|
| BIG-IP 16.x  | X |
| BIG-IP 15.x  | X |
| BIG-IP 14.x  | X |

## Password Management

|:point_up: |By default bigip module will have random password setting to give dynamic password generation|
|----|---|

|:point_up: |Users Can explicitly provide password as input to Module using optional Variable "f5_password"|
|----|---|

|:point_up:  | To use Gcp secret manager ,we have to enable the variable "gcp_secret_manager_authentication" to true and supply the variables with secret name,version |
|-----|----|

## Example Usage

We have provided some common deployment [examples](https://github.com/f5devcentral/terraform-gcp-bigip-module/tree/main/examples) 

#### Note

Users can have dynamic or static private ip allocation.If primary/secondary private ip value is null, it will be dynamic or else static private ip allocation.

```
With Static private ip allocation we can assign primary and secondary private ips for external interfaces, whereas primary private ip for management
and internal interfaces.
```

If it is static private ip allocation we can't use module count as same private ips will be tried to allocate for multiple 
bigip instances based on module count.

With Dynamic private ip allocation,we have to pass null value to primary/secondary private ip declaration and module count will be supported.

Below example snippets show how this module is called. ( Dynamic private ip allocation )

```hcl
#
#Example 1-NIC Deployment Module usage
#
module bigip {
  source          = "../.."
  prefix          = "bigip-gcp-1nic"
  project_id      = var.project_id
  zone            = var.zone
  image           = var.image
  service_account = var.service_account
  mgmt_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.mgmt_subnetwork.id, "public_ip" = true, "private_ip_primary" = "" }]
}

#
#Example 2-NIC Deployment Module usage
#
module "bigip" {
  source              = "../.."
  prefix              = "bigip-gcp-2nic"
  project_id          = var.project_id
  zone                = var.zone
  image               = var.image
  service_account     = var.service_account
  mgmt_subnet_ids     = [{ "subnet_id" = google_compute_subnetwork.mgmt_subnetwork.id, "public_ip" = true, "private_ip_primary" = "" }]
  external_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.external_subnetwork.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
}

#
#Example 3-NIC Deployment  Module usage 
#
module bigip {
  source              = "../.."
  prefix              = "bigip-gcp-3nic"
  project_id          = var.project_id
  zone                = var.zone
  image               = var.image
  service_account     = var.service_account
  mgmt_subnet_ids     = [{ "subnet_id" = google_compute_subnetwork.mgmt_subnetwork.id, "public_ip" = true, "private_ip_primary" = "" }]
  external_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.external_subnetwork.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  internal_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.internal_subnetwork.id, "public_ip" = false, "private_ip_primary" = "", "private_ip_secondary" = "" }]
}
#
#Example 4-NIC Deployment  Module usage(with 2 external public interfaces,one management and internal interfaces)
#
module bigip {
  source              = "../.."
  prefix              = "bigip-gcp-4nic"
  project_id          = var.project_id
  zone                = var.zone
  image               = var.image
  service_account     = var.service_account
  mgmt_subnet_ids     = [{ "subnet_id" = google_compute_subnetwork.mgmt_subnetwork.id, "public_ip" = true, "private_ip_primary" = "" }]
  external_subnet_ids = ([{ "subnet_id" = google_compute_subnetwork.external_subnetwork.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = ""  },{ "subnet_id" = google_compute_subnetwork.external_subnetwork2.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = ""  }])
  internal_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.internal_subnetwork.id, "public_ip" = false, "private_ip_primary" = "" }]
}
```

+ Similarly we can have N-nic deployments based on user provided subnet_ids.

+ With module count, user can deploy multiple bigip instances in the gcp cloud (with the default value of count being one )

#### Below is the example snippet for private ip allocation

```hcl
#
#Example 3-NIC Deployment with static private ip allocation
#
module bigip {
  source              = "../.."
  prefix              = "bigip-gcp-3nic"
  project_id          = var.project_id
  zone                = var.zone
  image               = var.image
  service_account     = var.service_account
  mgmt_subnet_ids     = [{ "subnet_id" = google_compute_subnetwork.mgmt_subnetwork.id, "public_ip" = true, "private_ip_primary" = "" }]
  external_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.external_subnetwork.id, "public_ip" = true, "private_ip_primary" = "10.2.1.2", "private_ip_secondary" = "10.2.1.3" }]
  internal_subnet_ids = [{ "subnet_id" = google_compute_subnetwork.internal_subnetwork.id, "public_ip" = false, "private_ip_primary" = "", "private_ip_secondary" = "" }]
}

```

#### Required Input Variables

These variables must be set in the module block when using this module.

| Name | Description | Type | 
|------|-------------|------|
| prefix | This value is inserted in the beginning of each Gcp object. Note: requires alpha-numeric without special character | `string` |
| project\_id | The GCP project identifier where the cluster will be created | `string` |
| zone  | The compute zones which will host the BIG-IP VMs | `string` |
| mgmt\_subnet\_ids | Map with Subnet-id and public_ip as keys for the management subnet | `List of Maps` |
| service\_account | service account email to use with BIG-IP | `string` |

#### Optional Input Variables

These variables have default values and don't have to be set to use this module. You may set these variables to override their default values.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| f5\_username | The admin username of the F5   BIG-IP that will be deployed | `string` | bigipuser |
| f5\_password | Password of the F5  BIG-IP that will be deployed.If this is not specified random password will get generated | `string` | "" |
| image | The self-link URI for a BIG-IP image to use as a base for the VM cluster  | `string` | "projects/f5-7626-networks-public/global/images/f5-bigip-16-0-1-1-0-0-6-payg-good-25mbps-210129040032" |
| min_cpu_platform | Minimum CPU platform for the VM instance such as Intel Haswell or Intel Skylake | string` | Intel Skylake |
| machine_type | The machine type to create,if you want to update this value (resize the VM) after initial creation, you must set allow_stopping_for_update to true | string` | n1-standard-4 |
| automatic_restart | Specifies if the instance should be restarted if it was terminated by Compute Engine (not a user) | `bool` | true |
| preemptible | Specifies if the instance is preemptible. If this field is set to true, then automatic_restart must be set to false | `boo1` | false |
| disk_type | The GCE disk type. May be set to pd-standard, pd-balanced or pd-ssd | `string` | pd-ssd |
| disk_size_gb | The size of the image in gigabytes. If not specified, it will inherit the size of its base image | `number` | null |
| gcp_secret_manager_authentication | Whether to use secret manager to pass authentication | `bool` | false |
| gcp_secret_name | The secret to get the secret version for | `string` | null |
| gcp_secret_version | The version of the secret to get. If it is not provided, the latest version is retrieved | `string` | latest|
| libs\_dir | Directory on the BIG-IP to download the A&O Toolchain into | `string` | /config/cloud/gcp/node_modules |
| onboard\_log | Directory on the BIG-IP to store the cloud-init logs | `string` | /var/log/startup-script.log |
| mgmt\_subnet\_ids | List of maps of subnetids of the virtual network where the virtual machines will reside | `List of Maps` | [{ "subnet_id" = null, "public_ip" = null,"private_ip_primary" = "" }] |
| external\_subnet\_ids | List of maps of subnetids of the virtual network where the virtual machines will reside | `List of Maps` | [{ "subnet_id" = null, "public_ip" = null,"private_ip_primary" = "", "private_ip_secondary" = "" }] |
| internal\_subnet\_ids | List of maps of subnetids of the virtual network where the virtual machines will reside | `List of Maps` | [{ "subnet_id" = null, "public_ip" = null,"private_ip_primary" = "" }] |
| DO_URL | URL to download the BIG-IP Declarative Onboarding module | `string` | latest | 
| AS3_URL | URL to download the BIG-IP Application Service Extension 3 (AS3) module | `string` | latest | 
| TS_URL | URL to download the BIG-IP Telemetry Streaming module | `string` | latest | 
| FAST_URL | URL to download the BIG-IP FAST module | `string` | latest | 
| CFE_URL | URL to download the BIG-IP Cloud Failover Extension module | `string` | latest |
| INIT_URL | URL to download the BIG-IP runtime init module | `string` | latest |

#### Output Variables
| Name | Description |
|------|-------------|
| mgmtPublicIP | The actual ip address allocated for the resource |
| mgmtPort | Mgmt Port |
| f5\_username | BIG-IP username |
| bigip\_password | BIG-IP Password  |
| public_addresses | List of BIG-IP public addresses |
| private_addresses | List of BIG-IP private addresses |
| service_account | The service account that will be used for the BIG-IP VMs |

## Support Information

This repository is community-supported. Follow instructions below on how to raise issues.

### Filing Issues and Getting Help

If you come across a bug or other issue, use [GitHub Issues](https://github.com/f5devcentral/terraform-gcp-bigip-module/issues) to submit an issue for our team.  You can also see the current known issues on that page, which are tagged with a purple Known Issue label.

## Copyright

Copyright 2014-2019 F5 Networks Inc.

### F5 Networks Contributor License Agreement

Before you start contributing to any project sponsored by F5 Networks, Inc. (F5) on GitHub, you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer (if applicable) before signing the CLA since some employment agreements may have restrictions on your contributions to other projects. Otherwise by submitting a CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your contributions, you represent that you have received permission to make contributions on behalf of that employer, that your employer has waived such rights for your contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally entitled to grant the license recited therein. You represent further that each employee of the entity that submits contributions is authorized to submit such contributions on behalf of the entity pursuant to the CLA.
