resource "aws_api_gateway_rest_api" "pdf" {
    name = "pdf_retrieve"
    binary_media_types = [ "*/*" ]
     endpoint_configuration {
       types = ["REGIONAL"]
     }
}

resource "aws_api_gateway_resource" "folder" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id
  parent_id = aws_api_gateway_rest_api.pdf.root_resource_id
  path_part = "{folder}"
}

resource "aws_api_gateway_resource" "object" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id
  parent_id = aws_api_gateway_resource.folder.id
  path_part = "{object}"
}

resource "aws_api_gateway_method" "put" {
    rest_api_id = aws_api_gateway_rest_api.pdf.id
    resource_id = aws_api_gateway_resource.object.id
    http_method = "PUT"
    authorization = "AWS_IAM"
    api_key_required = false  
}

resource "aws_api_gateway_method" "get" {
    rest_api_id = aws_api_gateway_rest_api.pdf.id
    resource_id = aws_api_gateway_resource.object.id
    http_method = "GET"
    authorization = "AWS_IAM"
    api_key_required = false  
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id 
  resource_id = aws_api_gateway_resource.object.id   
  http_method = aws_api_gateway_method.put.http_method
  integration_http_method = "PUT"
  type = "AWS"
  uri         = "arn:aws:apigateway:ap-south-1:s3:path//"
  credentials = aws_iam_role.s3_api_gateway_role.arn
  }

  resource "aws_api_gateway_integration" "S3GetIntegration" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id 
  resource_id = aws_api_gateway_resource.object.id   
  http_method = aws_api_gateway_method.get.http_method
  integration_http_method = "GET"
  type = "AWS"
  uri         = "arn:aws:apigateway:ap-south-1:s3:path//"
  credentials = aws_iam_role.s3_api_gateway_role.arn
  }

resource "aws_iam_policy" "s3_policy" {
  name        = "s3-policy"
  description = "Policy for allowing all S3 Actions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

# Create API Gateway Role
resource "aws_iam_role" "s3_api_gateway_role" {
  name = "s3-api-gateway-role"

  # Create Trust Policy for API Gateway
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach S3 Access Policy to the API Gateway Role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.s3_api_gateway_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}