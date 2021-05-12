# assigning a provider - AWS Cloud - access key and secret key is stored in AWS default profile.
provider "aws" {

region = "ap-south-1"
profile = "default"

}



# creating a security group that allows traffic only on port number 80(http) and 22(ssh) from all IPs.
resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow http and ssh inbound traffic"
  
  ingress {
    description      = "allow_http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
   
  }
  ingress {
    description      = "allow_ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
   
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 tags = {
    Name = "allow_http_ssh"
  }

}



# creating a private key-pair. 
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = "Terraform-key"
  public_key = tls_private_key.this.public_key_openssh
}



# Launching the instance Terraform OS by creating the resource.
resource "aws_instance" "Terraform-OS" {

   ami = "ami-010aff33ed5991201"
   instance_type = "t2.micro"
   security_groups = ["allow_http_ssh"]
   key_name = "Terraform-key"
   tags = {
    Name = "Terraform-OS"
     }
}



# Creating a null resource for establishing a remote connection and doing configuration management in the instance launched.
resource "null_resource" "nullresource1" {
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.this.private_key_pem
    host     = aws_instance.Terraform-OS.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo yum install php -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }
}



# Creating EBS volume using aws_ebs_volume resource.
resource "aws_ebs_volume" "Terraform-EBS" {
  availability_zone = aws_instance.Terraform-OS.availability_zone
  size              = 1

  tags = {
    Name = "Terraform EBS"
  }
}



# Attaching the EBS volume to EC2 instance using ids.
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.Terraform-EBS.id
  instance_id = aws_instance.Terraform-OS.id
}



# Creating a null resource 2 for establishing a remote connection and doing configuration management in the instance launched.
resource "null_resource" "nullresource2" {
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.this.private_key_pem
    host     = aws_instance.Terraform-OS.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/sdh",
      "sudo mount /dev/sdh /var/www/html",
      "sudo yum install git -y",
      "sudo git clone https://github.com/yadvi12/okd_repo.git /var/www/html/web"
    ]
  }
}
