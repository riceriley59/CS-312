# AWS Minecraft Server Installation and Configuration Tutorial
In this tutorial we will overview how to go through and install a minecraft server on an AWS EC2 instance that will allow you and others to play Minecraft together! You'll see the sections detailed below that explain in order how to go about completing this task.

## Create a VPC for the Minecraft Server's Resources:

1. Make sure you are in the correct region for the tutorial, you want it to be close to your actual geographical region. For this tutorial we will be using the Oregon region, and this can be changed via a drop down near the top right of the screen.

2. Now, using the search bar, search for the "VPC" dashboard and click on that. Once your at the VPC dashboard click on the "VPCs" section where you should see a list of all your VPCs (there may only be one if this is your first time setting this up).

3. Click on the "Create VPC" button in the top right.

4. Now click on the "VPC and more" radio to create subnets and whatever else is needed. Then make sure the auto generate option is selected and type in "minecraft-vpc" which will now be the name of your VPC and will prefix all of it's resources. Now in the IPv4 CIDR Block box enter in 10.3.14.0/24 (You can enter whatever CIDR range of IPs you want this to be but /24 is 256 addresses which should be good enough for our use case). Now select 'No IPv6 CIDR Block', 'Default' Tenancy, 2 AZ zones, 2 public subnets, 0 private subnets, 'None' for the NAT gateways, and 'None' for the VPC Endpoints. You can now click 'Create VPC' and wait for the creation process to finish.

5. Now you have created a VPC (Virtual Private Cloud) for all our minecraft server resources, our EC2 box, to sit in and will allow us to configure specific traffic that can communicate with the server.

## Configure the VPC's Security Group:

6. After creating the VPC you should now be in the 'Your VPCs' section which is now displaying your newly created mincraft-server VPC. NOTE the VPC ID of your minecraft-server VPC as we'll need that to know which security group to modify.

7. On the left of you screen you should see more options to manage your VPC. Scroll down and under the 'Security' section you should see the 'security groups' section. Click on that, and you should be brought to a page with all of the security groups. This is where remembering the VPC ID for the new VPC you just created will be needed as you'll need to click on the security group with the corresponding VPC ID as the VPC that you just created.

8. You'll now be able to see the inbound rules for the VPC's security group which we'll need to modify a bit if we want to be able to allow users to connect to the minecraft server. We'll need to add two more inbound rules so click on the 'Edit Inbound Rules' button. First off lets configure SSH traffic so we can connect to and configure our EC2 boxes, click on add rule and select the type of 'SSH' then do a source of 'Anywhere IPv4' which you should see in the source dropdown. Finally, we need to configure the rule to allow users to connect to the minecraft server which runs on the default port of 25565 unless explicity configured otherwise. Click on 'add rule' again and this time do a type of 'Custom TCP' and enter in 25565 for the port range, and then again select a source of 'Anywhere IPv4' for the source which you'll see in the source dropdown.

9. Now the correct traffic should be allowed into the VPC and let us and the users communicate with the servers.

## Create an AWS EC2 Instance:

10. Now we actually need a server to run Minecraft on. Go to the search bar in the top left and search for the 'EC2' dashboard. Once at the EC2 dashboard ensure that you are still in the same region as the VPC that you just created which you should be able to see in the top right. Then click on the 'Launch Instance' button.

11. You should now be prompted with options for the EC2 box. First off we need to name it, call it minecraft server or something along those lines. For the operating system select Ubuntu 24.04 LTS which should also be in the quick start options, also ensure that it's using the x86 architecture. Next select the instance type of t2.small so our server will have enough resources to actually run Minecraft.

12. For the Key Pair you can create a new one or use a pre-existing one whichever works better for you, but just make sure you put it somewhere accesible as you'll need that to be able to connect to the EC2 box later on.

13. Finally, for the network settings we need to configure the EC2 box to use our VPC we created above. Click on the 'edit' button for the network settings, and then select the VPC we just created, it should have the name you gave it, and make sure the subnet ends with west-2a. Enable auto-assign public IP. Use the 'Select Existing Security Group' option and select the default security group.

14. Now you can launch the instance (Click the launch instance button in the bottom right), and wait for it to start.

## Configure and Start the Minecraft Server:

