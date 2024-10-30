#!/bin/bash

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Enable debug logging for CI
if [ "${CI:-false}" = "true" ]; then
    set -x
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 -u USERNAME -d DOMAIN -e EMAIL -n NETDATA_USER -p NETDATA_PASSWORD [-w SLACK_WEBHOOK_URL] [-c SLACK_CHANNEL]"
    echo
    echo "Required arguments:"
    echo "  -u USERNAME         New username"
    echo "  -d DOMAIN          Domain (e.g., netdata.example.com)"
    echo "  -e EMAIL           Email for SSL certificate"
    echo "  -n NETDATA_USER    Username for Netdata access"
    echo "  -p NETDATA_PASSWORD Password for Netdata access"
    echo
    echo "Optional arguments:"
    echo "  -w SLACK_WEBHOOK_URL Slack webhook URL"
    echo "  -c SLACK_CHANNEL     Slack channel (default: #alarms)"
    exit 1
}

# Parse command line arguments
while getopts "u:d:e:n:p:w:c:h" opt; do
    case $opt in
        u) NEW_USERNAME="$OPTARG" ;;
        d) DOMAIN="$OPTARG" ;;
        e) EMAIL="$OPTARG" ;;
        n) NETDATA_USER="$OPTARG" ;;
        p) NETDATA_PASSWORD="$OPTARG" ;;
        w) SLACK_WEBHOOK_URL="$OPTARG" ;;
        c) SLACK_CHANNEL="$OPTARG" ;;
        h) show_usage ;;
        ?) show_usage ;;
    esac
done

# Verify required parameters
if [ -z "${NEW_USERNAME:-}" ] || [ -z "${DOMAIN:-}" ] || [ -z "${EMAIL:-}" ] || [ -z "${NETDATA_USER:-}" ] || [ -z "${NETDATA_PASSWORD:-}" ]; then
    echo "Error: Missing required parameters"
    show_usage
fi

# Set default Slack channel if not provided
SLACK_CHANNEL=${SLACK_CHANNEL:-"#alarms"}

# Function to log steps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check command success
check_command() {
    if [ $? -eq 0 ]; then
        log "✅ $1 successful"
    else
        log "❌ $1 failed"
        exit 1
    fi
}

# Main setup function
setup_netdata() {
    log "Starting Netdata setup..."

    # Check if running as root/sudo
    if [ "$(id -u)" -ne 0 ]; then
        log "Error: This script must be run as root or with sudo"
        exit 1
    fi

    # Update system
    log "Updating system packages..."
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    check_command "System update"

    # Install required packages
    log "Installing required packages..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx certbot python3-certbot-nginx stress-ng
    check_command "Package installation"

    # Install Netdata
    log "Installing Netdata..."
    curl -Ss https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh
    sh /tmp/netdata-kickstart.sh --non-interactive
    check_command "Netdata installation"

    # Configure firewall
    log "Configuring firewall..."
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    ufw --force enable
    check_command "Firewall configuration"

    # Create Nginx configuration
    log "Configuring Nginx..."
    cat > /etc/nginx/conf.d/netdata.conf << EOF
upstream backend {
    server 127.0.0.1:19999;
    keepalive 64;
}

server {
    listen 80;
    server_name ${DOMAIN};

    auth_basic "Protected";
    auth_basic_user_file /etc/nginx/passwords;

    location / {
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_pass_request_headers on;
        proxy_set_header Connection "keep-alive";
        proxy_store off;
    }
}
EOF
    check_command "Nginx configuration"

    # Create password file for basic auth
    log "Setting up authentication..."
    printf "${NETDATA_USER}:$(openssl passwd -6 ${NETDATA_PASSWORD})\n" | tee /etc/nginx/passwords > /dev/null
    check_command "Authentication setup"

    # Configure Netdata to listen only on localhost
    log "Configuring Netdata..."
    sed -i 's/# bind to = \*/bind to = 127.0.0.1/g' /opt/netdata/etc/netdata/netdata.conf
    check_command "Netdata configuration"

    # Set up SSL
    log "Setting up SSL..."
    certbot --nginx --agree-tos --redirect --hsts --staple-ocsp \
        --email "${EMAIL}" -d "${DOMAIN}" --non-interactive
    check_command "SSL setup"

    # Configure CPU usage alert
    log "Setting up monitoring alerts..."
    cat > /etc/netdata/health.d/cpu_usage.conf << EOF
alarm: cpu_usage
on: system.cpu
lookup: average -1m unaligned of user,system,softirq,irq,guest
every: 1m
warn: \$this > 80
crit: \$this > 90
info: CPU utilization over 80%
EOF
    check_command "Alert configuration"

    # Configure Slack notifications if webhook URL is provided
    if [ ! -z "${SLACK_WEBHOOK_URL:-}" ]; then
        log "Configuring Slack notifications..."
        sed -i "s/SEND_SLACK=\"NO\"/SEND_SLACK=\"YES\"/" /etc/netdata/health_alarm_notify.conf
        sed -i "s#SLACK_WEBHOOK_URL=\"\"#SLACK_WEBHOOK_URL=\"${SLACK_WEBHOOK_URL}\"#" /etc/netdata/health_alarm_notify.conf
        sed -i "s/DEFAULT_RECIPIENT_SLACK=\"\"/DEFAULT_RECIPIENT_SLACK=\"${SLACK_CHANNEL}\"/" /etc/netdata/health_alarm_notify.conf
        check_command "Slack notification setup"
    fi

    # Restart services
    log "Restarting services..."
    systemctl restart netdata
    systemctl restart nginx
    check_command "Service restart"

    log "Setup completed successfully! ✨"
    log "You can now access Netdata at: https://${DOMAIN}"
    log "Username: ${NETDATA_USER}"
    log "Important:"
    log "1. Ensure DNS A record points ${DOMAIN} to your server IP"
    log "2. Test the setup by accessing https://${DOMAIN}"
}

# Main execution
setup_netdata