# docdb-change-stream-elastic-search-sync

This sample code can be used to sync Amazon Elasticsearch service with Amazon DocumentDB 
using Amazon DocumnetDB's Change Streams feature.

# Prerequisite
AWS Account with VPC.

# Usage
1] Clone the repo

2] Set the following placeholder values as applicable to your AWS account in "terraform_scripts/variables.tf"
    
    A] VPC related values:
        vpc_id, private_subnet_1, private_subnet_2

    B] Set AWS-REGION 
        user_region

    D] Set up DocumentDB user details (user id and password)
        master_docdb_password, master_docdb_user

3]  Set placeholder values in "backend.tf" as applicable to your AWS account.
    
    A] <DEPLOYMENT-BUCKET-NAME>

    B] <TERRAFORM-STATE-FILE-NAME>

    C] <AWS-PROFILE>
    
    D] <AWS-REGION>

4] Set AWS Profile as appropriate in /terraform_scripts/provider.tf    

5] EC2 Bastion host can be used to connect to Elasticsearch service domain, Kibhana and DocumentDB running within private subnet in a VPC

6] Download the DocumentDB [pem](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem) and place under src/process_change_stream

7] Download [AmazonRootCA1.pem](https://www.amazontrust.com/repository/AmazonRootCA1.pem) and place under src/update_elasticsearch_service
