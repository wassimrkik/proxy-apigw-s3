terraform {
  backend "s3" {
    bucket = "infrastructure-backend-ede"
    key    = "pdf-retrieval/terraform.tfstate"
    region = "ap-south-1"
  }
}