# AWS IaC Bootstrapping

Terraform remote state backend on AWS, using discovery-resistant naming patterns and ephemeral local states.

- Single file ignition.
- Globally addressable resource names (S3) are fully randomized.
- State store and lock table reside in home region, and are encrypted with customer managed multi-region KMS keys.
- State, lock, and keys are replicated to secondary region.  
  Keys are additionally replicated to a "keystore region".
- Resulting identifiers are stored in KMS encrypted SSM parameters.
- State and replica have distinct log buckets in their respective regions.  
  Logs are encrypted and replicated cross-region.
- State version history and log history are maintained through lifecycle management.

> [!NOTE]
> All resources are locked down through resource-based policies, as applicable. For S3 buckets:
> - Require state requests to originate from MFA-authenticated sessions, not older than 1 hour.
> - Require all requests to use TLS v1.3 (or better).
> - Require all objects to be encrypted exclusively with our key.
> - Prevent all PUT and DELETE requests on replication targets.

Out of scope (for now):

- Custom key store
- Custom key material
- Multiple state replication regions
- Cross-account replication
- History object lock (in planning)

## Init

Create an AWS CLI SSO profile for your account, or whatever you have to do to commandeer the account :shipit:

## Setup

> [!CAUTION]
> Storing 4 customer managed keys in 3 regions incurs charges. Even _entirely idle_ deployments, will add 144&nbsp;USD to your yearly cloud spend.

```shell
tofu init
tofu apply
tofu output seed
# Optional: Display a backend configuration.
./display-backend.tf.sh
```

> [!IMPORTANT]
> Take note of the `seed` output. This is crucial to restore the state later. Keep it safe.

### Pre-Seeding

To generate the seed outside of the first infrastructure plan generation, `-target` the resource.

```shell
tofu init
tofu apply -refresh=false -target=random_id.seed
tofu apply
```

## Restore

Restore the state by providing the seed that was used to create it.

```shell
cd import
tofu init
# Ensure AWS_PROFILE and AWS_REGION are set appropriately.
# Prefix command with space to prevent history entry.
 tofu import random_id.seed oCxD1aYEn4eSQXIObCAQZd6KpN_5-82G8_7PGYvXvmo
tofu apply
```

## Post-Deployment Validation

### State Restore

Expect success

```shell
# Note seed.
tofu output -json seed | jq --raw-output '.id'
# Delete state.
rm *.tfstate*
 tofu import random_id.seed oCxD1aYEn4eSQXIObCAQZd6KpN_5-82G8_7PGYvXvmo
tofu apply
```

### S3 State Bucket Initiator Write Access

Expect success

```shell
# Write flag to state bucket
echo "$(date) $(whoami)@$(hostname):$PWD" | aws s3 cp - s3://$(tofu output -json s3 | jq --raw-output '.state.id')/flag.txt --sse=aws:kms --sse-kms-key-id=$(tofu output -json kms | jq --raw-output '.state.id')
# Verify
aws s3 cp s3://$(tofu output -json s3 | jq --raw-output '.state.id')/flag.txt -
```

### S3 State Replication

Expect success

```shell
# Write flag to state bucket
echo "$(date) $(whoami)@$(hostname):$PWD" | aws s3 cp - s3://$(tofu output -json s3 | jq --raw-output '.state.id')/flag.txt --sse=aws:kms --sse-kms-key-id=$(tofu output -json kms | jq --raw-output '.state.id')
# Verify on replica
aws s3api wait object-exists --bucket=$(tofu output -json s3 | jq --raw-output '.replica.id') --key=flag.txt
aws s3 cp s3://$(tofu output -json s3 | jq --raw-output '.replica.id')/flag.txt -
```

### S3 State Replica Bucket Initiator Write Denial

Expect failure

