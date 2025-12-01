variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "Región para la VPC y subredes"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona para las VMs"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Nombre de la VPC"
  type        = string
  default     = "portfolio-vpc"
}

variable "public_subnet_cidr" {
  description = "CIDR de la subred pública"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR de la subred privada"
  type        = string
  default     = "10.10.2.0/24"
}

variable "public_vm_name" {
  description = "Nombre de la VM pública"
  type        = string
  default     = "web-vm"
}

variable "private_vm_name" {
  description = "Nombre de la VM privada"
  type        = string
  default     = "db-vm"
}

variable "machine_type" {
  description = "Tipo de máquina para ambas VMs"
  type        = string
  default     = "e2-micro"
}

variable "tags_web" {
  description = "Tags de red para la VM web"
  type        = list(string)
  default     = ["web"]
}

variable "tags_db" {
  description = "Tags de red para la VM de base de datos"
  type        = list(string)
  default     = ["db"]
}
