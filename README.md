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

# Scenario 2 - Kubernetes:

=========


**#I divided scenario two in below parts:**

Creating Incremental and Decremental Counter Application in Kubernetes (Minikube)

Deploy MySQL server in minikube.

Create Table in MySQL server.

Counter application must be able to communicate to MySQL.

Install Prometheus and Grafana on minikube

Monitor Cluster metrics using Prometheus and Visualize in Grafana.


# Steps I have done on this scenario 

#I have just setup minikube on mac and able to run it, created deployements for counter app and mysql and deployed in minikube.

Both Pods running fine.

#Installed Prometheus and Grafana for Monitoring.



# Created Docker Image for Incremental and Decremental Counter according to our scenario using dockerfile as below:

#DOCKERFILE FOR COUNTER APP

#Use an official Nginx image as the base image
FROM nginx:latest

#Set environment variable for displaying first name
ENV FIRST_NAME "Nitin Paras"

#Copy the HTML file into the nginx server root directory
COPY index.html /usr/share/nginx/html/index.html

#Expose port 80
EXPOSE 80

#Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]

======================================

Build Docker Image using this dockerfile and upload to docker hub repository.

# Created below YAML file for counter app deployment:



apiVersion: apps/v1
kind: Deployment
metadata:
  name: counter
  labels:
    app: counter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: counter
  template:
    metadata:
      labels:
        app: counter
    spec:
      containers:
        - name: counter
          image: cloudmonknitin/incredecrement:tag
          env:
            - name: MYSQL_HOST
              value: mysql
            - name: MYSQL_USER
              value: root
            - name: MYSQL_PASSWORD
              value: XXXXXXXXXX
            - name: MYSQL_DATABASE
              value: incredecreDB
            - name: DISPLAY_NAME
              value: "NitinParas"
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: counter
spec:
  selector:
    app: counter
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort

=========================================================

**kubectly apply -f appcounter.yaml**



# Created MySQL YAML file for Deployment of MySQL Server in MiniKube as below:

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  labels:
    app: mysql
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:latest
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: Bmwx5@yahoo
            - name: MYSQL_DATABASE
              value: incredecreDB
            - name: MYSQL_USER
              value: cloud
            - name: MYSQL_PASSWORD
              value: Bmwx5@yahoo1234
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  selector:
    app: mysql
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306



======================================

kubectl apply -f mysql.yaml

admin@Admins-MacBook-Pro-2 prometheus % kubectl get pods
NAME                                  READY   STATUS    RESTARTS        AGE
counter-854d5697bd-wv7fs              1/1     Running   1 (5h22m ago)   5h40m
counter-deployment-57694fcf44-27bcr   1/1     Running   1 (5h22m ago)   6h35m
mysql-7fff4d4f5b-wds9v                1/1     Running   1 (65m ago)     6h7m
admin@Admins-MacBook-Pro-2 prometheus % 



=======================================

# Communication with MySQL Server:






=========================================
# Monitoring using Prometheus and Grafana

![image](https://github.com/nparas5/hiddenclouds/assets/40522271/9d6a9067-7932-4462-9dc4-e20c17b499a4)













