#!/bin/bash
# package updates
#######################Automation,sh V0.1##########################################
####### Version V0.1 Ec2 instance is created 
####### Apache instance & aws instance installed & services are running
####### Apache file serverlog archieved and transfered to s3 bucket
#######################Automation.sh V0.2###########################################
###### Book keeping done with /var/www/html/inventory.html
###### Cron job created to start the script automatically
####################################################################################
sudo echo Y | apt update && sudo apt -y upgrade
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
sudo systemctl status apache2 |grep Active
if [ $? -eq  0 ] 
   then
    echo "======================================================="
    echo "   APACHE WEBSERVER IS ALREADY INSTALLED AND IS RUNNING"
    echo "======================================================="
    else
	sudo apt install apache2-bin --fix-missing
	sudo systemctl is-enabled apache2.service
	sudo systemctl stop apache2
	sudo systemctl start apache2
   
    echo "======================================================="
    echo " APACHE WEBSERVER IS INSTALLED AND SERVICE IS STARTED"
    echo "======================================================="


    fi
echo "Checking AWS Installation"
sudo systemctl status aws |grep Active
if [ $? -eq  0 ]
   then
    echo "======================================================="
    echo "   AMAZON AWS IS ALREADY INSTALLED AND IS RUNNING"
    echo "======================================================="
    else
	sudo rm -rf *.zip
	wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
	sudo apt install unzip
	sudo echo A | unzip -u awscli-exe-linux-x86_64.zip
	sudo echo Y | ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
	${aws_loc}= which aws
	sudo echo Y | ./aws/install --bin-dir /usr/local/bin --install-dir ${aws_loc} --update
	sudo ls -l ${aws_loc} | grep ${aws_loc}
    echo "======================================================="
    echo " AMAZON AWS IS INSTALLED AND SERVICE IS STARTED"       
    echo "======================================================="


    fi
sudo echo Y | apt install firewalld
sudo systemctl start firewalld
sudo systemctl status firewalld | grep Active
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
# acquiring the ip address for access to the web server
echo "this is the public IP address:" `curl -4 icanhazip.com`
# adding the needed permissions for creating and editing the index.html file
sudo chown -R $USER:$USER /var/www
cd /var/www/html/
echo '<!DOCTYPE html>' > index.html
echo '<html>' >> index.html
echo '<head>' >> index.html
echo '<title>Level It Up</title>' >> index.html
echo '<meta charset="UTF-8">' >> index.html
echo '</head>' >> index.html
echo '<body>' >> index.html
echo '<h1>Welcome to Level Up in Tech</h1>' >> index.html
echo '<h3>Red Team</h3>' >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html
#==============================================================================
echo " "
echo "============================================"
echo "Archiving APACHE SERVER LOGS to /tmp Folder"
echo "============================================"
echo " "

sudo cd /var/log/apache2


myname="umadevi"
s3_bucket="upgrad-umadevi"
timestamp=$(date '+%d%m%Y-%H%M%S')
extension=".tar"
file=/tmp/${myname}-httpd-logs-${timestamp}${extension}
echo "file : ${file}"
sudo tar -cvf /tmp/${myname}-httpd-logs-${timestamp}${extension}  /var/log/apache2/*.log
sleep 20

size=`sudo stat -c "%s" /etc/*.conf|paste -sd+|bc -l`



echo "\n /tmp/$myname-httpd-logs-$timestamp$extension"
echo "==============================================="
echo " LOg Details Available in /var/www/html/inventory.html"
echo "==============================================="



echo "<tr> <td>httpd-logs</td><td>$timestamp</td><td>$extension<td>/tmp/$myname-httpd-logs-$timestamp$extension></td><td>$size</td></tr>"	>> /var/www/html/inventory.html




echo "==============================================="
echo " TRANSFER OF ARCHIVE FILES TO AWS S3 STORAGE "
echo "==============================================="

aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}${extension} s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}${extension}
aws s3 cp /var/www/html/inventory.html s3://${s3_bucket}/inventory.html
