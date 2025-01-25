variable "force_namespace" {
  default     = false
  description = <<-EOT
  We expect that only a single IaC state is used per AWS account, as anything else just raises potential for conflicts. Thus, account-local resources are created with a fixed name to make them easier to discover.

  If you absolutely require multiple IaC states in one account, you can set this variable to `true` to have _all_ resources namespaced.
  EOT
  type        = bool
}

terraform {
  required_version = ">=1.5.9"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6.3"
    }
  }
}

locals {
  tags = {
    owner-manager = "iac-aws-bootstrap"
  }
}
provider "aws" {
  # assumed region is in 'eu-'
  default_tags {
    tags = local.tags
  }
}
provider "aws" {
  alias  = "global"
  region = "us-east-1"
  default_tags {
    tags = local.tags
  }
}
provider "aws" {
  alias = "replica"
  // Replica in same content (eu-), out-of-region
  region = "eu-north-1"
  default_tags {
    tags = local.tags
  }
}
provider "aws" {
  alias = "keystore"
  // Recovery keystore on different continent
  region = "ca-central-1"
  default_tags {
    tags = local.tags
  }
}

resource "random_password" "seed" {
  length = 128

  lower            = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 0
  numeric          = true
  override_special = "-"
  special          = true
  upper            = false
}

locals {
  seed_base    = random_password.seed.result
  seed_padding = split("", strrev(replace(random_password.seed.result, "-", "")))
  seed_derived = sha512(random_password.seed.result)

  namespaces = [
    "${local.seed_padding[00]}${substr(local.seed_base, 00, 61)}${local.seed_padding[01]}",
    "${local.seed_padding[02]}${substr(local.seed_base, 61, 61)}${local.seed_padding[03]}"
  ]
  namespaces_derived = sort([
    "-${local.seed_padding[04]}${substr(local.seed_derived, 00, 30)}${local.seed_padding[05]}",
    "-${local.seed_padding[06]}${substr(local.seed_derived, 30, 30)}${local.seed_padding[07]}",
    "-${local.seed_padding[08]}${substr(local.seed_derived, 60, 30)}${local.seed_padding[09]}",
    "-${local.seed_padding[10]}${substr(local.seed_derived, 90, 30)}${local.seed_padding[11]}"
  ])
  namespaces_local = var.force_namespace ? local.namespaces_derived : ["", "", "", ""]

  lock_key_alias                 = "alias/iac-lock${local.namespaces_local[0]}"
  lock_name                      = "iac-state-lock${local.namespaces_local[0]}"
  lock_name_pointer              = "/iac${local.namespaces_local[0]}/state-lock-table"
  state_manager_name             = "iac-state-manager${local.namespaces_local[0]}"
  state_observer_name            = "iac-state-observer${local.namespaces_local[0]}"
  state_replication_name         = "iac-state-replicator${local.namespaces_local[0]}"
  state_bucket_name              = local.namespaces[0]
  state_bucket_name_pointer      = "/iac${local.namespaces_local[0]}/state-bucket"
  state_bucket_replica_name      = strrev(local.namespaces[0])
  state_bucket_replica_logs_name = strrev(local.namespaces[1])
  state_logs_bucket_name         = local.namespaces[1]
  state_key_alias                = "alias/iac-state${local.namespaces_local[0]}"
  state_key_alias_pointer        = "/iac${local.namespaces_local[0]}/state-key"
  ssm_key_alias                  = "alias/iac-ssm${local.namespaces_local[0]}"
}

output "seed" {
  description = "Cryptographic seed of this backend deployment."
  sensitive   = true
  value = {
    id = random_password.seed.result
  }
}

output "kms" {
  description = "Server-Side-Encryption keys for created S3 buckets."
  value = {
    iac_state = {
      arn   = aws_kms_key.state.arn
      id    = aws_kms_key.state.id
      alias = aws_kms_alias.state.id
    }
    iac_state_replica = {
      arn   = aws_kms_replica_key.replica.arn
      id    = aws_kms_replica_key.replica.id
      alias = aws_kms_alias.replica.id
    }
    iac_state_keystore = {
      arn = aws_kms_replica_key.keystore.arn
      id  = aws_kms_replica_key.keystore.id
    }
  }
}

