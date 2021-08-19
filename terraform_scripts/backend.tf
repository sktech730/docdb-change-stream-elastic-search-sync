terraform {
  backend "s3" {
    bucket = "<DEPLOYMENT-BUCKET-NAME>"
    key = "<TERRAFORM-STATE-FILE-NAME>"
    profile = "<AWS-PROFILE>"
    encrypt = true
    region = "<AWS-REGION>"
  }
}