#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo mkdir /var/www/html/images/
echo "<h1>Deployed via Terraform Serving images from images folder</h1>" > /var/www/html/images/index.html

