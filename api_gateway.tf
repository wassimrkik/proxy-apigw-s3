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
    authorization = "NONE"
    api_key_required = false  
}

resource "aws_api_gateway_method" "get" {
    rest_api_id = aws_api_gateway_rest_api.pdf.id
    resource_id = aws_api_gateway_resource.object.id
    http_method = "GET"
    authorization = "NONE"
    api_key_required = false  
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id 
  resource_id = aws_api_gateway_method.put.id   
  http_method = aws_api_gateway_method.put.http_method
  integration_http_method = "PUT"
  type = "AWS"
  uri = "arn:aws:apigateway:ap-south-1:s3:path/"
  credentials = aws_iam_role.s3_full_access_role.arn
  }

resource "aws_iam_role" "s3_full_access_role" {
  name = "s3-full-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com" 
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_full_access_policy" {
  name = "s3-full-access-policy"

  description = "Provides full access to Amazon S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "s3:*",
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
  role       = aws_iam_role.s3_full_access_role.name
}