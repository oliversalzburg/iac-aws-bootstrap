data "aws_kms_alias" "state" {
  name = local.alias_state
}
data "aws_kms_key" "state" {
  key_id = data.aws_kms_alias.state.target_key_id
}

data "aws_kms_alias" "lock" {
  name = local.alias_lock
}
data "aws_kms_key" "lock" {
  key_id = data.aws_kms_alias.lock.target_key_id
}

data "aws_kms_alias" "logs" {
  name = local.alias_logs
}
data "aws_kms_key" "logs" {
  key_id = data.aws_kms_alias.logs.target_key_id
}

data "aws_kms_alias" "ssm" {
  name = local.alias_ssm
}
data "aws_kms_key" "ssm" {
  key_id = data.aws_kms_alias.ssm.target_key_id
}
