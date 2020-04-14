# AWS SFTP File Transfer 
Terraform to deploy AWS SFTP Server and S3 Bucket 

### Usage 
```
module "modulename" {
    source="git::https://github.com/mileesingh/sftpfiletransfer"
    username = "<username to use for SFTP>"
    environment = "<environment name>"
    public_key = "<public key path>"
}
```