resource "aws_iam_user" "data_bucket" {
  name = "${var.service_name}-${var.environment}-data_bucket"
  path = "/applicaton/${var.service_name}/"
}

resource "aws_iam_access_key" "data_bucket" {
  user = "${aws_iam_user.data_bucket.name}"
}

resource "aws_iam_user_policy" "data_bucket" {
  name = "data-bucket-access"
  user = "${aws_iam_user.data_bucket.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
          "${module.data.arn}",
	  "${module.data.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_user" "attachments_bucket" {
  name = "${var.service_name}-${var.environment}-attachments_bucket"
  path = "/applicaton/${var.service_name}/"
}

resource "aws_iam_access_key" "attachments_bucket" {
  user = "${aws_iam_user.attachments_bucket.name}"
}

resource "aws_iam_user_policy" "attachments_bucket" {
  name = "attachment-bucket-access"
  user = "${aws_iam_user.attachments_bucket.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
          "${module.attachments.arn}",
	  "${module.attachments.arn}/*"
      ]
    }
  ]
}
EOF
}
