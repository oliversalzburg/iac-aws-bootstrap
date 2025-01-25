import {
  to = aws_s3_bucket.terraform_state
  id = local.terraform_state_bucket_name
}
import {
  to = aws_s3_bucket.log_bucket
  id = local.terraform_state_logs_bucket_name
}
import {
  to = aws_dynamodb_table.terraform_lock_table
  id = local.terraform_lock_table_name
}
import {
  to = aws_iam_policy.terraform_s3_backend_policy
  id = "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:policy/${local.terraform_s3_backend_policy_name}"
}
import {
  to = aws_ssm_parameter.terraform_state_bucket
  id = local.terraform_state_bucket_name_pointer
}
import {
  to = aws_ssm_parameter.terraform_lock_table
  id = local.terraform_lock_table_name_pointer
}
