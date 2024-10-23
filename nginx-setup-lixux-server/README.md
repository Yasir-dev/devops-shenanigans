# Set up NGINX on a Linux Server

Follow the steps from [here](./../ssh-digital-occean-setup/README.md) and do the following:

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

## Deploy changes of static HTML page via a shell script

The content of the page from `http://your_server_ip` are delivered from `/var/www/html/` folder which has the root user and group (this is not the best security practice). The web root files should be owned by a non-root user, typically the user that Nginx runs as. In most Linux distributions, Nginx runs under the www-data

### Verify the NGINX user:

  ```
  id www-data
  ```

### Add a new user for our deploy script:

  ```
  sudo adduser deploy
  ```
### Add this user to sudo

```
sudo usermod -aG sudo deploy
```

### Verify that is is now part of sudo

```
getent group sudo
```

### Remove password restriction for deploy user

You now have to remove the password restriction for sudo for the `deploy` user. start the sudo editor

```
sudo visudo
```

This will open in nano, if you want to use vi you do it with this command:

```
sudo update-alternatives --config editor
```

Now add the following to the bottom of the file (user this with care and never allow for untrusted user, only allow for trusted user and for deploy scripts in CI/CD)

```
deploy ALL=(ALL) NOPASSWD: ALL
```

### Copy the SSH public key, so the deploy user can deploy via SSH

```
sudo rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```

### Change the owner and group for NGINX `/var/www/html/` folder:
  
  ```
  sudo chown -R deploy:www-data /var/www/html
  ```

The above command make the deploy user as the owner of the folder and add the www-data group.

### Change the file permissions:

```
sudo chmod -R 755 /var/www/html
```

The above command allows deploy user to to change the content and www-data user to read the content

### Use the deploy script for deployment (from local/dev machine)

Make sure that the script is executable

```
chmod +x deploy.sh
```

deploy:
```
./deploy.sh
```
