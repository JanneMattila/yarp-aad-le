using Azure.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);
var keyvault = builder.Configuration["Keyvault"];
if(!string.IsNullOrEmpty(keyvault))
{
    // Key Vault configured, so pull configuration from there
    builder.Configuration.AddAzureKeyVault(new Uri(keyvault), new DefaultAzureCredential());
}

builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));
builder.Services.AddLettuceEncrypt().PersistCertificatesToAzureKeyVault();
builder.Services.AddMicrosoftIdentityWebAppAuthentication(builder.Configuration);
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
});

var app = builder.Build();
app.UseHttpsRedirection();
app.UseAuthentication();
app.MapReverseProxy();

await app.RunAsync();
