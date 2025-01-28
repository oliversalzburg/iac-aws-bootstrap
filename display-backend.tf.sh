#!/usr/bin/env bash

cat <<-EOT
terraform {
  backend "s3" {
    bucket         = "$(terraform output -json s3 | jq --raw-output '.state.id')"
    dynamodb_table = "$(terraform output -json dynamodb | jq --raw-output '.lock.id')"
    encrypt        = true
    key            = "iac.tfstate"
    kms_key_id     = "$(terraform output -json kms | jq --raw-output '.state.id')"
    region         = "$(terraform output -json s3 | jq --raw-output '.state.region')"
  }
}
EOT
