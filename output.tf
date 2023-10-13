output "api" {
  value = "https://${aws_api_gateway_rest_api.pdf.id}-execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.stage_name}"
}