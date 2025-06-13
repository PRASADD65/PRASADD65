variable "stage" {
  description = "Deployment stage (dev or prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default        = "VPC"
}

variable "az_name" {
  description = "Name of the az"
  type        = string
}

variable "github_repo_url" {
  description = "URL of the GitHub repository"
  type        = string
  default     = "https://github.com/techeazy-consulting/techeazy-devops.git" # Add your GitHub URL here
}

variable "key_name" {
  description = "Name of the AWS Key Pair to SSH into the instance"
  type        = string
}

variable "s3_bucket_name" {
  description = "The globally unique name for the S3 bucket where logs will be stored."
  type        = string
  # No default to enforce explicit naming, fulfilling the requirement
  # "name should be configurable; if not provided, terminate with error"
}

# New variable for instance shutdown time (full cron expression)
variable "shutdown_time" {
  description = "The cron expression (5 parts: Minute Hour DayOfMonth Month DayOfWeek) for when the EC2 instance should shut down and logs are backed up. E.g., '40 18 * * *' for 6:40 PM daily."
  type        = string
  validation {
    # Simple validation: ensure it's a non-empty string with at least 4 spaces (5 fields)
    condition     = length(regexall("\\s", var.shutdown_time)) == 4 && length(var.shutdown_time) > 0
    error_message = "Shutdown time must be a 5-part cron expression (e.g., '0 17 * * *')."
  }
}
