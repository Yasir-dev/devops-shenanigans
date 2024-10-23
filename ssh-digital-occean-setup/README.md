# Setup SSH for a linux server

## Check if SSH is available

To check if a remote Linux server has SSH available, you can use the `nc` (netcat) command to test the connection to the SSH port (usually port 22). Here's how you can do it:

1. Open a terminal on your local machine.

2. Use the following command to test the SSH connection:

   ```
   nc -zv <server_ip_or_hostname> 22
   ```

   Replace `<server_ip_or_hostname>` with the actual IP address or hostname of the remote server.

   The `-zv` flag in the `nc` command has two parts:
   
   - `-z`: This option tells netcat to scan for listening daemons without sending any data. It's used for port scanning.
   - `-v`: This stands for "verbose" and makes netcat provide more detailed output about what it's doing.

   Together, these flags allow you to check if the SSH port is open and listening, while also providing informative output about the connection attempt.

3. If SSH is available, you'll see output similar to:

   ```
   Connection to <server_ip_or_hostname> 22 port [tcp/ssh] succeeded!
   ```

   If the connection fails, you'll see an error message instead.


## Setup SSH on a Linux Server (I am using Digital Ocean (any other cloud provider can be used) for setting up a simple linux server)

To set up SSH on a Linux server, specifically creating a simple Ubuntu Linux server droplet on DigitalOcean, follow these steps:

### Create the Droplet

1. Sign up or log in to your DigitalOcean account.

2. Click on the "Create" button in the top-right corner and select "Droplets" from the dropdown menu.

3. Choose your configuration:
   - Select "Ubuntu" as the distribution (latest LTS version recommended).
   - Choose a plan that fits your needs (Basic plans are suitable for most simple setups).
   - Select a datacenter region closest to your target audience.

4. In the "Authentication" section, choose "SSH keys" for secure access:
   - If you haven't added an SSH key before, click "New SSH Key".
   - Copy your public key (usually found in `~/.ssh/id_rsa.pub` on your local machine) and paste it into the provided field.
   - Give your key a name and click "Add SSH Key".

5. (Optional) Add a hostname for your droplet.

6. Review your choices and click "Create Droplet" at the bottom of the page.

7. Wait for your droplet to be created. DigitalOcean will provide you with the IP address of your new server.


### SSH login as root

Once the droplet is ready, you can SSH into it using the command:
   ```
   ssh root@your_droplet_ip
   ```

   Replace `your_droplet_ip` with the actual IP address of your droplet.

**IMPORTANT:** Due to high privileges, it is not recommended to use root user on a regular basis, so we will create a normal user with sudo privileges.

### Creating a new use 

```
adduser newusername
```

### Give new user Admin permissions

```
usermod -aG sudo newusername
```

### Verfiy that the user is now sudo group

```
getent group sudo
```

### Setup the firewall

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

### Enable SSH access of newly created User

### Root logged in with a password

If the password authentication is enabled for SSH, you can simple run this command from local machine

```
ssh <newusername>@your_droplet_ip
```

Enter the new `<newusername>` and you are good to go

### Root logged in via SSH keys (On Digital occean by default password authentication for SSH is disabled)

Logged in as root user we need to copy the local public key to `~/.ssh/authorized_keys` of the new user

`rsync --archive --chown=<newusername>:<newusername> ~/.ssh /home/<newusername>`

The above command copies the root user’s .ssh directory, retains the permissions, and changes the file owners-all in a single command


### SSH login as a newly created user 🎉

`ssh <newusername>@your_droplet_ip`


## Secure SSH from bruteforce attacks with fail2ban

### Install fail2ban

```
sudo apt update
sudo apt install fail2ban
````

Check the status of the service

`systemctl status fail2ban`

### Configure Fail2ban

The fail2ban service keeps its configuration files in the `/etc/fail2ban` directory. There is a file
with defaults `jail.conf`. It is not recommended to change this file as is periodically updated as fail2ban is 
updated.

We will create a `jail.local` file and copy the contents from `jail.conf`:

`sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local`

Add settings for SSH:

`vi /etc/fail2ban/jail.local``

search for the section sshd and enable the mode, we will use aggressive for testing. We also add the follow

```
bantime = 30m # ip will be banned for 10 minutes
findtine = 10m # maxretry failed login attempts within this timespane
maxretry = 5
```

Restart the service

`sudo systemctl restart fail2ban``


### Testing

From you local machine (other then the droplet) run this command 5 times:


`ssh bla@your_droplet_ip`

On sixth try you will get the following message

`ssh: connect to host your_droplet_ip port 22: Connection refused`

## Verify on the droplet

`sudo iptables -S | grep f2b`


Here you will see that the IP is blocked like this:

`A f2b-sshd -s <brute-force-attacker-ip> -j REJECT --reject-with icmp-port-unreachable`


`iptables` is a command for interacting with low-level port and firewall rules on your server