15. Now that we have all the infrastructure setup now we need to actually set up the EC2 server and install and configure Minecraft on it. To do this we will first need to SSH insto the EC2 box. Go to the EC2 dashboard and click on the EC2 instance we just created and click on 'Connect' and then the 'SSH client' and copy the example command to SSH into the server. It should look something like this:
```
ssh -i "M4 Macbook Pro.pem" root@ec2-35-91-221-105.us-west-2.compute.amazonaws.com
```

16. I have wrote a bash script to install and setup the minecraft server and also set it up as a systemd service so the minecraft server will automatically start whenever the EC2 box does. In order to run this script all you have to do is copy it to the EC2 box via SSH and then make it executable so you can run it (`chmod +x`). You'll only need to run this script once, and then all other configurations can be made in the `/opt/minecraft/server` directory. The script does a few things:

     * Updates the EC2 box and it's packages via `sudo apt update`.
     * Installs the Java Runtime Environment (JRE) version 21 since Minecraft is written in Java.
     * Creates a Minecraft user which will actually run the server.
     * Creates the `/opt/minecraft` and `/opt/minecraft/server` directories for the Minecraft server files to live.
     * Downloads the Minecraft `server.jar` file into the `/opt/minecraft/server` directory.
     * Runs the `server.jar` for the first time which creates all the other configuration and EULA files. It then accepts the EULA by changing the eula.txt file.
     * Creates start and stop scripts to quickly start or stop the server from running.
     * Creates a new systemd service called `minecraft.service` which uses the Minecraft user to run the start script.
     * Starts and enables the new minecraft.service so that the Minecraft server will run every time the EC2 box starts up or is rebooted.

### setup-minecraft-server\.sh

**IMPORTANT**: By Running this script you are accepting the Minecraft servers EULA.

```
#!/bin/bash

# Insert Server Download URL Below
# (Currently it's for the 1.21.5 server version)
MCSERVERBINARY_URL='https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar'

# Install JRE version 21 (Minecraft Dependency)
sudo apt update
sudo apt install openjdk-21-jdk-headless

# Create a minecraft user for the service to use
# and a directory for all the server files to live
sudo useradd --system --no-create-home --shell /usr/sbin/nologin minecraft
sudo mkdir /opt/minecraft/
sudo mkdir /opt/minecraft/server/

# Get the MC server binary and install it in the
# server directory
cd /opt/minecraft/server
sudo wget $MCSERVERBINARY_URL

# Start the server and accept the EULA
# IMPORTANT: You are accepting the Minecraft EULA
# by running this script.
sudo chown -R minecraft:minecraft /opt/minecraft/
sudo java -Xms1024M -Xmx2048M -jar server.jar --nogui
sleep 40
sudo sed -i 's/false/true/p' eula.txt

# Create a start script for the minecraft service
sudo touch start
sudo printf '#!/bin/bash\njava -Xms1024M -Xmx2048M -jar server.jar --nogui\n' | sudo tee start > /dev/null
sudo chmod +x start

sleep 1

# Create a stop script to quickly stop the server
sudo touch stop
sudo printf '#!/bin/bash\nkill -9 $(ps -ef | pgrep -f "java")\n' | sudo tee stop > /dev/null
sudo chmod +x stop

sleep 1

# Create a minecraft service
cd /etc/systemd/system/
sudo touch minecraft.service
sudo printf '[Unit]\nDescription=Minecraft Server on start up\nWants=network-online.target\n[Service]\nUser=minecraft\nWorkingDirectory=/opt/minecraft/server\nExecStart=/opt/minecraft/server/start\nStandardInput=null\n[Install]\nWantedBy=multi-user.target' | sudo tee minecraft.service > /dev/null

# Enable and start the minecraft service so the
# server will automatically restart/run when the server
# comes up
sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo systemctl start minecraft.service

```

## Connecting to the Minecraft Server:

Now you should have a working Minecraft server that is hosted in AWS that can be connected to via your EC2 boxes public IP or domain name which is pretty cool. If you are wondering how to get the public IP for your minecraft server just click on the Minecraft EC2 instance and you should see the 'Public IPv4 Address' listed.

**NOTE:** You will also need to make sure you are connecting to the server with the same client version as the server. The script above uses the 1.21.5 version of Minecraft.

## Conclusion:

Good job on setting up the Minecraft server using AWS. To make this even better in the future you could make it so that the work is less manual and define the infrastructure through a cloud provisioning tool such as Terraform. Then you could scale your Minecraft server up to many more users (horizontally or vertically) and even add in some load balancing between multiple servers.
