provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "sftp-file-transfer" {
  bucket_prefix = format("stp-file-transfer-%s", var.environment)
  acl           = "private"

  tags = {
    Name        = "sftp-file-transfer"
    Environment = var.environment
  }
  versioning {
    enabled = true
  }
}

resource "aws_iam_role" "sftp-file-role" {
  name = format("sftp-file-transfer-role-%s", var.environment)

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iampolicy" {
  name = format("sftp-file-transfer-policy-%s", var.environment)
  role = aws_iam_role.sftp-file-role.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "AllowFullAccesstoCloudWatchLogs",
        "Effect": "Allow",
        "Action": [
            "logs:*"
        ],
        "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_transfer_server" "sftp-server" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp-file-role.arn

  tags = {
    Name        = format("sftp-file-transfer-server-%s", var.environment)
    Environment = var.environment
  }
}

resource "aws_iam_role" "useriamrole" {
  name = format("user-iam-role-%s", var.environment)

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "userpolicy" {
  name = format("sftp-transfer-policy-%s", var.environment)
  role = aws_iam_role.useriamrole.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFullAccesstoS3",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_transfer_user" "sftpuser" {
  server_id = aws_transfer_server.sftp-server.id
  user_name = var.username
  role      = aws_iam_role.useriamrole.arn

  tags = {
    Name = format("sftp-user-name-%s", var.environment)
  }
  home_directory = format("/%s/%s", aws_s3_bucket.sftp-file-transfer.id, var.username)
}

resource "aws_transfer_ssh_key" "public-key-upload" {
  server_id = aws_transfer_server.sftp-server.id
  user_name = aws_transfer_user.sftpuser.user_name
  body      = file(var.public_key)
}