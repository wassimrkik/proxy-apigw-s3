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
  uri         = "arn:aws:apigateway:${var.aws_region}:s3:path//"
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

