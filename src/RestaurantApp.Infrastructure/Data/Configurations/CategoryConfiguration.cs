namespace RestaurantApp.Infrastructure.Data.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Name).IsRequired().HasMaxLength(100);

        builder.HasData(
            new Category { Id = 1, Name = "Soups" },
            new Category { Id = 2, Name = "Main Courses" },
            new Category { Id = 3, Name = "Drinks" },
            new Category { Id = 4, Name = "Desserts" }
        );
    }
}