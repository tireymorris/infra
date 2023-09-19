terraform {
  #   backend "s3" {
  #     bucket  = "projectname-terraform-state"
  #     key     = "projectname.tfstate"
  #     region  = "us-west-2"
  #     encrypt = true
  #   }
    required_providers {
        postgresql = {
            source = "cyrilgdn/postgresql"
            version = "1.20.0"
        }
    }
}
