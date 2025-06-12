#!/bin/bash
set -e

echo "📦 Installing Git..."
apt-get update -y
apt-get install -y git

echo "📦 Installing Java..."
apt-get install -y openjdk-21-jdk

echo "📦 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "📂 Cloning repository..."
git clone https://github.com/yourusername/your-repo-name.git /opt/app

echo "⚙️ Applying stage config file..."
mkdir -p /opt/app/configs
cat <<EOF > /opt/app/configs/config.json
${config_file}
EOF

echo "⚙️ Building the Java project..."
cd /opt/app

# Ensure mvnw is executable if it exists
if [ -f "./mvnw" ]; then
  chmod +x ./mvnw
  ./mvnw clean package
else
  mvn clean package
fi

echo "🚀 Running the app on port 80..."
JAR_FILE=$(find target -name "*.jar" | head -n 1)
if [ -f "$JAR_FILE" ]; then
  nohup java -jar "$JAR_FILE" > /var/log/app.log 2>&1 &
else
  echo "❌ JAR file not found. Build may have failed."
  exit 1
fi

# Optional: Shut down after 1 hour
echo "⏳ Scheduling instance shutdown in 1 hour..."
apt-get install -y at
echo "shutdown -h now" | at now + 60 minutes

echo "✅ Bootstrap completed."
