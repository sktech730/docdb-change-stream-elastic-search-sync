# docdb-change-stream-elastic-search-sync

The Sample code to sync amazon elasticsearch service with Amazon Document DB 
using Amazon DocumnetDB's change stream feature.

# Prerequisite
AWS Account with VPC.

# Usage
1] Clone the repo

2] set the following placeholder values as per your AWS account in "Variables.tf"
    
    A] VPC Related Values:
        vpc_id, private-subnet-1,private-subnet-2

    B] Set up AWS-REGIOn to workon
        user_region

    D] set up document db user details (user id and password)
        master_docdb_password, master_docdb_user

3]  setup placeholder values in "backend.tf" as per your AWS account.
    
    A] <DEPLOYMENT-BUCKET-NAME>

    B] <TERRAFORM-STATE-FILE-NAME>

    C] <AWS-PROFILE>
    
    D] <AWS-REGION>

4] To Connect to elasticsearch service domain as well Kibhana  and DocumentDB
   which is running in VPC, one of ways is through ec2 bastion host
   you can launch ec2 instance which will act as bastion host in same security group where elastic search and DocumentDB is running
   and using port forwarding technique you will be able to access the elasticsearch service end point and Amazon Doumnet DB.
   

    

