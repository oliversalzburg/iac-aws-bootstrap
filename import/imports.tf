#import {
#  to = aws_kms_key.state
#  id = "mrk-69a8e6e1b496455a899da561ed280e12"
#}
#import {
#  to = aws_kms_key.lock
#  id = "mrk-34de9a4f85ec4d62844d91232f873bd3"
#}
#import {
#  to = aws_kms_key.ssm
#  id = "mrk-764d3574dacc48499669230eec95d592"
#}

import {
  to = aws_kms_alias.state
  id = local.alias_state
}
import {
  to = aws_kms_alias.replica
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
  to = aws_s3_bucket.state
  id = local.name_state_bucket
}
import {
  to = aws_s3_bucket.state_logs
  id = local.name_state_logs
}
import {
  to = aws_s3_bucket.replica
  id = local.state_bucket_replica_name
}
import {
  to = aws_s3_bucket.replica_logs
  id = local.state_bucket_replica_logs_name
}

import {
  to = aws_dynamodb_table.lock
  id = local.name_lock
}
import {
  to = aws_dynamodb_table_replica.lock_replica
  id = "${local.name_lock}:${data.aws_region.current.name}"
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
  to = aws_iam_policy.replication
  id = "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_state_replicator}"
}
import {
  to = aws_iam_role.replication
  id = local.name_state_replicator
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
