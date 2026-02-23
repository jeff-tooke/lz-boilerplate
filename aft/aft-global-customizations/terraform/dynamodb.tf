################################################################################
# DynamoDB Table — Terraform State Locking (Primary Region)
#
# DynamoDB streams are enabled from the start. This allows the Standard
# account customisation to add a Global Table DR replica in eu-west-1 for
# high-criticality accounts without recreating the table (a DynamoDB table
# without streams cannot be converted to a Global Table).
################################################################################

resource "aws_dynamodb_table" "locks" {
  name         = local.dynamodb_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.account.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.dynamodb_name
    }
  )

  depends_on = [aws_kms_key.account]
}
