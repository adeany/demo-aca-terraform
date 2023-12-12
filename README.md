# demo-aca-terraform

This project includes Terraform templates for [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/overview):

### [tf-aca](/tf-aca/)

A Terraform template to deploy a container app in Azure with the following characteristics:

- Log analytics workspace resource
- Application insights enables
- Ability to specify a container app image using `image` parameter in `template` block

### [tf-aca-with-acr](/tf-aca-with-acr/)

