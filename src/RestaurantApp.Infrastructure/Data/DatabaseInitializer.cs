namespace RestaurantApp.Infrastructure.Data;

public static class DatabaseInitializer
{
    public static async Task InitializeAsync(
        RestaurantDbContext context,
        CancellationToken cancellationToken = default)
    {
        await context.Database.MigrateAsync(cancellationToken);

        if (!await context.Categories.AnyAsync(cancellationToken))
        {
            var soups = new Category
            {
                Name = "Soups",
                Description = "Fresh soups prepared daily.",
                DisplayOrder = 1
            };
            var mains = new Category
            {
                Name = "Main courses",
                Description = "Signature plates from the kitchen.",
                DisplayOrder = 2
            };
            var drinks = new Category
            {
                Name = "Drinks",
                Description = "Cold and hot beverages.",
                DisplayOrder = 3
            };
            var desserts = new Category
            {
                Name = "Desserts",
                Description = "Desserts baked and plated in house.",
                DisplayOrder = 4
            };

            context.Categories.AddRange(soups, mains, drinks, desserts);
            context.MenuItems.AddRange(
                NewMenuItem("Lentil soup", "Red lentils, vegetables and warm spices.", 5.50m, soups),
                NewMenuItem("Chicken soup", "Slow-cooked chicken broth with herbs.", 6.00m, soups),
                NewMenuItem("Beef steak", "Grilled beef steak with seasonal garnish.", 25.00m, mains),
                NewMenuItem("Grilled chicken", "Herb-marinated chicken with roasted vegetables.", 15.50m, mains),
                NewMenuItem("Coca-Cola", "Chilled classic soft drink.", 2.00m, drinks),
                NewMenuItem("Orange juice", "Freshly pressed orange juice.", 3.50m, drinks),
                NewMenuItem("Cheesecake", "Creamy cheesecake with berry sauce.", 7.00m, desserts),
                NewMenuItem("Tiramisu", "Espresso-soaked Italian dessert.", 8.50m, desserts));
        }

        if (!await context.DiningTables.AnyAsync(cancellationToken))
        {
            for (var number = 1; number <= 12; number++)
            {
                context.DiningTables.Add(new DiningTable
                {
                    Number = number.ToString("00"),
                    Capacity = number <= 4 ? 2 : number <= 9 ? 4 : 6
                });
            }
        }

        await context.SaveChangesAsync(cancellationToken);
    }

    private static MenuItem NewMenuItem(
        string name,
        string description,
        decimal price,
        Category category) => new()
        {
            Name = name,
            Description = description,
            Price = price,
            Category = category,
            IsAvailable = true
        };
}
