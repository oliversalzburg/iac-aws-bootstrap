#!/usr/bin/env bash

cat <<-EOT
terraform {
  backend "s3" {
    bucket         = "$(terraform output -json s3 | jq --raw-output '.state.id')"
    dynamodb_table = "$(terraform output -json dynamodb | jq --raw-output '.lock.id')"
    key            = "iac.tfstate"
    region         = "$(terraform output -json s3 | jq --raw-output '.state.region')"
  }
}
EOT
