using Microsoft.EntityFrameworkCore.Design;

namespace RestaurantApp.Infrastructure.Data;

public sealed class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<RestaurantDbContext>
{
    public RestaurantDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? "Host=localhost;Database=restaurant_app;Username=restaurant_app";

        var options = new DbContextOptionsBuilder<RestaurantDbContext>()
            .UseNpgsql(connectionString)
            .Options;

        return new RestaurantDbContext(options);
    }
}
