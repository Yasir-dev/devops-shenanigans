#!/bin/bash

# Exit on any error, undefined variable, or pipe failure
# -e: Exit immediately if a command exits with a non-zero status
# -u: Treat unset variables as an error when substituting
# -o pipefail: Return value of a pipeline is the status of the last command to exit with a non-zero status see https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euo pipefail

# Enable debug logging for CI
if [ "${CI:-false}" = "true" ]; then
    # Enable debug mode to print each command before execution
    set -x
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 -d DOMAIN -e EMAIL -n NETDATA_USER -p NETDATA_PASSWORD [-w SLACK_WEBHOOK_URL] [-c SLACK_CHANNEL]"
    echo
    echo "Required arguments:"
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
# getopts is a built-in bash command for parsing command line options/arguments
# The first argument "u:d:e:n:p:w:c:h" specifies valid options:
# - Letters followed by : expect an argument (stored in $OPTARG)
# - Letters without : are flags (no argument)
# The while loop processes each option one by one
while getopts "u:d:e:n:p:w:c:h" opt; do
    case $opt in
        # For each matched option letter, store its argument in a variable
        d) DOMAIN="$OPTARG" ;;         # -d domain.com
        e) EMAIL="$OPTARG" ;;          # -e email@example.com
        n) NETDATA_USER="$OPTARG" ;;   # -n username
        p) NETDATA_PASSWORD="$OPTARG" ;; # -p password
        w) SLACK_WEBHOOK_URL="$OPTARG" ;; # -w webhook_url
        c) SLACK_CHANNEL="$OPTARG" ;;  # -c channel_name
        h) show_usage ;;               # -h (show help)
        ?) show_usage ;;               # Invalid option
    esac
done

# Verify required parameters
# Check if any required parameters are empty/unset
# The ${VAR:-} syntax safely checks variables that may be unset (emmpty string is set as default)
# -z tests if the string length is zero
if [ -z "${DOMAIN:-}" ] || [ -z "${EMAIL:-}" ] || [ -z "${NETDATA_USER:-}" ] || [ -z "${NETDATA_PASSWORD:-}" ]; then
    # If any required parameter is missing, show error and usage instructions
    echo "Error: Missing required parameters"
    show_usage
fi

# Set default Slack channel if not provided
SLACK_CHANNEL=${SLACK_CHANNEL:-"#alarms"}

# Function to log steps
# Function to log messages with timestamp
# Takes a message string as input and prints it with the current date/time
# Example: log "Starting installation..." -> [2024-01-20 14:30:45] Starting installation...
log() {
    # Format: [YYYY-MM-DD HH:MM:SS] Message
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check command success
# Function to check if a command executed successfully
# Takes a message string as input and checks the exit status of the last command
# Logs success/failure and exits script if command failed
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
    # Use noninteractive frontend to prevent prompts during apt commands
    # Update package lists and upgrade all installed packages
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
    # Allow SSH access for remote management
    ufw allow OpenSSH
    # Allow HTTP/HTTPS traffic for Nginx
    ufw allow 'Nginx Full'
    # Enable firewall non-interactively
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
    # Generate a password hash using openssl with the provided NETDATA_PASSWORD
    # and create a new line in the /etc/nginx/passwords file with the format:
    # NETDATA_USER:hashed_password
    printf "${NETDATA_USER}:$(openssl passwd -6 ${NETDATA_PASSWORD})\n" | tee /etc/nginx/passwords > /dev/null
    check_command "Authentication setup"

    # Configure Netdata to listen only on localhost
    log "Configuring Netdata..."
    # The sed command is used to perform text transformations on a file.
    # -i: Edit the file in place.
    # 's/# bind to = \*/bind to = 127.0.0.1/g': The 's' stands for substitute.
    # The pattern between the first pair of slashes is the search pattern.
    # The pattern between the second pair of slashes is the replacement pattern.
    # The 'g' at the end stands for global, meaning all occurrences in the line will be replaced.
    # Special characters:
    #   - \* : Escapes the asterisk (*) character, which is a wildcard in regex.
    sed -i 's/# bind to = \*/bind to = 127.0.0.1/g' /opt/netdata/etc/netdata/netdata.conf
    check_command "Netdata configuration"

    # Set up SSL
    log "Setting up SSL..."
    # certbot: The command-line tool to obtain and manage SSL/TLS certificates from Let's Encrypt.
    # --nginx: Use the Nginx plugin for authentication and installation of the certificate.
    # --agree-tos: Agree to the terms of service automatically without prompting.
    # --redirect: Automatically redirect all HTTP traffic to HTTPS.
    # --hsts: Add the HTTP Strict Transport Security (HSTS) header to all HTTPS responses.
    # --staple-ocsp: Enable OCSP (Online Certificate Status Protocol) stapling.
    # --email "${EMAIL}": Email address for important account notifications and recovery.
    # -d "${DOMAIN}": The domain name for which the certificate is being requested.
    # --non-interactive: Run the command in non-interactive mode, suitable for scripts and automation.
    certbot --nginx --agree-tos --redirect --hsts --staple-ocsp \
        --email "${EMAIL}" -d "${DOMAIN}" --non-interactive
    check_command "SSL setup"

    # Configure CPU usage alert
    log "Setting up monitoring alerts..."
    cat > /opt/netdata/etc/netdata/health.d/cpu_usage.conf << EOF
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
        sed -i "s/SEND_SLACK=\"NO\"/SEND_SLACK=\"YES\"/" /opt/netdata/etc/netdata/health_alarm_notify.conf
        sed -i "s#SLACK_WEBHOOK_URL=\"\"#SLACK_WEBHOOK_URL=\"${SLACK_WEBHOOK_URL}\"#" /opt/netdata/etc/netdata/health_alarm_notify.conf
        sed -i "s/DEFAULT_RECIPIENT_SLACK=\"\"/DEFAULT_RECIPIENT_SLACK=\"${SLACK_CHANNEL}\"/" /opt/netdata/etc/netdata/health_alarm_notify.conf
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