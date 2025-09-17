variable "domain_name" {
  type        = string
  description = "The custom domain name to use for the application"
}

variable "docker_image_url" {
  type        = string
  description = "The full URL of the Docker image from ECR. This is provided by the CI/CD pipeline"
  default     = null
}