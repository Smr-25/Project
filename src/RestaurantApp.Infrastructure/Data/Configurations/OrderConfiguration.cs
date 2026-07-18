namespace RestaurantApp.Infrastructure.Data.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.HasKey(o => o.Id);
        builder.Property(o => o.Number).IsRequired().HasMaxLength(32);
        builder.HasIndex(o => o.Number).IsUnique();
        builder.Property(o => o.TotalAmount).HasColumnType("decimal(18,2)");
        builder.Property(o => o.CreatedAtUtc).IsRequired();
        builder.Property(o => o.Status).IsRequired();
        builder.Property(o => o.Notes).HasMaxLength(500);
        builder.Property(o => o.CancellationReason).HasMaxLength(300);
    }
}
