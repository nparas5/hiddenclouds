# hiddenclouds

##Scenario 1 - Terraform, AWS, CICD: 
#AWS Design Consists of Below:
DESIGN FILE NAME -  AssessmentAWS2024.jpeg

Region- ap-southeast-1
Availability Zones : 2
Private Subnets : 2
Public Subnets : 2 (Already created in Default VPC)
VPC : Default VPC
IAM User : Administrator
IaC Used : Terraform v1.7.5

============================
# About Design Consideration
This design shows the nginx web servers running as ec2 in autoscaling group which exists in private subnets across 2 AZs.

This Design have Public facing Application Load Balancer across 2 Public Subnets.

ALB has listerner configured on HTTP port 80, which forwards the requests to target group consits of EC2 web instances.


There is private S3 bucket created which have the nginx web content (In this scenario we are using Incremental and Decremental counter html code).


During boot EC2 instances will get its web content from S3 bucket, connecting using an IAM role assigned to them with S3 get policies.


The code to get web content will be defined in User-Data section of ec2 .


EC2 instances installed with AWS CLI as well ,this allow to run cli command to interact with S3 bucket and download the web content.

=====================================
#Other Design Consideration:

This Static website could be run on S3 bucket with custom access policies for public ACLs. We can simply create static website of the given html file in S3 bucket. This can save cost and more efficient than the current one.



=======================================
#Terraform Code :

I created 2 terraform files to accomplish this design:

main.tf
vars.tf

main.tf -  Consists of code creating all the infrastructure on AWS as below:







