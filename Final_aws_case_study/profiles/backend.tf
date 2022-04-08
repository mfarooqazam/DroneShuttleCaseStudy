terraform {
  backend "s3" {
   encrypt = false
   bucket  = "tf-bucket-s3-staging-terraform"
   dynamodb_table = "tf-state-lock-dynamo"
   key = "path/path/terraform-tfstate"
   region = "us-east-1"
  }
}
