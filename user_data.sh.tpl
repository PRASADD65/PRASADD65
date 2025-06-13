#!/bin/bash

# user_data.sh.tpl
# This script is a Terraform template for the EC2 user_data.
# It orchestrates the setup of the application, log backup, and scheduled shutdown.
# It sources environment-specific variables from the configs folder.

# IMPORTANT FIX: Ensure HOME environment variable is set as early as possible
export HOME=/root
set -e # Exit immediately if a command exits with a non-zero status
set -x # Print commands and their arguments as they are executed

echo "################################################################"
echo "# Starting EC2 User Data Script Orchestrator (from template) #"
echo "################################################################"

# --- 1. Inject Configuration File and Source It ---
# The 'stage' variable is passed from Terraform to select the correct config file.
CONFIG_FILE_PATH="/tmp/app_config.env"
cat << 'APP_CONFIG_EOF' > "$CONFIG_FILE_PATH"
${config_file_content}
APP_CONFIG_EOF

if [ -f "$CONFIG_FILE_PATH" ]; then
    echo "Sourcing configuration from $CONFIG_FILE_PATH"
    source "$CONFIG_FILE_PATH"
else
    echo "Error: Configuration file $CONFIG_FILE_PATH not found. Exiting."
    exit 1
fi
echo "Configuration variables sourced."
echo ""

# Now that the config file is sourced, the variables (REPO_URL, S3_BUCKET_NAME, SHUTDOWN_TIME)
# should be available as shell variables. We export them for subsequent scripts.
# We explicitly check and export them here to ensure they are available in the shell environment.
export REPO_URL
export S3_BUCKET_NAME
export SHUTDOWN_TIME

# Validate critical variables sourced from config
if [ -z "$S3_BUCKET_NAME" ]; then
  echo "Error: S3_BUCKET_NAME is not set in the sourced config. Exiting."
  exit 1
fi
if [ -z "$SHUTDOWN_TIME" ]; then
  echo "Error: SHUTDOWN_TIME is not set in the sourced config. Exiting."
  exit 1
fi
if [ -z "$REPO_URL" ]; then
  echo "Error: REPO_URL is not set in the sourced config. Exiting."
  exit 1
fi

# Derive REPO_DIR_NAME once after REPO_URL is available
export REPO_DIR_NAME=$(basename "$REPO_URL" .git)

echo "REPO_URL: ${REPO_URL}"
echo "S3_BUCKET_NAME: ${S3_BUCKET_NAME}"
echo "SHUTDOWN_TIME (cron format): ${SHUTDOWN_TIME}"
echo "REPO_DIR_NAME: ${REPO_DIR_NAME}"
echo ""

# --- 2. Install General Utilities (AWS CLI, Cron) ---
echo "--- Installing General Utilities (AWS CLI, Cron) ---"
sudo apt update -y # Ensure package list is up-to-date for installations
sudo apt install awscli cron -y

# Verify AWS CLI installation
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI installation failed. Cannot setup S3 backups. Exiting."
    exit 1
fi
echo "AWS CLI installed successfully."

# Verify Cron installation
if ! command -v cron &> /dev/null; then
    echo "Error: Cron installation failed. Cannot setup scheduled shutdown. Exiting."
    exit 1
fi
echo "Cron installed successfully."
echo ""

# --- 3. Deploy and Execute Core Application Setup Script (automate.sh) ---
echo "--- Deploying and Executing Core Application Setup Script ---"
AUTOMATE_SCRIPT_PATH="/usr/local/bin/automate_app_setup.sh" # Standard path for custom scripts

# Write the content of automate.sh to the file on EC2
cat << 'EOF_AUTOMATE_SCRIPT' | sudo tee "$AUTOMATE_SCRIPT_PATH" > /dev/null
${automate_sh_content}
EOF_AUTOMATE_SCRIPT

sudo chmod +x "$AUTOMATE_SCRIPT_PATH"
# Execute the application setup script. All needed variables are already exported.
sudo "$AUTOMATE_SCRIPT_PATH"
echo ""

# --- 4. Deploy Logs Off Script (logs_off.sh) ---
echo "--- Deploying Logs Off Script ---"
CRON_SCRIPT_PATH="/usr/local/bin/logs_off.sh" # Standard path for custom scripts

# Write the content of logs_off.sh to the file on EC2
cat << 'EOF_LOGS_OFF_SCRIPT' | sudo tee "$CRON_SCRIPT_PATH" > /dev/null
${logs_off_sh_content}
EOF_LOGS_OFF_SCRIPT

# Make the cron script executable
sudo chmod +x "$CRON_SCRIPT_PATH"
echo "logs_off.sh deployed to ${CRON_SCRIPT_PATH} and made executable."
echo ""

# --- 5. Setup Cron Job for Log Backup and Shutdown ---
echo "--- Setting up Cron Job ---"

# Use the full cron expression directly from the sourced config
CRON_SCHEDULE="${SHUTDOWN_TIME}"

# The CRON_COMMAND includes the env vars for the logs_off.sh script
CRON_COMMAND="S3_BUCKET_NAME=\"${S3_BUCKET_NAME}\" REPO_DIR_NAME=\"${REPO_DIR_NAME}\" ${CRON_SCRIPT_PATH} >> /var/log/cron.log 2>&1"

# Add cron job for the root user, ensuring it doesn't duplicate existing ones
(sudo crontab -l 2>/dev/null | grep -v "${CRON_SCRIPT_PATH}"; echo "${CRON_SCHEDULE} ${CRON_COMMAND}") | sudo crontab -

echo "Cron job scheduled using expression: '${CRON_SCHEDULE}' to run ${CRON_SCRIPT_PATH}."
echo "Cron logs will be in /var/log/cron.log"
echo ""

echo "################################################################"
echo "# All EC2 Setup Complete!                                    #"
echo "################################################################"
echo "Application deployed, logs configured for backup and scheduled shutdown."
