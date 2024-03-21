# hiddenclouds

SCENARIO 1 Design:

This design is Highly Available Design Consists of below things explained:

# Region- ap-southeast-1
# Availability Zones : 2
# Private Subnets : 2
# Public Subnets : 2 (Already created in Default VPC)
# VPC : Default VPC
# IAM User : Administrator
# IaC Used : Terraform v1.7.5

============================

This design shows the nginx web servers running as ec2 in autoscaling group which exists in private subnets across 2 AZs.
This Design have Public facing Application Load Balancer across 2 Public Subnets.
ALB has listerner configured on HTTP port 80, which forwards the requests to target ggroup consits of EC2 web instances.
There is private S3 bucket created which have the nginx web content (In this scenario we are using Incremental and Decremental counter html code).
During boot EC2 instances will get its web content from S3 bucket, connecting using an IAM role assigned to them with S3 get policies.
The code to get web content will be defined in User-Data section of ec2 .
EC2 instances installed with AWS CLI as well ,this allow to run cli command to interact with S3 bucket and download the web content.




