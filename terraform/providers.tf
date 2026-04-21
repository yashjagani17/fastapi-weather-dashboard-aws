# primary
provider "aws" {
    alias = "primary"
    region = "eu-west-2"
}

# secondary
provider "aws" {
    alias = "secondary"
    region = "us-east-1"
}