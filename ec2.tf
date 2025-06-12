resource "aws_instance" "app_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Example AMI ID
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = module.vpc.public_subnets[0]
  depends_on    = [
    module.vpc,
    aws_security_group.web_sg
  ]
  user_data = templatefile("${path.module}/automate.sh.tmpl", {
    config_file = "configs/${local.config_file}"
  })

  tags = {
    Name = "${var.stage}-${var.instance_name}"
  }
}
