# AWS IAM Integration

The IAM Authenticator allows an AWS resource to use its AWS IAM role to authenticate with Conjur. This approach enables EC2 instances and Lambda functions to access credentials stored in Conjur.

The code used here is based on [conjur-authn-iam-client-python](https://github.com/cyberark/conjur-authn-iam-client-python)
  

## How does the IAM Authenticator works?

![Conjur IAM authenticator](https://github.com/assafjh/cybr-demos/blob/main/aws-iam/iam-authenticator.png?raw=true)
## Two use cases are described here
### EC2 using an IAM Role to consume a secret from Conjur
#### Please refer to the folder '*elastic*' 
### Lambda function using an IAM Role to consume a secret from Conjur
#### Please refer to the folder '*lambda*' 
