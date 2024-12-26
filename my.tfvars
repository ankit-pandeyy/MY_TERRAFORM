ami = "ami-id"
key_name = "Mykey"
security_group_id = "sg-id"
instancetype = "t2.nano"
pub_subnet  = "subnet-id"
user_data_script = <<-EOF
    #! /bin/bash
    sudo su
    sudo yum update
    sudo yum install -y httpd
    sudo chkconfig httpd on
    sudo service httpd start
    echo "<h1>Hey ,successfully Deployed EC2 With Terraform</h1>" | sudo tee /var/www/html/index.html
    EOF
