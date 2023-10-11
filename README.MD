
# EDE SERVICE REPORT

This repository contains the IAC code for an API deployment under AWS to use as an S3 proxy 

## Features
###### GET method
###### PUT method
###### PDF visualization and upload
###### Auth0 custom integration

## Deployment
git clone git@github.com:edeuae/pdf-retrieval.git
###### retrieve AWS credentials from https://ede-cloud.awsapps.com/start/
###### Select programmatic access 
###### Configure credentials
###### terraform plan 
###### review changes
###### terraform apply
###### Take note of the api url on the terminal

## Demo
###### using postman, you can put the url returned on the terminal
###### choose the desired method [GET, PUT]
###### on Headers add  Authorization column
###### Add the jwt token retrieved from Auth0 domain
###### click send 
#### CLI command
###### GET curl --location '<API_URL_OUTPUT>' --header 'Authorization: <AUTH0_TOKEN>'
###### PUT curl --location --request PUT '<API_URL_OUTPUT>' --header 'Authorization: <AUTH0_TOKEN>' --data '<PATH_TO_PDF>'


