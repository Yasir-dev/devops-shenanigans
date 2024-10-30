# Set up Netdata for Performance Monitoring of Ubuntu Server with NGINX Reverse Proxy and basic Authentication

Netdata is a powerful, real-time performance monitoring solution designed for systems and applications. It provides detailed insights into system metrics including CPU usage, memory consumption, disk activity, network traffic, and application-specific metrics with minimal overhead.

## Ubuntu server setup

I am using a Digital Ocean droplet with Ubuntu as OS

**IMPORTANT:** Due to high privileges, it is not recommended to use root user on a regular basis, so we will create a normal user with sudo privileges.

### Creating a new user

Login with ssh as root user to create a new user

```
ssh root@your_droplet_ip
```

### Creating a new user

```
adduser <newusername>
```

#### Give new user Admin permissions

```
usermod -aG sudo <newusername>
```

#### Verify that the user is now sudo group

```
getent group sudo
```

### Remove password restriction for new user

You now have to remove the password restriction for sudo for the `<newusername>` user. start the sudo editor

```
sudo visudo
```

This will open in nano, if you want to use vi you do it with this command:

```
sudo update-alternatives --config editor
```

Now add the following to the bottom of the file (use this with care and never allow for untrusted user, only allow for trusted user and for deploy scripts in CI/CD)

```
<newusername> ALL=(ALL) NOPASSWD: ALL
```

#### Setup the firewall for SSH access

Preview the list of installed UFW profiles:

```
ufw app list
```

Allow OpenSSH

```
ufw allow OpenSSH
```

Enable the firewall

```
ufw enable
```

Verify that if SSH connection are allowed now

```
ufw status
```

#### Enable SSH access of newly created User

Logged in as root user we need to copy the local public key to `~/.ssh/authorized_keys` of the new user

 ```
rsync --archive --chown=<newusername>:<newusername> ~/.ssh /home/<newusername>
 ```

The above command copies the root user’s .ssh directory, retains the permissions, and changes the file owners-all in a single command


### Install and Setup Netadata

#### SSH login as a newly created user

`ssh <newusername>@your_droplet_ip`

#### Install Netdata

```
apt update
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

#### Verify that is is running

```
systemctl status netdata
```

Netdata by default listens on port 19999. If your server has firewall enabled, then you need to open TCP port 19999.

```
sudo ufw allow 19999/tcp
```

Verify

```
sudo ufw status
```

Now the netadata should be accessable via this URL:

```
http://server-ip:19999
```

You can get the public IP using this command


```
curl -4 icanhazip.com
```

### Set Up Reverse Proxy

Accessing Netdata directly via IP exposes it to the public internet, posing security risks. Use an Nginx reverse proxy with authentication to secure the interface. Nginx can also handle SSL/TLS encryption and restrict access to specific IPs or networks, enhancing security.

#### Install NGINX


```
sudo apt install nginx
```

#### Adjust the Firewall

```
sudo ufw allow 'Nginx Full'
```

The above command allows full access to Nginx through the firewall, enabling both HTTP (port 80) and HTTPS (port 443) traffic.

Verify the firewall status:

```
sudo ufw status
````

Verify the firewall status:

```
sudo ufw status
````

After Nginx is installed, create a virtual host config file for netdata under `/etc/nginx/conf.d/` directory

```
sudo touch /etc/nginx/conf.d/netdata.conf
```

```
upstream backend {
   server 127.0.0.1:19999;
   keepalive 64;
}

server {
   listen 80;
   server_name netdata.example.com;

   location / {
     proxy_set_header X-Forwarded-Host $host;
     proxy_set_header X-Forwarded-Server $host;
     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_pass http://backend;
     proxy_http_version 1.1;
     proxy_pass_request_headers on;
     proxy_set_header Connection "keep-alive";
     proxy_store off;
   }
}
```

Save and close this file. Then test Nginx configuration.

```
sudo nginx -t
```

Restart the NGINX service

```
sudo systemctl restart nginx
```

IMPORTANT: Do not forget to add a A record on your domain registry and point to the ip of your server

#### Listen on Localhost Only (netadata)


```
sudo vi /opt/netdata/etc/netdata/netdata.conf
```

Go to the [web] section and find the following line

```
# bind to = *
```

Remove the # sign and set its value to 127.0.0.1.

```
sudo systemctl restart netdata
````

