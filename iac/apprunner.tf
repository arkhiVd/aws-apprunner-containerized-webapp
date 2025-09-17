resource "aws_ecr_repository" "app_repo" {
  name                 = "portfolio-app-runner-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_iam_role" "apprunner_ecr_role" {
  name = "PortfolioAppRunnerECRAccessRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "build.apprunner.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_apprunner_service" "main" {
  service_name = "portfolio-showcase-app"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
    image_repository {
      image_identifier      = var.docker_image_url
      image_repository_type = "ECR"
      image_configuration {
        port = "8080"
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "256" 
    memory = "512"
  }

  health_check_configuration {
    protocol = "TCP"
    path     = "/"
  }
}

resource "aws_apprunner_custom_domain_association" "main" {
  domain_name = "app.${var.domain_name}"
  service_arn = aws_apprunner_service.main.arn
}


data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "app_cname" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_apprunner_custom_domain_association.main.dns_target]
}


output "apprunner_default_url" {
  description = "The default URL of the App Runner service"
  value       = aws_apprunner_service.main.service_url
}

output "final_application_url" {
  description = "The final, public URL of the application"
  value       = "https://app.${var.domain_name}"
}
