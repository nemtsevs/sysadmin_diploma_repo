variable "virtual_machines" {
  default = ""
}

variable "s3bucket" {
  default = ""
}

variable "yc_service_account_id" {
  type      = string
  sensitive = true
}
variable "yc_access_key_id" {
  type      = string
  sensitive = true
}
variable "yc_secret_access_key" {
  type      = string
  sensitive = true
}
