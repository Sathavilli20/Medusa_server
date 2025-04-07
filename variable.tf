variable "key_name" {
  description = "medusa"
  type        = string
}
 
variable "db_username" {
  description = "Sarath"
  type        = string
  default     = "medusaadmin"
}
 
variable "db_password" {
  description = "Sarath2025"
  type        = string
  sensitive   = true
}