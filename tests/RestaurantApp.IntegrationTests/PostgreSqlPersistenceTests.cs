using Microsoft.EntityFrameworkCore;
using RestaurantApp.Domain.Models;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.IntegrationTests;

[Collection(PostgreSqlCollection.Name)]
public sealed class PostgreSqlPersistenceTests(PostgreSqlFixture fixture)
{
    [Fact]
    public async Task Migrations_and_seed_create_a_ready_demo_database()
    {
        await using var context = CreateContext();

        await DatabaseInitializer.InitializeAsync(context);

        Assert.NotEmpty(await context.Database.GetAppliedMigrationsAsync());
        Assert.Equal(4, await context.Categories.CountAsync());
        Assert.Equal(8, await context.MenuItems.CountAsync());
        Assert.Equal(12, await context.DiningTables.CountAsync());
    }

    [Fact]
    public async Task Order_graph_persists_the_table_status_and_price_snapshot()
    {
        await using var context = CreateContext();
        await DatabaseInitializer.InitializeAsync(context);
        var table = await context.DiningTables.OrderBy(item => item.Id).FirstAsync();
        var menuItem = await context.MenuItems.OrderBy(item => item.Id).FirstAsync();
        var originalPrice = menuItem.Price;
        var orderNumber = $"ORD-TEST-{Guid.NewGuid().ToString("N")[..16]}";
        var order = Order.Create(orderNumber, table.Id, "Integration test order");
        order.AddItem(menuItem, 2, "Light salt");
        context.Orders.Add(order);

        await context.SaveChangesAsync();
        context.ChangeTracker.Clear();

        var stored = await context.Orders
            .Include(item => item.DiningTable)
            .Include(item => item.OrderItems)
            .SingleAsync(item => item.Number == order.Number);
        var line = Assert.Single(stored.OrderItems);
        Assert.Equal(OrderStatus.Pending, stored.Status);
        Assert.Equal(table.Number, stored.DiningTable!.Number);
        Assert.Equal(originalPrice, line.UnitPrice);
        Assert.Equal(originalPrice * 2, stored.TotalAmount);
    }

    [Fact]
    public async Task Database_constraint_rejects_a_non_positive_menu_price()
    {
        await using var context = CreateContext();
        await DatabaseInitializer.InitializeAsync(context);
        var category = await context.Categories.FirstAsync();
        context.MenuItems.Add(new MenuItem
        {
            Name = $"Invalid-{Guid.NewGuid():N}",
            Description = "A deliberately invalid database test item.",
            Price = 0,
            CategoryId = category.Id
        });

        await Assert.ThrowsAsync<DbUpdateException>(() => context.SaveChangesAsync());
    }

    private RestaurantDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<RestaurantDbContext>()
            .UseNpgsql(fixture.ConnectionString)
            .Options;
        return new RestaurantDbContext(options);
    }
}
