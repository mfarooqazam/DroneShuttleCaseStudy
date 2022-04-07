resource "aws_kms_key" "s3_backend_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "s3_backend_key_alias" {
  name          = "alias/TerraformBackend"
  target_key_id = aws_kms_key.s3_backend_key.key_id
}

resource "aws_s3_bucket" "aws_s3_bucket_backend" {
  bucket = "${var.stack_name}-${data.aws_caller_identity.current.account_id}-backend"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_backend_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_locking_dynamodb" {
  name           = "${var.stack_name2}-backend"
  hash_key       = "LockID"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }
}