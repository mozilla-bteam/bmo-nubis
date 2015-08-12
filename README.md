# nubis-skel
This is a skeleton repository that can be used for testing or as a quick way for you to incorporate nubis into your own project.

## Prerequisites
If you are new to the Nubisproject you will need to set up some [prerequisites](https://github.com/Nubisproject/nubis-docs/blob/master/PREREQUISITES.md). 

## Get the code
Next grab the latest [release](https://github.com/Nubisproject/nubis-skel/releases), extract it and copy the *nubis* directory into your code base. You also need to add *nubis/cloudformation/parameters.json* to your *.gitignore* file. See the project [.gitignore](.gitignore) file for an example.

## Build the project
This step is only necessary if you have changes, otherwise you can simply configure the deployment using an ami id from the following list:

|  Region   |   AMI Id     |
|-----------|--------------|
| us-west-2 | ami-bf43408f |
| us-east-1 | ami-c35e96a8 |
 
If you run *nubis-builder* it will output an ami id for you to use.
```bash
nubis-builder build
```

## Configure the deployment
Create a nubis/cloudformation/parameters.json file by copying the [parameters.json-dist](nubis/cloudformation/parameters.json-dist) file and editing the parameter values. More detailed instructions can be found [here](nubis/cloudformation/README.md#set-up).
```bash
cp nubis/cloudformation/parameters.json-dist nubis/cloudformation/parameters.json
vi nubis/cloudformation/parameters.json
```

## Deploy the stack
You are now ready to deploy your stack. Be sure to replace "YOUR_NAME" with a unique stack name. You can find more detailed instructions [here](nubis/cloudformation/README.md#commands-to-work-with-cloudformation).
```bash
aws cloudformation create-stack --template-body file://nubis/cloudformation/main.json --parameters file://nubis/cloudformation/parameters.json --stack-name YOUR-STACK
```

## Help
If you run into any issues, feel free to reach out to us. We hang out in #nubis-users on irc.mozilla.org.
