namespace RestaurantApp.Infrastructure.Data.Configurations;

public class MenuItemConfiguration : IEntityTypeConfiguration<MenuItem>
{
    public void Configure(EntityTypeBuilder<MenuItem> builder)
    {
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Name).IsRequired().HasMaxLength(150);
        builder.HasIndex(m => m.Name).IsUnique();
        builder.Property(m => m.Price).HasColumnType("decimal(18,2)");
        
        builder.HasOne(m => m.Category)
               .WithMany(c => c.MenuItems)
               .HasForeignKey(m => m.CategoryId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasData(
            new MenuItem { Id = 1, Name = "Lentil Soup", Price = 5.50m, CategoryId = 1 },
            new MenuItem { Id = 2, Name = "Chicken Soup", Price = 6.00m, CategoryId = 1 },
            new MenuItem { Id = 3, Name = "Beef Steak", Price = 25.00m, CategoryId = 2 },
            new MenuItem { Id = 4, Name = "Grilled Chicken", Price = 15.50m, CategoryId = 2 },
            new MenuItem { Id = 5, Name = "Coca Cola", Price = 2.00m, CategoryId = 3 },
            new MenuItem { Id = 6, Name = "Orange Juice", Price = 3.50m, CategoryId = 3 },
            new MenuItem { Id = 7, Name = "Cheesecake", Price = 7.00m, CategoryId = 4 },
            new MenuItem { Id = 8, Name = "Tiramisu", Price = 8.50m, CategoryId = 4 }
        );
    }
}