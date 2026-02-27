#!/bin/bash
set -e

# Update all packages
dnf update -y

# Install CloudWatch agent for metrics and logs
dnf install -y amazon-cloudwatch-agent

# Install Node.js (example runtime)
dnf install -y nodejs npm

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create environment file with database and cache endpoints
# These values come from Terraform templatefile() function
cat > /opt/app/.env << EOF
DB_PROXY_ENDPOINT=${db_proxy_endpoint}
REDIS_ENDPOINT=${redis_endpoint}
ENVIRONMENT=${environment}
EOF

# Create placeholder application
# In production, this would be your real app code
cat > /opt/app/server.js << 'EOF'
const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  
  // Health check endpoint for ALB
  // Returns 200 OK if app is running
  if (parsedUrl.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      status: 'healthy',
      timestamp: new Date().toISOString(),
      environment: process.env.ENVIRONMENT
    }));
  } else {
    // Default response
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hello from ' + process.env.ENVIRONMENT);
  }
});

// Listen on port 80 (HTTP)
const PORT = 80;
server.listen(PORT, () => {
  console.log(`Server running on port $${PORT}`);
});
EOF

# Start application in background
# nohup = no hang up (survives SSH disconnect)
# > /var/log/app.log = redirect output to log file
# 2>&1 = redirect errors to same file
# & = run in background
nohup node /opt/app/server.js > /var/log/app.log 2>&1 &

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "metrics": {
    "namespace": "App/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "totalcpu": true
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app.log",
            "log_group_name": "/app/${environment}/application",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json