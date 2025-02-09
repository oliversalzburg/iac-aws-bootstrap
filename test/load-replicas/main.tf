data "aws_s3_object" "this" {
  provider = aws.replica
  bucket   = var.s3_bucket_replica
  key      = var.s3_key_flag
}
