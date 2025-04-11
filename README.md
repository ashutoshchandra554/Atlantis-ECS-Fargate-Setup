**Important**: Please review the [Working Guide](https://github.com/ashutoshchandra554/Atlantis-ECS-Fargate-Setup?tab=readme-ov-file#working) **before deployment** for required configuration and access policy changes.  

# Introduction

This project introduces a ready to use template for deploying Atlantis using an ECS Fargate setup.

Atlantis is an open-source tool designed to automate and streamline infrastructure management using Infrastructure as Code (IaC) principles, primarily with Terraform. It integrates with version control systems (VCS) like GitHub, GitLab, and Bitbucket to enforce collaborative, auditable workflows for infrastructure changes.

Learn more about Atlantis here: [here](https://github.com/runatlantis/atlantis?tab=readme-ov-file)

## Installation

To install this project extract it locally using:

```bash
git clone https://github.com/ashutoshchandra554/Atlantis-ECS-Fargate-Setup.git
```

If you have issues doing this related to Personal Access Tokens (PAT) refer [this](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

After extracting the folder go into the Atlantis-ECS-Fargate-Setup directory using:
```bash
cd Atlantis-ECS-Fargate-Setup
```
In this directory we will have to create a file for environmental variables as terraform.tfvars as shown below:
```bash
atlantis_gh_user       = <Your Github username>
atlantis_gh_token      = <Your Github PAT>
atlantis_repo_allowlist = "github.com/<github username>/<repo name>"
```
After making sure we are using the correct directory in the bash terminal. Make sure we have AWS cli installed using: 
```bash
aws --version
```
If we cannot see the version correctly then AWS cli is not installed and we will need to install it first.
 (*We can skip this step if aws is already installed* )

Refer to [this](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) guide for installing AWS cli.

After this is installed and working correctly we can configure AWS with required credentials. In bash terminal run:
```bash
aws configure
```

We need to configure AWS cli like this example:
```bash
AWS Access Key ID: <Your AWS Access Key>
AWS Secret Access Key: <Your AWS Secret Key>
Default region name [None]: <None>
Default output format [None]: <None>
```
After AWS cli is connected and ready run:
```bash
terraform init
```
For satisfying ip address display script dependency run:
```bash
pip install boto3
```
Once it is complete run:
```bash
terraform plan
```
After the plan is complete you should be able to see all the resources that will be added without any errors, once that happens run:
```bash
terraform apply
```
With that the resources are successfully created just wait about 2-3 minutes the terraform file (outpurs.tf) will return the public ip of the ECS fargate task running atlantis.


## Usage

After acquiring the public IP of the ECS task where atlantis is deployed we can confirm that atlantis is deployed and working correctly by opening in browser:
```python
http://<public IP>:4141
```
The output should resemble the main screen of atlantis.Next go to the repo that was added as repo allowlist in terraform.tfvars.

In the desired repo visit settings > webhook, enter payload URL as:
```python
http://<public IP>:4141/events
```
Request type should be application/json and trigger events should be kept as pull requests and issue comments.

Voilà, with this Atlantis is up, running and configured with Github. Everytime a terraform pull request is opened atlantis will initialize terraform state.

Atlantis commands can be used as comments in the same pull request, the exact commands can be found in the documentation.



## Working

All infrastructure is codified with Terraform (HCL), ensuring reproducibility and version control.  

* Firstly, the project is creating a security group named **atlantis-sg** that allows all traffic to access port 4141 (where Atlantis is hosted). This can be changed to allow only the ip(s) that need access to the hosted Atlantis.

* Next comes creation of IAM role with the following :
   1. AmazonECSTaskExecutionRolePolicy: It grants permissions required for Amazon ECS (Elastic Container Service) tasks to interact with other AWS services. 
   2. AmazonS3FullAccess: This role provides full access to S3 buckets (This is only needed if we store terraform state files in s3 and also full access can be changed to give only barely required access.)
    3. AmazonDynamoDBFullAccess: This role provides full access to DynamoDB (This is only needed if we use Dynamo DB for terraform state locking and also full access can be changed to give only barely required access.)

* Finally, an ECS task definition is created:
  1. **Task name**: atlantis-task
  2. **Task Role**: The role just created.
  3. **Task size**:
        Memory: `0.5GB`
        CPU: `0.25 vCPU`


* Container Definition are as follows: 
  1. **Container name**: `atlantis`
  2. **Image**: `ghcr.io/runatlantis/atlantis:latest`
  3. **Port mappings**: **4141**
  4. **Environment variables**(Managed through terraform.tfvars mentioned above):
        - `ATLANTIS_GH_USER` = `<your_github_user>`
        - `ATLANTIS_GH_TOKEN` = `<your_github_token>` 
        - `ATLANTIS_REPO_ALLOWLIST` = `github.com/<your-org-or-user>/<your-repo>`

* Finally an ECS fargate service runs 1 task (1 desired) containing the Atlantis container and the Public IP address of the task is printed to user after 1 minute (to make sure container has started successfully) using a python script.
## Roadmap

- Additional customization using repos.yaml
- Streamlining the process of destroying and creating resources by adding the webhook url directly to Route 53.


## Acknowledgements

 - [Atlantis Parent Website](https://www.runatlantis.io/)
 - [Atlantis Github Repo](https://github.com/runatlantis/atlantis)
 
