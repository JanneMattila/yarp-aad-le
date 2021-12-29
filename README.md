# YARP + Azure AD + Let's Encrypt

YARP configured with Azure AD authentication and Let's Encrypt certificates

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
