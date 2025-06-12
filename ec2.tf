resource "aws_instance" "app_instance" {
  ami                         = "ami-0a89b8a7f72b9cb5d" # Use your region-specific AMI
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = templatefile("${path.module}/automate.sh.tmpl", {
    config_file = file("${path.module}/configs/dev_config.json")
  })

  depends_on = [
    module.vpc,
    aws_security_group.web_sg
  ]

  tags = {
    Name = "${var.stage}-${var.instance_name}"
  }
}
