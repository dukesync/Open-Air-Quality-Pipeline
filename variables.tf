variable "region_id" {
  description = "Neon project region"
  type        = string
  default     = "aws-eu-central-1" # Optimized for OpenAQ S3 bucket location
}

variable "org_id" {
  description = "Neon Organization ID"
  type        = string
}