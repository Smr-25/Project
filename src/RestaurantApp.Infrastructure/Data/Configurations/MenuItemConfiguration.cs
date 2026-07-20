namespace RestaurantApp.Infrastructure.Data.Configurations;

public class MenuItemConfiguration : IEntityTypeConfiguration<MenuItem>
{
    public void Configure(EntityTypeBuilder<MenuItem> builder)
    {
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Name).IsRequired().HasMaxLength(150);
        builder.Property(m => m.Description).IsRequired().HasMaxLength(500);
        builder.Property(m => m.ImageUrl).HasMaxLength(500);
        builder.HasIndex(m => m.Name).IsUnique();
        builder.Property(m => m.Price).HasPrecision(10, 2);
        builder.ToTable(table => table.HasCheckConstraint("CK_MenuItems_Price_Positive", "\"Price\" > 0"));
        
        builder.HasOne(m => m.Category)
               .WithMany(c => c.MenuItems)
               .HasForeignKey(m => m.CategoryId)
               .OnDelete(DeleteBehavior.Restrict);

    }
}