output "s3" {
  description = "Information regarding created S3 buckets."
  sensitive   = true
  value = {
    state = {
      arn = aws_s3_bucket.state.arn,
      id  = local.state_bucket_name
    }
    state_logs = {
      arn = aws_s3_bucket.state_logs.arn,
      id  = local.state_logs_bucket_name
    }
    replica = {
      arn = aws_s3_bucket.replica.arn,
      id  = local.state_bucket_replica_name
    }
    replica_logs = {
      arn = aws_s3_bucket.replica_logs.arn
      id  = local.state_bucket_replica_logs_name
    }
  }
}

output "dynamodb" {
  description = "Holds IaC state locks."
  value = {
    lock = {
      arn = aws_dynamodb_table.lock.arn
      id  = aws_dynamodb_table.lock.id
    }
  }
}

output "ssm" {
  description = "ARNs of SSM parameters in the account, which hold the names of the created resources."
  value = {
    state_bucket = {
      arn = aws_ssm_parameter.state_bucket.arn,
      id  = aws_ssm_parameter.state_bucket.id,
    }
    state_bucket_key = {
      arn = aws_ssm_parameter.state_bucket_key.arn
      id  = aws_ssm_parameter.state_bucket_key.id,
    }
    lock_table = {
      arn = aws_ssm_parameter.lock_table.arn,
      id  = aws_ssm_parameter.lock_table.id,
    }
  }
}

output "iam" {
  description = "ARN of the IAM policy that allows management access to the state resources."
  value = {
    manager_policy = {
      arn = aws_iam_policy.state_manager.arn,
      id  = aws_iam_policy.state_manager.id
    }
    observer_policy = {
      arn = aws_iam_policy.state_observer.arn,
      id  = aws_iam_policy.state_observer.id
    }
    replication_policy = {
      arn = aws_iam_policy.replication.arn
      id  = aws_iam_policy.replication.id
    }
    replication_role = {
      arn = aws_iam_role.replication.arn
      id  = aws_iam_role.replication.id
    }
  }
}


// Terraform internals below

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_region" "replica" {
  provider = aws.replica
}

