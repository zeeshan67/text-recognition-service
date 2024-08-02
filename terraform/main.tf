provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "lambda-api-gateway"
    }
  }
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "text-recognition-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_text_recognition" {
  type        = "zip"
  source_dir  = "${path.module}/../app/handlers"
  output_path = "${path.module}/../app/handlers.zip"
}

resource "aws_s3_object" "lambda_text_recognition" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "handlers.zip"
  source = data.archive_file.lambda_text_recognition.output_path
  etag   = filemd5(data.archive_file.lambda_text_recognition.output_path)
}

resource "aws_lambda_layer_version" "tesseract_layer" {
  layer_name          = "TesseractLayer"
  compatible_runtimes = [
    "python3.8",
    "python3.9",
    "python3.10",
    "python3.11",
  ]

  filename = "${path.module}/../tesseract/tesseract_layer.zip"
  source_code_hash = filebase64sha256("${path.module}/../tesseract/tesseract_layer.zip")
}

resource "aws_lambda_function" "gateway_handler" {
  function_name = "GatewayLambda"
  description   = "Acts as a proxy, invokes text recognition lambda by passing base64 image and returning text response."
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_text_recognition.key
  runtime       = "python3.11"
  handler       = "gateway_handler.handler"
  source_code_hash = data.archive_file.lambda_text_recognition.output_base64sha256
  role          = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function" "text_recognition_handler" {
  function_name = "TextRecognitionLambda"
  description   = "Processes base64 image and extracts text using Textract."
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_text_recognition.key
  runtime       = "python3.11"
  handler       = "text_recognition.handler"
  source_code_hash = data.archive_file.lambda_text_recognition.output_base64sha256
  role          = aws_iam_role.lambda_exec.arn
  layers = [
    aws_lambda_layer_version.tesseract_layer.arn
  ]
}

resource "aws_lambda_permission" "allow_gateway_to_invoke_text_recognition" {
  statement_id  = "AllowGatewayLambdaToInvokeTextRecognitionLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_recognition_handler.function_name
  principal     = "lambda.amazonaws.com"

  source_arn    = aws_lambda_function.gateway_handler.arn
}

resource "aws_iam_policy" "invoke_text_recognition_policy" {
  name        = "InvokeTextRecognitionPolicy"
  description = "Policy to allow invoking the Text Recognition Lambda function"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = aws_lambda_function.text_recognition_handler.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_invoke_policy" {
  policy_arn = aws_iam_policy.invoke_text_recognition_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_cloudwatch_log_group" "gateway_handler_logs" {
  name              = "/aws/lambda/${aws_lambda_function.gateway_handler.function_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "image_processing_handler_logs" {
  name              = "/aws/lambda/${aws_lambda_function.text_recognition_handler.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "textract_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonTextractFullAccess"
}

# Optional: Bucket policy to allow Lambda functions to read from the bucket
resource "aws_s3_bucket_policy" "lambda_bucket_policy" {
  bucket = aws_s3_bucket.lambda_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "s3:GetObject"
      Resource = "${aws_s3_bucket.lambda_bucket.arn}/*"
    }]
  })
}


# API Gateway configuration
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

resource "aws_apigatewayv2_integration" "gateway_integration" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = aws_lambda_function.gateway_handler.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "gateway_route" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "POST /recognize" # Change this to your desired route
  target    = "integrations/${aws_apigatewayv2_integration.gateway_integration.id}"
}


resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gateway_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}