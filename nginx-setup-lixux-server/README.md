# Set up NGINX on a Linux Server

Follow the steps from [here](./../nginx-setup-lixux-server/README.md) and do the following:

1. Set up a remote linux server
2. Setup SSH
3. Create new user with sudo permissions
4. Set up firewall for SSH so non root user can login via SSH

Once above steps are done login to the server via SSH and install the NGINX:

```
sudo apt update
sudo apt install nginx
```

## Adjust the Firewall

Before testing Nginx, the firewall software needs to be configured to allow access to the service. Nginx registers itself as a service with ufw upon installation, making it straightforward to allow Nginx access. The can be verified by this command:

```
sudo ufw app list
```

Example output from the above command:

```
Output
Available applications:
  Nginx Full
  Nginx HTTP
  Nginx HTTPS
  OpenSSH
```

As shown by the output, there are three profiles available for Nginx:

- Nginx Full: This profile opens both port 80 (normal, unencrypted web traffic) and port 443 (TLS/SSL encrypted traffic)
- Nginx HTTP: This profile opens only port 80 (normal, unencrypted web traffic)
- Nginx HTTPS: This profile opens only port 443 (TLS/SSL encrypted traffic)

Recommended is to enable: Nginx Full, but for demo purpose we will use only Nginx HTTP:

```
sudo ufw allow 'Nginx HTTP'
```

Verify the change:

```
sudo ufw status
```

## Check NGINX service status

```
systemctl status nginx
```

## Use icanhazip.com tool to determine the public IP of your linux Server

```
curl -4 icanhazip.com
```

## Enter the address in the browser

```
http://your_server_ip
```

Now you will see a NGINX standard page 🥳

