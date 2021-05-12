# assigning a provider - AWS Cloud - access key and secret key is stored in AWS default profile.
provider "aws" {

region = "ap-south-1"
profile = "default"

}

# Launching the instance Terraform OS by creating the resource.
resource "aws_instance" "Terraform-OS" {

ami = "ami-010aff33ed5991201"
instance_type = "t2.micro"
tags = {
    Name = "Terraform OS"
     }

}

# Printing availability zone of EC2 instance launched so that we can put the EBS volume in the same AZ.
output "AZ" {
value = aws_instance.Terraform-OS.availability_zone
}

# Printing public IP of ec2-instance launched.
output "Public-IP" {
value = aws_instance.Terraform-OS.public_ip
}

# Printing the Instance ID.
output "Instance-ID" {
value = aws_instance.Terraform-OS.id
}

# Creating EBS volume using aws_ebs_volume resource.
resource "aws_ebs_volume" "Terraform-EBS" {
  availability_zone = aws_instance.Terraform-OS.availability_zone
  size              = 10

  tags = {
    Name = "Terraform EBS"
  }
}

# Printing the volume ID so that we can attach the EBS-volume to the EC2-instance.
output "Volume-ID" {
value = aws_ebs_volume.Terraform-EBS.id
}

# Attaching the EBS volume to EC2 instance using ids.
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.Terraform-EBS.id
  instance_id = aws_instance.Terraform-OS.id
}