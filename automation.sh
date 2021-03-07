# Perform an update of the package details and the package list
sudo apt update -y

# Install the apache2 package if it is not already installed.
webServerPackage=apache2
status="$(dpkg-query -W --showformat='${db:Status-Status}' "$webServerPackage" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
	sudo apt install $webServerPackage
fi

# Ensure that the apache2 service is running
if systemctl is-active apache2 | grep -q 'active';
then
	echo "apache2 service is active"
else
	systemctl start apache2
fi

# Ensure that the apache2 service is enabled
if systemctl is-enabled apache2 | grep -q 'enabled';
then
	echo "apache2 service is enabled"
else
	systemctl enable apache2
fi

# Create a tar archive of apache2 access logs and error logs
myname="Balaji"
timestamp=$(date '+%d%m%Y-%H%M%S')
filename=${myname}-httpd-logs-${timestamp}.tar
s3Bucket="upgrad-balaji"
tar cvf /tmp/$filename /var/log/apache2/*.log

# Run the AWS CLI command and copy the archive to the s3 bucket
aws s3 cp /tmp/$filename s3://$s3Bucket/

# Bookkeeping
filesize=$(find /tmp/"$filename" -printf "%s")
htmlFile=/var/www/html/index.html
if [ ! -f "$htmlFile" ]; then
    touch $htmlFile
	echo Log Type$'\t'Time Created$'\t'Type$'\t'Size >> $htmlFile
else
	echo httpd-logs$'\t'${timestamp}$'\t'tar$'\t'${filesize}K >> $htmlFile
fi

# Cron Job
cron=/etc/cron.d/automation
if [ ! -f "$cron" ]; then
    echo "0 0 * * * root /root/Automation_Project/automation.sh" > $cron
fi
