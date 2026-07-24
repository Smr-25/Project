namespace RestaurantApp.Web.Infrastructure;

public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
            headers.Append("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
            headers.Append(
                "Content-Security-Policy",
                "default-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline'; script-src 'self'; font-src 'self' data:; form-action 'self'; frame-ancestors 'none'");
            return Task.CompletedTask;
        });

        await next(context);
    }
}
