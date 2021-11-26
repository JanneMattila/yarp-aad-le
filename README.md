# YARP + Azure AD + Let's Encrypt

YARP configured with Azure AD authentication and Let's Encrypt certificates

## Azure AD Authentication

Follow these [instructions](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
and set redirect uri to be: `https://<youraddress>/signin-oidc` and remember to enable `ID tokens` under authentication.
