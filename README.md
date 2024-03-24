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


**#Other Design Consideration:**
========================================

This Static website could be run on S3 bucket with custom access policies for public ACLs. We can simply create static website of the given html file in S3 bucket. This can save cost and more efficient than the current one.



=======================================


**#Terraform Code :**

I created 2 terraform files to accomplish this design:

main.tf
vars.tf

#**main.tf -  Consists of code creating all the infrastructure on AWS as below**:
=======================

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

=======================================================


# vars.tf : I created variables for below items so that they can be simply called in the Terraform Code:**


public_subnet_ids: A list of IDs representing the public subnets where the EC2 instances and ALB will be deployed. The default value contains two subnet IDs.

private_subnet_ids: A list of IDs representing the private subnets where the EC2 instances will be deployed. The default value contains two subnet IDs.

s3_bucket_name: The name of the S3 bucket from which the user data script in the EC2 launch configuration will copy the HTML file. The default value is "nginxweb1x2x3x".

vpc_id: The ID of the VPC in which the resources will be created. This VPC should contain the specified subnets. The default value is the ID of the VPC where resources will be deployed.


NOTE: More code items can be added into variable file as well, for more consistency and to avoid using diret values in the main.tf code itself.


============================================================================

terraform apply -auto-approve


once you run terraform apply it will provision the required infrastructure on AWS for you. Refer ALB_URL_Output.jpeg file for the file copied from S3 Bucket.


#THINGS NOT WORKED IN THIS:

User-Data was failing to run.

Manually tried worked fine with same SSM role and same AMI.

Tried Troubleshooting cloud-init logs , tried adding user-data explicitly in shell script but did not worked. More Troubleshooting can be done to check more user-data logs etc.

Have to manually register EC2 instance as targets in Target group. 


#WORKAROUND I APPLIED

Created pre-configured AMI from EC2 Instance and then use that AMI ID in the Terraform Code.


#OTHER WORKAROUND 

Instead of using user-data we can use AWS Systems Manager to Run Command by using a Shell Script Runbook. It will have to assign SSM roles to Instance in order to manage them via SSM.


====================
====================================
====================
=====================================
====================


# PART -2** 
:

Set up a Gitlab pipeline which updates changes to website code stored in your Gitlab code repository to the above-mentioned S3 bucket upon merge to Master branch. Change all the text to upper case and push changes to S3 bucket using your pipeline. In your pipeline, trigger instance refresh of the autoscaling group of Server fleet A, after successful push of code to S3 bucket.


This one I setip GitLab pipeline which ran successfully and initiated instance refresh.

Refer gitlab-ci.yml for the same.

NOTEs:

After instance refresh have to manually register targets to the Target group.

Again same issue as index.html would not be copied from S3 Bucket to AWS instance during refresh also because of User-data was not running. 

Troubleshooted this but could not find any issues. More troubleshooting >>>>>>>>

Workaround to this to use AWS Run Command via Systems Manager and execute the user-data shell script in runbook.


========