data "aws_iam_policy_document" "state_key" {
  version   = "2012-10-17"
  policy_id = "iac-state"
  statement {
    sid    = "Baseline IAM Access"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Initiator Access"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
resource "aws_kms_key" "state" {
  description             = "IaC State Encryption Key"
  deletion_window_in_days = 30
  multi_region            = true
  policy                  = data.aws_iam_policy_document.state_key.json
  enable_key_rotation     = true
  tags = {
    Name = "iac-state"
  }
}
resource "aws_kms_alias" "state" {
  target_key_id = aws_kms_key.state.id
  name          = local.state_key_alias
}
resource "aws_kms_replica_key" "replica" {
  provider                = aws.replica
  description             = "IaC State Encryption Key Replica"
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.state_key.json
  primary_key_arn         = aws_kms_key.state.arn
  tags = {
    origin = data.aws_region.current.name
  }
}
resource "aws_kms_alias" "replica" {
  provider      = aws.replica
  target_key_id = aws_kms_replica_key.replica.id
  name          = local.state_key_alias
}
resource "aws_kms_replica_key" "keystore" {
  provider                = aws.keystore
  description             = "IaC State Encryption Key Replica"
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.state_key.json
  primary_key_arn         = aws_kms_key.state.arn
  tags = {
    origin = data.aws_caller_identity.current.account_id
  }
}

data "aws_iam_policy_document" "lock_key" {
  version   = "2012-10-17"
  policy_id = "iac-lock"
  statement {
    sid    = "Baseline IAM Access"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Initiator Access"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
resource "aws_kms_key" "lock" {
  description             = "IaC Lock Encryption Key"
  deletion_window_in_days = 30
  multi_region            = true
  policy                  = data.aws_iam_policy_document.lock_key.json
  enable_key_rotation     = true
  tags = {
    Name = "iac-lock"
  }
}
resource "aws_kms_alias" "lock" {
  target_key_id = aws_kms_key.lock.id
  name          = local.lock_key_alias
}
resource "aws_kms_replica_key" "lock_replica" {
  provider                = aws.replica
  description             = "IaC Lock Encryption Key Replica"
  deletion_window_in_days = 30
  primary_key_arn         = aws_kms_key.lock.arn
  tags = {
    origin = data.aws_region.current.name
  }
}
resource "aws_kms_alias" "lock_replica" {
  provider      = aws.replica
  target_key_id = aws_kms_replica_key.lock_replica.id
  name          = local.lock_key_alias
}
resource "aws_kms_replica_key" "lock_keystore" {
  provider                = aws.keystore
  description             = "IaC Lock Encryption Key Replica"
  deletion_window_in_days = 30
  primary_key_arn         = aws_kms_key.lock.arn
  tags = {
    origin = data.aws_caller_identity.current.account_id
  }
}

data "aws_iam_policy_document" "ssm_key" {
  version   = "2012-10-17"
  policy_id = "iac-ssm"
  statement {
    sid    = "Baseline IAM Access"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Initiator Access"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
resource "aws_kms_key" "ssm" {
  description             = "IaC SSM Encryption Key"
  deletion_window_in_days = 30
  multi_region            = true
  policy                  = data.aws_iam_policy_document.ssm_key.json
  enable_key_rotation     = true
  tags = {
    Name = "iac-ssm"
  }
}
resource "aws_kms_alias" "ssm" {
  target_key_id = aws_kms_key.ssm.id
  name          = local.ssm_key_alias
}
resource "aws_kms_replica_key" "ssm_replica" {
  provider                = aws.replica
  description             = "IaC SSM Encryption Key Replica"
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.ssm_key.json
  primary_key_arn         = aws_kms_key.ssm.arn
  tags = {
    origin = data.aws_region.current.name
  }
}
resource "aws_kms_alias" "ssm_replica" {
  provider      = aws.replica
  target_key_id = aws_kms_replica_key.ssm_replica.id
  name          = local.ssm_key_alias
}
resource "aws_kms_replica_key" "ssm_keystore" {
  provider                = aws.keystore
  description             = "IaC SSM Encryption Key Replica"
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.ssm_key.json
  primary_key_arn         = aws_kms_key.ssm.arn
  tags = {
    origin = data.aws_caller_identity.current.account_id
  }
}

resource "aws_s3_bucket" "state" {
  bucket        = local.state_bucket_name
  force_destroy = true
  tags = {
    Name = "iac-state"
  }
}
resource "aws_s3_bucket" "state_logs" {
  bucket        = local.state_logs_bucket_name
  force_destroy = true
  tags = {
    Name = "iac-state-logs"
  }
}
resource "aws_s3_bucket" "replica" {
  provider      = aws.replica
  bucket        = local.state_bucket_replica_name
  force_destroy = true
  tags = {
    Name = "iac-state-replica"
  }
}
resource "aws_s3_bucket" "replica_logs" {
  provider      = aws.replica
  bucket        = local.state_bucket_replica_logs_name
  force_destroy = true
  tags = {
    Name = "iac-state-replica-logs"
  }
}

data "aws_iam_policy_document" "replica_lockdown" {
  provider  = aws.replica
  version   = "2012-10-17"
  policy_id = "replica-lockdown"
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:PutObject"
    ]
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = ["arn:aws:s3:::${local.state_bucket_replica_name}/*"]
    sid       = "DenyWrite"
  }
}
resource "aws_s3_bucket_policy" "replica" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica]
  bucket     = local.state_bucket_replica_name
  policy     = data.aws_iam_policy_document.replica_lockdown.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  depends_on = [aws_s3_bucket.state]
  bucket     = local.state_bucket_name
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica]
  bucket     = local.state_bucket_replica_name
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "state" {
  depends_on = [aws_s3_bucket.state]
  bucket     = local.state_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "state_logs" {
  depends_on = [aws_s3_bucket.state_logs]
  bucket     = local.state_logs_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "replica" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica]
  bucket     = local.state_bucket_replica_name
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "replica_logs" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica_logs]
  bucket     = local.state_bucket_replica_logs_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  depends_on = [aws_s3_bucket.state]
  bucket     = local.state_bucket_name
  rule {
    id = "expire-history"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 360
    }
    status = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "state_logs" {
  depends_on = [aws_s3_bucket.state_logs]
  bucket     = local.state_logs_bucket_name
  rule {
    id = "expire-history"
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    status = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica]
  bucket     = local.state_bucket_replica_name
  rule {
    id = "expire-history"
    noncurrent_version_transition {
      noncurrent_days = 360
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 720
    }
    status = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "replica_logs" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica_logs]
  bucket     = local.state_bucket_replica_logs_name
  rule {
    id = "expire-history"
    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 360
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  depends_on              = [aws_s3_bucket.state]
  bucket                  = local.state_bucket_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "state_logs" {
  depends_on              = [aws_s3_bucket.state_logs]
  bucket                  = local.state_logs_bucket_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "replica" {
  provider                = aws.replica
  depends_on              = [aws_s3_bucket.replica]
  bucket                  = local.state_bucket_replica_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "replica_logs" {
  provider                = aws.replica
  depends_on              = [aws_s3_bucket.replica_logs]
  bucket                  = local.state_bucket_replica_logs_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_metric" "state" {
  bucket = aws_s3_bucket.state.id
  name   = "EntireBucket"
}
resource "aws_s3_bucket_metric" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_acl" "state" {
  depends_on = [aws_s3_bucket_ownership_controls.state]
  bucket     = local.state_bucket_name
  acl        = "private"
}
resource "aws_s3_bucket_acl" "replica" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket_ownership_controls.replica]
  bucket     = local.state_bucket_replica_name
  acl        = "private"
}
resource "aws_s3_bucket_acl" "state_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.state_logs]
  bucket     = local.state_logs_bucket_name
  acl        = "log-delivery-write"
}
resource "aws_s3_bucket_acl" "replica_logs" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket_ownership_controls.replica_logs]
  bucket     = local.state_bucket_replica_logs_name
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_ownership_controls" "state" {
  depends_on = [aws_s3_bucket.state]
  bucket     = local.state_bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_ownership_controls" "state_logs" {
  depends_on = [aws_s3_bucket.state_logs]
  bucket     = local.state_logs_bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_ownership_controls" "replica" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica_logs]
  bucket     = local.state_bucket_replica_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_ownership_controls" "replica_logs" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket.replica_logs]
  bucket     = local.state_bucket_replica_logs_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_logging" "state" {
  depends_on    = [aws_s3_bucket.state, aws_s3_bucket.state_logs]
  bucket        = local.state_bucket_name
  target_bucket = local.state_logs_bucket_name
  target_prefix = "log/"
}
resource "aws_s3_bucket_logging" "replica" {
  provider      = aws.replica
  depends_on    = [aws_s3_bucket.replica, aws_s3_bucket.replica_logs]
  bucket        = local.state_bucket_replica_name
  target_bucket = local.state_bucket_replica_logs_name
  target_prefix = "log/"
}

