#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo mkdir /var/www/html/data/
echo "<h1>Deployed via Terraform data from data folder</h1>" > /var/www/html/data/index.html

