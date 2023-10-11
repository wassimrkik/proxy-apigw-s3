resource "aws_api_gateway_rest_api" "pdf" {
  name               = "pdf_retrieve"
  binary_media_types = ["*/*"]
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "folder" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id
  parent_id   = aws_api_gateway_rest_api.pdf.root_resource_id
  path_part   = "{folder}"
}

resource "aws_api_gateway_resource" "object" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id
  parent_id   = aws_api_gateway_resource.folder.id
  path_part   = "{object}"
}

resource "aws_api_gateway_method" "put" {
  rest_api_id      = aws_api_gateway_rest_api.pdf.id
  resource_id      = aws_api_gateway_resource.object.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.object" = true
    "method.request.path.folder" = true
  }
}

resource "aws_api_gateway_method" "get" {
  rest_api_id      = aws_api_gateway_rest_api.pdf.id
  resource_id      = aws_api_gateway_resource.object.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.object" = true
    "method.request.path.folder" = true

  }
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id             = aws_api_gateway_rest_api.pdf.id
  resource_id             = aws_api_gateway_resource.object.id
  http_method             = aws_api_gateway_method.put.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  ##### needs credentials for s3 integration
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/{bucket}/{key}"
  credentials             = aws_iam_role.s3_api_gateway_role.arn
  request_parameters = {
    ################## URL QUERY STRING PARAMETERES ###########################
    # "integration.request.querystring.key" = "method.request.querystring.object"
    # "integration.request.querystring.bucket" = "method.request.querystring.folder"
    ################## URL PATH PARAMETER PARAMETERES ###########################
    "integration.request.path.bucket" = "method.request.path.folder"
    "integration.request.path.key" = "method.request.path.object"
  }
}

resource "aws_api_gateway_integration" "S3GetIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.pdf.id
  resource_id             = aws_api_gateway_resource.object.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/{bucket}/{key}"
  credentials             = aws_iam_role.s3_api_gateway_role.arn
  request_parameters = {
    ################## URL QUERY STRING PARAMETERES ###########################
    # "integration.request.querystring.key" = "method.request.querystring.object"
    # "integration.request.querystring.bucket" = "method.request.querystring.folder"
    ################## URL PATH PARAMETER PARAMETERES ###########################
    "integration.request.path.bucket" = "method.request.path.folder"
    "integration.request.path.key" = "method.request.path.object"
  }
}

resource "aws_api_gateway_stage" "S3stage" {
  deployment_id = aws_api_gateway_deployment.S3APIDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.pdf.id
  stage_name    = "dev"
}
resource "aws_api_gateway_deployment" "S3APIDeployment" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.pdf.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  stage_description = timestamp()
  description = "Deployed aty ${timestamp()}"
}


resource "aws_api_gateway_method_response" "get_response" {
    rest_api_id = aws_api_gateway_rest_api.pdf.id  
    resource_id = aws_api_gateway_resource.object.id
    http_method = aws_api_gateway_method.get.http_method
    status_code = "200"
    response_parameters = {
    "method.response.header.content-Type"   = true
  }
    response_models = {
    "application/json" = "Empty"
  }  
  
}

resource "aws_api_gateway_integration_response" "get_int_response" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id  
  resource_id = aws_api_gateway_resource.object.id  
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.get_response.status_code
  response_parameters = {
    "method.response.header.content-Type"   = "'application/pdf'"
  }

}

resource "aws_api_gateway_method_response" "put_response" {
    rest_api_id = aws_api_gateway_rest_api.pdf.id  
    resource_id = aws_api_gateway_resource.object.id
    http_method = aws_api_gateway_method.put.http_method
    status_code = "200"
    response_models = {
    "application/json" = "Empty"
  }  
  
}

resource "aws_api_gateway_integration_response" "put_int_response" {
  rest_api_id = aws_api_gateway_rest_api.pdf.id  
  resource_id = aws_api_gateway_resource.object.id  
  http_method = aws_api_gateway_method.put.http_method
  status_code = aws_api_gateway_method_response.put_response.status_code

}