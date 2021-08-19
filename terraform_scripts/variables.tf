variable "vpc_id" {
  type    = string
  default = "<VPC-ID>"
}

variable "secret_rotation_frequency" {
  type    = number
  default = "<SAMPLE-VALUE-IN-NUMBER>" # set the rotation frequency in days
}

variable "master_docdb_password" {
  type    = string
  default = "<MASTER-DOCDB-PASSWORD>"
}

variable "master_docdb_user" {
  type = string
  default = "<MASTER-DOCDB-USER>"
}

variable "private-subnet-1"{
  type = string
  default = "<PRIVATE-SUBNET-ID>"
}

variable "private-subnet-2"{
  type = string
  default = "<PRIVATE-SUBNET-ID>"
}

variable "user_region" {
  type        = string
  description = "AWS region to use for all resources"
  default     = "<AWS-REGION>"
}

variable "docdb-cluster-sample" {
  type = string
  default = "docdb-cluster-sample"
}

variable "sample-docdb-1" {
  type = string
  default = "sample-docdb-1"
}

