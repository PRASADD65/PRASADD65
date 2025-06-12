#!/bin/bash

# Log everything for future debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "==========================="
echo "🚀 Starting EC2 Bootstrap..."
echo "==========================="

# Update packages
apt update -y

# Install Java 21
echo "📦 Installing Java 21..."
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
apt install -y ./jdk-21_linux-x64_bin.deb
java -version

# Install Git
echo "📦 Installing Git..."
apt install -y git

# Install Node.js and npm (via NodeSource)
echo "📦 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
node -v
npm -v

# Clone the repo
echo "📂 Cloning repository..."
git clone https://github.com/techeazy-consulting/techeazy-devops.git /opt/app
cd /opt/app

# Inject stage-based config
echo "⚙️ Applying stage config file..."
cp "${config_file}" /opt/app/config.json

# Build Java app using Maven Wrapper
echo "⚙️ Building the Java project..."
./mvnw clean package

# Run the Java app (from target dir)
echo "🚀 Running the app on port 80..."
nohup java -jar target/*.jar --server.port=80 &

# Schedule shutdown in 1 hour
echo "⏳ Scheduling instance shutdown in 1 hour..."
apt install -y at
echo "shutdown -h now" | at now + 60 minutes

echo "✅ Bootstrap completed."
