data "aws_iam_policy_document" "log_assume" {
  count = module.this.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "log" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }
}

locals {
  log_region = length(var.region) > 0 ? var.region : data.aws_region.default.name
}

resource "aws_iam_role_policy" "log" {
  count  = module.this.enabled ? 1 : 0
  name   = module.vpc_label.id
  role   = aws_iam_role.log.id
  policy = data.aws_iam_policy_document.log.json
}

resource "aws_iam_role" "log" {
  count              = module.this.enabled ? 1 : 0
  name               = module.vpc_label.id
  assume_role_policy = data.aws_iam_policy_document.log_assume.json
}

data "aws_iam_policy_document" "kinesis_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [format("logs.%s.amazonaws.com", local.log_region)]
    }
  }
}

data "aws_iam_policy_document" "kinesis" {
  statement {
    actions = [
      "kinesis:PutRecord*",
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
    ]

    resources = [
      aws_kinesis_stream.default.arn,
    ]
  }
}

resource "aws_iam_role" "kinesis" {
  count              = module.this.enabled ? 1 : 0
  name               = module.kinesis_label.id
  assume_role_policy = data.aws_iam_policy_document.kinesis_assume.json
}

resource "aws_iam_role_policy" "kinesis" {
  count  = module.this.enabled ? 1 : 0
  name   = module.vpc_label.id
  role   = aws_iam_role.kinesis.id
  policy = data.aws_iam_policy_document.kinesis.json
}
