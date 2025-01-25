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