```shell
# Write flag to replica bucket
echo "$(date) $(whoami)@$(hostname):$PWD" | aws s3 cp - s3://$(tofu output -json s3 | jq --raw-output '.replica.id')/flag.txt --sse=aws:kms
# Replace flag with own
echo "$(date) CAPTURE" | aws s3 cp - s3://$(tofu output -json s3 | jq --raw-output '.replica.id')/flag.txt --sse=aws:kms
# Delete flag
aws s3 rm s3://$(tofu output -json s3 | jq --raw-output '.replica.id')/flag.txt --sse=aws:kms
```

## Implementation Spec

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.86.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.3 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.86.0 |
| <a name="provider_aws.keystore"></a> [aws.keystore](#provider\_aws.keystore) | 5.86.0 |
| <a name="provider_aws.replica"></a> [aws.replica](#provider\_aws.replica) | 5.86.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_dynamodb_resource_policy.lock](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.lock_replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_table.lock](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table_replica.lock](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/dynamodb_table_replica) | resource |
| [aws_iam_policy.state_logs_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.state_manager](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.state_observer](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.state_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.state_logs_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_role) | resource |
| [aws_iam_role.state_manager](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_role) | resource |
| [aws_iam_role.state_observer](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_role) | resource |
| [aws_iam_role.state_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.state_logs_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.state_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.lock](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.lock_replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.logs_replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.ssm](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.ssm_replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.state_replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_alias) | resource |
| [aws_kms_key.lock](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_key) | resource |
| [aws_kms_key.logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_key) | resource |
| [aws_kms_key.ssm](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_key) | resource |
| [aws_kms_key.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_key) | resource |
| [aws_kms_replica_key.lock](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.lock_keystore](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.logs_keystore](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.ssm](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.ssm_keystore](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_kms_replica_key.state_keystore](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/kms_replica_key) | resource |
| [aws_s3_bucket.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_metric.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_metric.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_ownership_controls.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_replication_configuration.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.replica_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.state](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.state_logs](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_parameter.lock_table](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.state_bucket](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.state_bucket_key](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/resources/ssm_parameter) | resource |
| [random_id.seed](https://registry.terraform.io/providers/hashicorp/random/3.6.3/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role_caller](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role_s3](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lock_key](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lock_lockdown](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lock_replica_lockdown](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs_key](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replica_lockdown](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replica_logs_lockdown](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm_key](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_key](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_lockdown](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_logs_lockdown](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_logs_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_manager](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_observer](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.state_replicator](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/region) | data source |
| [aws_region.replica](https://registry.terraform.io/providers/hashicorp/aws/5.86.0/docs/data-sources/region) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_kms_key_deletion_window_in_days"></a> [force\_kms\_key\_deletion\_window\_in\_days](#input\_force\_kms\_key\_deletion\_window\_in\_days) | It should usually be worth it to keep the deleted keys for 30 days as a precaution.<br><br>But, especially during testing, it can be excessive to store the temporary resources this long. Thus, the value is lowered to 7 during tests. | `number` | `30` | no |
| <a name="input_force_namespace"></a> [force\_namespace](#input\_force\_namespace) | We expect that only a single IaC state is used per AWS account, as anything else just raises potential for conflicts. Thus, account-local resources are created with a fixed name to make them easier to discover.<br><br>If you absolutely require multiple IaC states in one account, you can set this variable to `true` to have _all_ resources namespaced. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb"></a> [dynamodb](#output\_dynamodb) | Details about the created DynamoDB state lock table. |
| <a name="output_iam"></a> [iam](#output\_iam) | ARN of the IAM policy that allows management access to the state resources. |
| <a name="output_kms"></a> [kms](#output\_kms) | Details about Server-Side-Encryption keys for created resources. |
| <a name="output_s3"></a> [s3](#output\_s3) | Details about all created S3 buckets. |
| <a name="output_seed"></a> [seed](#output\_seed) | Cryptographic seed of this backend deployment.<br>You need this to recover the state at a later point in time. |
| <a name="output_ssm"></a> [ssm](#output\_ssm) | Details about SSM parameters in the account, which hold the names of the created resources. |
<!-- END_TF_DOCS -->