resource "aws_dynamodb_table" "lock" {
  name             = local.lock_name
  hash_key         = "LockID"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    ignore_changes = [replica]
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.lock.arn
  }
  tags = {
    Name = "iac-state-lock"
  }
}
resource "aws_dynamodb_table_replica" "lock_replica" {
  provider               = aws.replica
  global_table_arn       = aws_dynamodb_table.lock.arn
  kms_key_arn            = aws_kms_replica_key.lock_replica.arn
  point_in_time_recovery = true
}

data "aws_iam_policy_document" "state_observer" {
  version   = "2012-10-17"
  policy_id = "iac-state-observer"
  statement {
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = [aws_s3_bucket.state.arn]
    sid       = "BucketAccess"
  }
  statement {
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.state.arn}/*"]
    sid       = "StateAccess"
  }
  statement {
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameterHistory",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    effect = "Allow"
    resources = [
      aws_ssm_parameter.lock_table.arn,
      aws_ssm_parameter.state_bucket.arn,
    ]
    sid = "ParameterAccess"
  }
}
data "aws_iam_policy_document" "state_manager" {
  version   = "2012-10-17"
  policy_id = "iac-state-manager"
  statement {
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.state.arn}/*"]
    sid       = "StateAccess"
  }
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.lock.arn]
    sid       = "Locking"
  }
}

resource "aws_iam_policy" "state_observer" {
  name        = local.state_observer_name
  description = "Allows reading the IaC state."
  policy      = data.aws_iam_policy_document.state_observer.json
}
resource "aws_iam_policy" "state_manager" {
  name        = local.state_manager_name
  description = "Allows writing the IaC state."
  policy      = data.aws_iam_policy_document.state_manager.json
}

data "aws_iam_policy_document" "s3_assume_role" {
  version   = "2012-10-17"
  policy_id = "s3-assume-role"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    sid = "S3AssumeRole"
  }
}
data "aws_iam_policy_document" "replication" {
  version   = "2012-10-17"
  policy_id = "replication"
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.state.arn]
    sid       = "SeeBucket"
  }
  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.state.arn}/*"]
    sid       = "GetVersioning"
  }
  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.replica.arn}/*"]
    sid       = "Replicate"
  }
  statement {
    actions   = ["kms:Decrypt"]
    effect    = "Allow"
    resources = [aws_kms_key.state.arn]
    sid       = "Decrypt"
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${aws_s3_bucket.state.arn}/*"]
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_replica_key.replica.arn]
    sid       = "ReEncrypt"
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${aws_s3_bucket.state.arn}/*"]
    }
  }
}

resource "aws_iam_policy" "replication" {
  name   = local.state_replication_name
  policy = data.aws_iam_policy_document.replication.json
}
resource "aws_iam_role" "replication" {
  name               = local.state_replication_name
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.state, aws_s3_bucket_versioning.replica]
  role       = aws_iam_role.replication.arn
  bucket     = local.state_bucket_name
  rule {
    id     = "main"
    status = "Enabled"
    source_selection_criteria {
      replica_modifications {
        status = "Disabled"
      }
      sse_kms_encrypted_objects {
        status = "Disabled"
      }
    }
    delete_marker_replication {
      status = "Disabled"
    }
    filter {}
    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"
      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.replica.arn
      }
      metrics {
        event_threshold {
          minutes = 15
        }
        status = "Enabled"
      }
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }
}

resource "aws_ssm_parameter" "state_bucket" {
  name        = local.state_bucket_name_pointer
  type        = "String"
  description = "Bucket used for IaC S3 backend deployment(s)."
  value       = local.state_bucket_name
  key_id      = aws_kms_key.ssm.id
}
resource "aws_ssm_parameter" "state_bucket_key" {
  name        = local.state_key_alias_pointer
  type        = "String"
  description = "KMS key used for S3 backend encryption."
  value       = local.state_key_alias
  key_id      = aws_kms_key.ssm.id
}
resource "aws_ssm_parameter" "lock_table" {
  name        = local.lock_name_pointer
  type        = "String"
  description = "DynamoDB locking table used for IaC S3 backend deployment(s)."
  value       = aws_dynamodb_table.lock.id
  key_id      = aws_kms_key.ssm.id
}
