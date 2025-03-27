
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

The project is fully made on Terraform using HCL. 

Firstly the project is creating a security group 
