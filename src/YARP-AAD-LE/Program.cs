using Azure.Identity;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);
var keyvault = builder.Configuration["Keyvault"];

var isKeyVaultConfigured = keyvault != null;
if (isKeyVaultConfigured)
{
    // Key Vault configured
    builder.WebHost.ConfigureKestrel(serverOptions =>
    {
        serverOptions.ConfigureHttpsDefaults(configureOptions =>
        {
            var appServices = serverOptions.ApplicationServices;
            configureOptions.UseLettuceEncrypt(appServices);
        });
    });

    builder.Configuration.AddAzureKeyVault(new Uri(keyvault), new DefaultAzureCredential());
    builder.Services.AddLettuceEncrypt().PersistCertificatesToAzureKeyVault();
}


builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var isAzureADConfigured = builder.Configuration.GetSection("AzureAd").Value != null;
if (isAzureADConfigured)
{
    builder.Services.AddMicrosoftIdentityWebAppAuthentication(builder.Configuration);
    builder.Services.AddAuthorization(options =>
    {
        options.AddPolicy("proxyPolicy", policy => policy.RequireAuthenticatedUser());
    });
}

var app = builder.Build();

if (isKeyVaultConfigured)
{
    app.UseHttpsRedirection();
}

if (isAzureADConfigured)
{
    app.UseAuthentication();
    app.UseAuthorization();
}

app.MapReverseProxy();

await app.RunAsync();
