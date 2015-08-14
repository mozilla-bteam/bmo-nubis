# Working with Cloudformation

## Set Up
Before you deploy with Cloudformation you need to set up your parameters.json file. There is an example copy called parameters.json-dist that you can copy and edit. It should look something like this:

```json
[
  {
    "ParameterKey": "ServiceName",
    "ParameterValue": "bugzilla"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "sandbox"
  },
  {
    "ParameterKey": "SSHKeyName",
    "ParameterValue": "my_key"
  },
  {
    "ParameterKey": "TechnicalOwner",
    "ParameterValue": "my-email@domain.dom"
  },
  {
    "ParameterKey": "AmiId",
    "ParameterValue": "ami-abcdef123"
  }
]
```

### ServiceName
The ServiceName is the name of this service. For Mozilla deployments this should be the name of a real service as noted in [inventory](https://inventory.mozilla.org/en-US/core/service/)

### Environment
The environment is one of *sandbox*, *stage* or *prod*. For this (and all manual deployments) you will set this to *sandbox*.

### SSHKeyName
This is the name of an existing ssh key that you have either created or uploaded to AWS.

### TechnicalOwner
The technical owner should be a valid email or distribution list which is monitored by the team responsible for maintaining this service.

### AmiId
You will collect this as output from nubis-builder. Once the build is complete nubis-builder will display the ami id which you will need to manually copy into the parameters.json file. You will need to do this after every successful build.

## Commands to work with CloudFormation
NOTE: All examples run from the top level project directory.

In these examples the stack is called *bugzilla-mozilla-org*. You will need to choose a unique name for your stack as their can only be one *bugzilla-mozilla-org* stack at a time.

### Create
To create a new stack:
```bash
aws cloudformation create-stack --template-body file://nubis/cloudformation/main.json --parameters file://nubis/cloudformation/parameters.json --stack-name bugzilla-mozilla-org
```

### Update
To update an existing stack:
```bash
aws cloudformation update-stack --template-body file://nubis/cloudformation/main.json --parameters file://nubis/cloudformation/parameters.json --stack-name bugzilla-mozilla-org
```

### Update Consul
After creating or updating a stack you might need to update Consul. Run this command to take any (properly described) Cloudformation outputs and insert or update them in Consul:
```bash
nubis-consul --settings nubis/cloudformation/parameters.json --stack-name bugzilla-mozilla-org get-and-update
```

### Login
If you have only one EC2 instance and your ssh keys are on the jumphost, you can login by:
```bash
ssh -A -t ec2-user@jumphost.sandbox.us-west-2.nubis.allizom.org "ssh -A -t ubuntu@$(nubis-consul --settings nubis/cloudformation/parameters.json --stack-name bugzilla-mozilla-org get-ec2-instance-ip)"
```

### Visit site
The stack creates a route53 hosted zone and a cname record. You can set that up in your dns system by gathering the Route53 NS servers for your zone by:
To get the list of nameservers for the HostedZone:
```bash
nubis-consul --stack-name bugzilla-mozilla-org get-route53-nameservers
```

Or you can simply add one of the IPs from the dns name of the load balancer. To get the dns name of the load balancer:
```bash
aws cloudformation describe-stacks --query 'Stacks[*].Outputs[?OutputKey == `ELBDNSName`].OutputValue' --output text --stack-name bugzilla-mozilla-org
```

### Delete
To delete the stack:
```bash
aws cloudformation delete-stack --stack-name bugzilla-mozilla-org
```

After deleting the stack, be sure to remove the Consul data"
```bash
nubis-consul --settings nubis/cloudformation/parameters.json --stack-name bugzilla-mozilla-org delete
```

#### Nested Stacks

We are using nested stacks to deploy the necessary resources. You can find the nested stack templates at [nubis-stacks](https://github.com/Nubisproject/nubis-stacks).