Now you should be able to view the neta data via the URL:

```
http://netdata.example.com
```

#### Enable HTTPS

Install Let’s Encrypt client (certbot)

```
sudo apt install certbot
```

Install the Certbot Nginx plugin

```
sudo apt install python3-certbot-nginx
```

Obtain and install TLS certificate.

```
sudo certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email you@example.com -d netdata.example.com
````

Now you should be able to view the neta data via the https:

```
https://netdata.example.com
```

#### Enable Password Authentication

Generate a password file:

```
printf "yourusername:$(openssl passwd -6 'yourpassword')" | sudo tee -a /etc/nginx/passwords
```

Then edit the Nginx virtual host config file for netdata.

```
sudo vi /etc/nginx/conf.d/netdata.conf
```

Add the auth directives in server section

```
server {
.....

auth_basic "Protected";
auth_basic_user_file /etc/nginx/passwords;

....
```

Save and close this file. Then test Nginx configuration.

```
sudo nginx -t
```

Restart the NGINX service

```
sudo systemctl restart nginx
```

Now the browser will ask for the username and password.

### Add alert and Slack Notification

To configure an alert for CPU usage, add a new alert configuration


```
sudo vi  /opt/netdata/etc/netdata/health.d/cpu_usage.conf
```

Add the following

```
alarm: cpu_usage
on: system.cpu
lookup: average -1m unaligned of user,system,softirq,irq,guest
every: 1m
warn: $this > 80
crit: $this > 90
info: CPU utilization over 80%
```

This alert monitors the CPU usage of the system. It checks the average CPU usage over the last minute, including user, system, softirq, irq, and guest usage. The alarm triggers a warning if the CPU usage exceeds 80% and a critical alert if it exceeds 90%. The info message indicates that CPU utilization is over 80%.

you can read more about alerts [here](https://learn.netdata.cloud/docs/alerts-&-notifications/alert-configuration-reference)

### Add Slack Notification

```
cd /opt/netdata/etc/netdata
sudo ./edit-config health_alarm_notify.conf
```

Add the configuration:

```
#------------------------------------------------------------------------------
# slack (slack.com) global notification options

SEND_SLACK="YES"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXXXXXXX/XXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" 
DEFAULT_RECIPIENT_SLACK="#alarms"
```


#### Stress test the system to check netdata dashboard and Slack Notifications

```
sudo apt install stress-ng
```

Run 4 CPU, 2 virtual memory, 1 disk and 8 fork stressors for 2 minutes and print measurements:

```
stress-ng --cpu 4 --vm 2 --hdd 1 --fork 8 --timeout 2m --metrics
```

You can read more about stress-ng [here](https://github.com/ColinIanKing/stress-ng)


You should now see the matrix changing on your dashboard and you should receive Slack Notification.


## Automate everything as a script

To automate the entire setup process, you can use the `netdata-setup.sh` script. This script will handle the installation and configuration of Netdata, NGINX, SSL, and Slack notifications.

### Usage

The script requires several parameters to be passed as arguments. Below is the usage information:

```
sudo ./netdata-setup.sh \
  -d "netdata.yourdomain.com" \
  -e "your-email@example.com" \
  -n "netdata-user" \
  -p "netdata-password" \
  -w "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
  -c "#monitoring"
```

This script can also be used in the CI pipeline using Github Actions & GitLab CI

## Prerequisites for Running the Script from CI Pipeline

Before running the `netdata-setup.sh` script from a CI pipeline, ensure the following prerequisites are met:

1. **Secret Key Management**:
   - Store sensitive information such as passwords, Slack webhook URLs, and email addresses as secrets in your CI/CD platform (e.g., GitHub Secrets, GitLab CI/CD Variables).

2. **Copying SSH Key to the Target Server**:
   - Ensure you have an SSH key pair set up for secure access to the target server.
   - Add the public SSH key to the `~/.ssh/authorized_keys` file on the target server.
   - Store the private SSH key as a secret in your CI/CD platform.

3. **Domain Name A Record**:
   - Ensure that the domain name's A record points to the IP address of your target server.
   - This is necessary for the SSL certificate setup and for accessing the Netdata dashboard.




