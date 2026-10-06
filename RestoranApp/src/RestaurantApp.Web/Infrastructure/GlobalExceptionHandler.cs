using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.Exceptions;

namespace RestaurantApp.Web.Infrastructure;

public sealed class GlobalExceptionHandler(
    ILogger<GlobalExceptionHandler> logger,
    IProblemDetailsService problemDetailsService) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (status, title, detail) = exception switch
        {
            EntityNotFoundException => (StatusCodes.Status404NotFound, "Resource not found", exception.Message),
            EntityAlreadyExistException => (StatusCodes.Status409Conflict, "Resource already exists", exception.Message),
            CountZeroException or ArgumentException => (StatusCodes.Status400BadRequest, "Invalid request", exception.Message),
            InvalidOperationException => (StatusCodes.Status409Conflict, "Operation not allowed", exception.Message),
            _ => (StatusCodes.Status500InternalServerError, "Unexpected error", "The request could not be completed.")
        };

        if (status == StatusCodes.Status500InternalServerError)
        {
            logger.LogError(exception, "Unhandled request failure. Trace identifier: {TraceIdentifier}", httpContext.TraceIdentifier);
        }
        else
        {
            logger.LogWarning(exception, "Rejected request. Trace identifier: {TraceIdentifier}", httpContext.TraceIdentifier);
        }

        httpContext.Response.StatusCode = status;
        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            ProblemDetails = new ProblemDetails
            {
                Status = status,
                Title = title,
                Detail = detail,
                Extensions = { ["traceId"] = httpContext.TraceIdentifier }
            },
            Exception = exception
        });
    }
}
