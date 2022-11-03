variable "rg_name" {
    type = string
    default = "significantrg"
}

variable "vms" {
    type = map(object({
        size = string
        admin_user = string
        admin_password = string
        disks = list(number)
    }))
   default = {
  azurevm1 = {
    size = "Standard_DS1_v2"
    admin_user = "azureuser"
    admin_password = "azureuser@2021"
    disks = [30, 30]
  }
 }
}

variable "location" {}
variable "subscriptionId" {}
variable "clientId" {}
variable "clientSecret" {}
variable "tenantId" {}

module "vms" {
    for_each = var.vms
    
    source = "./modules/vm"
    resource_group_name = var.rg_name
    vm_name = each.key
    vm = each.value
    disks = each.value["disks"]
    location = var.location
}
