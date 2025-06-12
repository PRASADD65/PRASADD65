#!/bin/bash

echo "📦 Installing Git..."
apt-get update -y && apt-get install git -y

echo "📦 Installing Node.js and npm..."
apt-get install -y curl gnupg ca-certificates apt-transport-https
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "📦 Installing Java..."
wget -q https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
apt install -y ./jdk-21_linux-x64_bin.deb

echo "📂 Cloning repository..."
git clone https://github.com/PRASADD65/devops-java-sample-app.git /opt/app

echo "⚙️ Writing config.json..."
cat <<EOF > /opt/app/config.json
${config_file}
EOF

echo "⚙️ Building Java project..."
cd /opt/app
chmod +x mvnw || true
./mvnw package || exit 1

echo "🚀 Running app on port 80..."
nohup java -jar target/*.jar > /opt/app/app.log 2>&1 &

echo "⏳ Scheduling shutdown in 1 hour..."
apt-get install -y at
echo "shutdown -h now" | at now + 60 minutes

echo "✅ Bootstrap completed."
