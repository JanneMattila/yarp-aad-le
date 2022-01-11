# YARP + Azure AD + Let's Encrypt

YARP configured with Azure AD authentication and Let's Encrypt certificates

## Build Status

[![CICD](https://github.com/JanneMattila/yarp-aad-le/actions/workflows/CICD.yml/badge.svg)](https://github.com/JanneMattila/yarp-aad-le/actions/workflows/CICD.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/jannemattila/yarp-aad-le?style=plastic)](https://hub.docker.com/r/jannemattila/yarp-aad-le)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Components combined:

1. [YARP](https://github.com/microsoft/reverse-proxy)
2. Azure AD authentication
3. Let's Encrypt using [LettuceEncrypt](https://github.com/natemcmaster/LettuceEncrypt/)

## Azure AD Authentication

Follow these [instructions](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
and set redirect uri to be: `https://<youraddress>/signin-oidc` and remember to enable `ID tokens` under authentication.

## LettuceEncrypt

Uses [DefaultAzureCredential](https://docs.microsoft.com/en-us/dotnet/api/overview/azure/identity-readme)
for authentication towards Azure Key Vault.

Important [environment variables](https://docs.microsoft.com/en-us/dotnet/api/overview/azure/identity-readme#environment-variables):

- AZURE_CLIENT_ID
- AZURE_TENANT_ID
- AZURE_CLIENT_SECRET

## Working with 'YARP + Azure AD + Let's Encrypt'

### How to create image locally

```batch
# Build container image
docker build . -t yarp-aad-le:latest

# Run container using command
docker run -p "2001:80" yarp-aad-le:latest
``` 

### How to deploy to Azure Container Instances (ACI)

#### Pre-reqs for deployment:

- Ability to create DNS record e.g., `app.contoso.com` or alternative use ACI provided e.g., `<aci>.<location>.azurecontainer.io`
  - Access to Azure DNS Zone (or other provider)
- Register Azure AD App to match DNS record
  - Set redirect uri to be: `https://<your-domain>/signin-oidc`
  - Enable `ID tokens` under authentication
  - Take note of following variables:
    - `AZURE_CLIENT_ID`: Application (client) ID of app registration
    - `AZURE_TENANT_ID`: Directory (tenant) ID of app registration
- **After** deployment create `A` record to point to deployed IP Address (if using custom DNS hostname)

#### Deployment

See step-by-step instructions from [deploy.sh](./deploy.sh).
