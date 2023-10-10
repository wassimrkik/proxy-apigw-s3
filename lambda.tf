

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "authorizer" {
  filename         = "lambda_function_payload.zip"
  function_name    = "pdf_authorizer"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.8"
  layers = [aws_lambda_layer_version.cryptography.arn, aws_lambda_layer_version.jwt.arn, aws_lambda_layer_version.requests.arn]

}
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/pdf_authorizer"
  retention_in_days = 14
}
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_layer_version" "jwt" {
  filename            = "p38-PyJWT.zip"
  layer_name          = "p38-PyJWT"
  compatible_runtimes = ["python3.8"]

}


resource "aws_lambda_layer_version" "requests" {
  filename            = "p38-requests.zip"
  layer_name          = "p38-requests"
  compatible_runtimes = ["python3.8"]

}


resource "aws_lambda_layer_version" "cryptography" {
  filename            = "p38-cryptography.zip"
  layer_name          = "p38-cryptography"
  compatible_runtimes = ["python3.8"]

}