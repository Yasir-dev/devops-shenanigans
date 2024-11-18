# Amazon EC2: Elastic Cloud Compute

Amazon Elastic Compute Cloud (EC2) is a web service that provides resizable compute capacity in the cloud. It is designed to make web-scale cloud computing easier for developers by allowing them to create virtual machines, or instances, that run on the AWS Cloud.

## Launching an EC2 Instance via AWS Console

### Step 1: Select a Name
- Choose a descriptive name for your instance to easily identify it later.

### Step 2: Select an AMI (Amazon Machine Image)
- An AMI provides the information required to launch an instance. Choose an AMI that suits your application needs.

### Step 3: Select Instance Type
- Choose an instance type based on the required CPU, memory, storage, and networking capacity.

### Step 4: Create a Key Pair
- A key pair is used to securely connect to your instance. Create a new key pair or use an existing one.
- Upon creating new key the public key will be associated to the instance and the private key will be downloaded
- You can go in the details of the instance and click on connect --> ssh section to get the details about how to connect to the instance using SSH

### Step 5: Configure Network Settings
- **VPC and Subnet**: Use the default VPC and subnet for simplicity.
- **Security Group Rules**:
  - Allow SSH access from anywhere (`0.0.0.0/0`) for remote management.
  - Allow HTTP access from anywhere (`0.0.0.0/0`) to serve web traffic.
- Ensure that "Auto-assign Public IP" is enabled to allow access from the public internet.

### Step 6: Configure Storage
- Select the default 8 GiB gp3 (General Purpose SSD) for storage.

### Step 7: Add User Data Script
- Use the following script to install Nginx and create a simple HTML page displaying the host IP:
  ```bash
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get install nginx -y
  cat <<EOF > /var/www/html/index.html
  <html>
    <head>
      <title>EC2 Instance Info</title>
    </head>
    <body>
      <h1>Welcome to EC2 Instance</h1>
      <p><strong>Hostname:</strong> $(hostname -f)</p>
    </body>
  </html>
  EOF
  sudo systemctl start nginx
  sudo systemctl enable nginx
  ```
- To troubleshoot any issues with the user data script, check the log file:
  ```bash
  tail -3000 /var/log/cloud-init-output.log
  ```

### Step 8: Launch the Instance
- Launch the instance and navigate to the instance details page.
- Copy the public DNS and open it in a web browser. You should see the Nginx welcome page with the host IP details.


### EC2 Instance Types

- [AWS Documentation](https://aws.amazon.com/ec2/instance-types/)
- This StackOverflow [post](https://stackoverflow.com/a/56880093) explain what does the instance letter means (unofficially ;-))

### T Type Instances

T class instances are among the most widely utilized EC2 instance types. The T2 generation is the older version, while T3 represents the latest generation. Their popularity stems from being the most cost-effective EC2 instances available. T3 instances utilize a credit-based system for CPU usage, which contributes to their affordability. These instances offer two performance modes: baseline and burst. Baseline performance refers to the consistent level of performance you can expect at all times, whereas burst performance indicates the enhanced performance available during periods of high demand. However, burst performance is constrained by the number of CPU credits allocated to the instance. You read [here](https://aws.amazon.com/ec2/instance-types/#Burstable_Performance_Instances) more about Burstable Performance Instances

You can read more about T3 Instances [here](https://aws.amazon.com/ec2/instance-types/t3/)