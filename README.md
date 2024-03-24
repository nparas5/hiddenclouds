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

#**main.tf -  Consists of code creating all the infrastructure on AWS as below**:


Provider Configuration: Specifies the AWS region to use for provisioning resources.

IAM Role and Instance Profile: Creates an IAM role and instance profile allowing EC2 instances to access S3 and Systems Manager (SSM).

AWS Managed Policies: Attaches AWS managed policies (e.g., AmazonS3FullAccess, AmazonSSMFullAccess) to the IAM role for necessary permissions.

Security Group: Defines a security group for EC2 instances allowing inbound traffic on port 80 from an Application Load Balancer (ALB) and allowing all outbound traffic.

Launch Configuration: Configures the launch configuration for EC2 instances, specifying the Amazon Linux 2 AMI, instance type, security group, IAM instance profile, and user data script to install Nginx and copy an HTML file from an S3 bucket.

Autoscaling Group: Sets up an autoscaling group ensuring a desired number of EC2 instances are running.

Public Application Load Balancer (ALB): Creates a public ALB allowing inbound traffic on port 80 and associating it with the defined security group.

Target Group: Defines a target group for the ALB to route traffic to instances on port 80 and sets up a health check.

ALB Listener: Configures an ALB listener to forward incoming HTTP traffic to the target group.

Outputs: Exports the names of the autoscaling group and the DNS name of the ALB for reference.




