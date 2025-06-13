# ec2.tf

resource "aws_instance" "app_instance" {
  ami                         = "ami-07891c5a242abf4bc" # REMEMBER TO REPLACE THIS WITH YOUR REGION'S UBUNTU AMI ID
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  # Attach the IAM Instance Profile to this EC2 instance
  iam_instance_profile = aws_iam_instance_profile.app_instance_profile.name

  # Assemble the user_data script:
  # 1. Set HOME variable explicitly at the very beginning.
  # 2. Inject the config file content and source it.
  # 3. Append the main automation script (automate.sh).
  user_data = <<-EOF
    #!/bin/bash

    # IMPORTANT FIX: Ensure HOME environment variable is set as early as possible
    export HOME=/root

    # This section injects the content of your config file and sources it.
    CONFIG_FILE_PATH="/tmp/app_config.env"
    cat << 'APP_CONFIG_EOF' > "$CONFIG_FILE_PATH"
    ${file("${path.module}/configs/${var.stage}_config")}
    APP_CONFIG_EOF

    if [ -f "$CONFIG_FILE_PATH" ]; then
        echo "Sourcing configuration from $CONFIG_FILE_PATH"
        source "$CONFIG_FILE_PATH"
    else
        echo "Error: Configuration file $CONFIG_FILE_PATH not found. This should not happen if Terraform passes it correctly. Exiting."
        exit 1
    fi
    echo ""

    # Now, append the content of the main automate.sh script.
    ${file("${path.module}/automate.sh")}
    EOF

  depends_on = [
    module.vpc,
    aws_security_group.web_sg,
    aws_iam_instance_profile.app_instance_profile # Ensure IAM profile is created before attaching
  ]

  tags = {
    Name = "${var.stage}-${var.instance_name}"
  }
}
