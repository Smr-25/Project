using System.Net;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace RestaurantApp.IntegrationTests;

[Collection(PostgreSqlCollection.Name)]
public sealed class AntiforgeryTests(PostgreSqlFixture database)
{
    [Fact]
    public async Task Login_rejects_missing_or_forged_tokens_and_accepts_the_form_token()
    {
        await using var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = database.ConnectionString,
                ["HttpsRedirection:Enabled"] = "false"
            })));
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
        var fields = new Dictionary<string, string> { ["Email"] = "missing@example.test", ["Password"] = "NotARealPassword!7" };
        using var missing = await client.PostAsync("/Account/Login", new FormUrlEncodedContent(fields));
        Assert.Equal(HttpStatusCode.BadRequest, missing.StatusCode);
        fields["__RequestVerificationToken"] = "forged";
        using var forged = await client.PostAsync("/Account/Login", new FormUrlEncodedContent(fields));
        Assert.Equal(HttpStatusCode.BadRequest, forged.StatusCode);
        var form = await client.GetStringAsync("/Account/Login");
        var token = Regex.Match(form, "name=\"__RequestVerificationToken\"[^>]*value=\"([^\"]+)\"");
        Assert.True(token.Success, "The login form must issue an antiforgery token.");
        fields["__RequestVerificationToken"] = WebUtility.HtmlDecode(token.Groups[1].Value);
        using var valid = await client.PostAsync("/Account/Login", new FormUrlEncodedContent(fields));
        Assert.Equal(HttpStatusCode.OK, valid.StatusCode);
        Assert.Contains("incorrect", await valid.Content.ReadAsStringAsync());
    }
}
