import {
  to = aws_kms_alias.state
  id = local.alias_state
}
import {
  to = aws_kms_alias.state_replica
  id = local.alias_state
}
import {
  to = aws_kms_alias.lock
  id = local.alias_lock
}
import {
  to = aws_kms_alias.lock_replica
  id = local.alias_lock
}
import {
  to = aws_kms_alias.ssm
  id = local.alias_ssm
}
import {
  to = aws_kms_alias.ssm_replica
  id = local.alias_ssm
}
import {
  to = aws_kms_alias.logs
  id = local.alias_logs
}
import {
  to = aws_kms_alias.logs_replica
  id = local.alias_logs
}

import {
  to = aws_kms_key.state
  id = data.aws_kms_key.state.id
}
import {
  to = aws_kms_key.lock
  id = data.aws_kms_key.lock.id
}
import {
  to = aws_kms_key.logs
  id = data.aws_kms_key.logs.id
}
import {
  to = aws_kms_key.ssm
  id = data.aws_kms_key.ssm.id
}
import {
  to = aws_kms_replica_key.state
  id = data.aws_kms_key.state.id
}
import {
  to = aws_kms_replica_key.lock
  id = data.aws_kms_key.lock.id
}
import {
  to = aws_kms_replica_key.logs
  id = data.aws_kms_key.logs.id
}
import {
  to = aws_kms_replica_key.ssm
  id = data.aws_kms_key.ssm.id
}
import {
  to = aws_kms_replica_key.state_keystore
  id = data.aws_kms_key.state.id
}
import {
  to = aws_kms_replica_key.lock_keystore
  id = data.aws_kms_key.lock.id
}
import {
  to = aws_kms_replica_key.logs_keystore
  id = data.aws_kms_key.logs.id
}
import {
  to = aws_kms_replica_key.ssm_keystore
  id = data.aws_kms_key.ssm.id
}

import {
  to = aws_s3_bucket.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_versioning.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_versioning.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket_versioning.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket_versioning.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_server_side_encryption_configuration.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket_server_side_encryption_configuration.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket_server_side_encryption_configuration.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_replication_configuration.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_replication_configuration.state_logs
  id = local.name_state_logs
}

import {
  to = aws_s3_bucket_public_access_block.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_public_access_block.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket_public_access_block.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket_public_access_block.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_policy.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_policy.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket_policy.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket_policy.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_ownership_controls.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_ownership_controls.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket_ownership_controls.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket_ownership_controls.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_metric.state
  id = "${local.name_state_bucket}:EntireBucket"
}
import {
  to = aws_s3_bucket_metric.state_logs
  id = "${local.name_state_logs}:EntireBucket"
}

import {
  to = aws_s3_bucket_logging.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_logging.replica
  id = local.name_state_bucket_replica
}

import {
  to = aws_dynamodb_table.lock
  id = local.name_lock
}
import {
  to = aws_dynamodb_table_replica.lock
  id = "${local.name_lock}:${data.aws_region.current.name}"
}

import {
  to = aws_dynamodb_resource_policy.lock
  id = "arn:${data.aws_partition.current.id}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.name_lock}"
}
import {
  to = aws_dynamodb_resource_policy.lock_replica
  id = "arn:${data.aws_partition.current.id}:dynamodb:${data.aws_region.replica.name}:${data.aws_caller_identity.current.account_id}:table/${local.name_lock}"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket_lifecycle_configuration.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket_lifecycle_configuration.replica
  id = local.name_state_bucket_replica
}
import {
  to = aws_s3_bucket_lifecycle_configuration.replica_logs
  id = local.name_state_logs_replica
}

import {
  to = aws_s3_bucket_acl.state
  id = "${local.name_state_bucket},private"
}
import {
  to = aws_s3_bucket_acl.state_logs
  id = "${local.name_state_logs},log-delivery-write"
}
import {
  to = aws_s3_bucket_acl.replica
  id = "${local.name_state_bucket_replica},private"
}
import {
  to = aws_s3_bucket_acl.replica_logs
  id = "${local.name_state_logs_replica},log-delivery-write"
}

import {
  to = aws_iam_policy.state_observer
  id = "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_observer}"
}
import {
  to = aws_iam_policy.state_manager
  id = "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_manager}"
}
import {
  to = aws_iam_policy.state_replicator
  id = "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_replicator}"
}
import {
  to = aws_iam_policy.state_logs_replicator
  id = "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_logs_replicator}"
}

import {
  to = aws_iam_role.state_observer
  id = local.name_state_observer
}
import {
  to = aws_iam_role.state_manager
  id = local.name_state_manager
}
import {
  to = aws_iam_role.state_replicator
  id = local.name_state_replicator
}
import {
  to = aws_iam_role.state_logs_replicator
  id = local.name_state_logs_replicator
}

import {
  to = aws_iam_role_policy_attachment.state_replicator
  id = "${local.name_state_replicator}/arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_replicator}"
}
import {
  to = aws_iam_role_policy_attachment.state_logs_replicator
  id = "${local.name_state_logs_replicator}/arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_logs_replicator}"
}

import {
  to = aws_ssm_parameter.state_bucket
  id = local.pointer_name_state_bucket
}
import {
  to = aws_ssm_parameter.state_bucket_key
  id = local.pointer_alias_state
}
import {
  to = aws_ssm_parameter.lock_table
  id = local.pointer_name_lock
}
