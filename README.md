# AWS IaC Bootstrapping

Terraform remote state backend on AWS, using discovery-resistant naming patterns and ephemeral local states.

> [!CAUTION]
> **Extremely opinionated solution ahead!**

- State store and lock table in home region.
- State store and lock table are encrypted with multi-region KMS key.
- State _and_ keys are replicated to secondary region. Key is additionally replicated to a "keystore region".
- State and replica have distinct log buckets in their respective regions.
- State version history and log history are maintained through lifecycle management.

Out of scope:

- Custom key store
- Custom key material
- Multiple state replication regions
- Cross-account replication
- Log encryption
- History object lock

## Init

Create an AWS CLI SSO profile for your account, or whatever you have to do to commandeer the account :shipit:.

```shell
aws configure sso
> dev
> https://d-1234567890.awsapps.com/start/
> eu-central-1
> <accept default>
> <select target account>
> eu-central-1
> json
> <accept default>
```

Result: `aws s3 ls --profile AdministratorAccess-123456789101`

## Setup

```shell
cd terraform
terraform init
AWS_PROFILE=AdministratorAccess-123456789101 terraform apply
terraform output seed
```

> [!IMPORTANT]
> Take note of the `seed` output. This is crucial to restore the state later. Keep it safe.

### Pre-Seeding

To generate the seed outside of the firstinfrastructure plan generation, `-target` the resource.

```shell
cd terraform
terraform init
AWS_PROFILE=AdministratorAccess-123456789101 terraform apply -refresh=false -target=random_password.seed
AWS_PROFILE=AdministratorAccess-123456789101 terraform apply
```

## Restore

Restore the state by providing the seed that was used to create it.

```shell
cd import
terraform init
AWS_PROFILE=AdministratorAccess-123456789101 terraform import random_password.seed oCxD1aYEn4eSQXIObCAQZd6KpN_5-82G8_7PGYvXvmo
AWS_PROFILE=AdministratorAccess-123456789101 terraform apply
```

## Post-Deployment Validation

### S3 State Bucket Initiator Write Access

Expect success

```shell
# Write flag to state bucket
echo "$(date) $(whoami)@$(hostname):$PWD" | aws s3 cp - s3://$(terraform output -json s3 | jq --raw-output '.state.id')/flag.txt --sse=aws:kms
# Verify
aws s3 cp s3://$(terraform output -json s3 | jq --raw-output '.state.id')/flag.txt -
```

### S3 State Replication

Expect success

```shell
aws s3 cp s3://$(terraform output -json s3 | jq --raw-output '.replica.id')/flag.txt -
```

### S3 State Replica Bucket Initiator Write Denial

Expect failure

```shell
# Write flag to replica bucket
echo "$(date) $(whoami)@$(hostname):$PWD" | aws s3 cp - s3://$(terraform output -json s3 | jq --raw-output '.replica.id')/flag.txt --sse=aws:kms
# Replace flag with own
echo "$(date) MANIPULATION-MANIPULATION-MANIPULATION" | aws s3 cp - s3://$(terraform output -json s3 | jq --raw-output '.replica.id')/flag.txt --sse=aws:kms
# Delete flag
aws s3 rm s3://$(terraform output -json s3 | jq --raw-output '.replica.id')/flag.txt --sse=aws:kms
```

## Terraform Implementation Spec

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.84.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~>3.6.3 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |
| <a name="provider_aws.keystore"></a> [aws.keystore](#provider\_aws.keystore) | 5.84.0 |
| <a name="provider_aws.replica"></a> [aws.replica](#provider\_aws.replica) | 5.84.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.state_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.state_observer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_replica_key.keystore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_replica_key) | resource |
| [aws_s3_bucket.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_metric.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_metric.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_ownership_controls.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.state_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_parameter.lock_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.state_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.state_bucket_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [random_password.seed](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_observer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_namespace"></a> [force\_namespace](#input\_force\_namespace) | We expect that only a single IaC state is used per AWS account, as anything else just raises potential for conflicts. Thus, account-local resources are created with a fixed name to make them easier to discover.<br><br>If you absolutely require multiple IaC states in one account, you can set this variable to `true` to have _all_ resources namespaced. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb"></a> [dynamodb](#output\_dynamodb) | Holds IaC state locks. |
| <a name="output_iam"></a> [iam](#output\_iam) | ARN of the IAM policy that allows management access to the state resources. |
| <a name="output_kms"></a> [kms](#output\_kms) | Server-Side-Encryption keys for created S3 buckets. |
| <a name="output_s3"></a> [s3](#output\_s3) | Information regarding created S3 buckets. |
| <a name="output_seed"></a> [seed](#output\_seed) | Cryptographic seed of this backend deployment. |
| <a name="output_ssm"></a> [ssm](#output\_ssm) | ARNs of SSM parameters in the account, which hold the names of the created resources. |
<!-- END_TF_DOCS -->
