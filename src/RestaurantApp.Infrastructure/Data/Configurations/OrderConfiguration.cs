namespace RestaurantApp.Infrastructure.Data.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.HasKey(o => o.Id);
        builder.Property(o => o.Number).IsRequired().HasMaxLength(32);
        builder.HasIndex(o => o.Number).IsUnique();
        builder.Property(o => o.TotalAmount).HasPrecision(10, 2);
        builder.Property(o => o.CreatedAtUtc).IsRequired();
        builder.Property(o => o.Status).IsRequired();
        builder.Property(o => o.Notes).HasMaxLength(500);
        builder.Property(o => o.CancellationReason).HasMaxLength(300);
        builder.ToTable(table => table.HasCheckConstraint("CK_Orders_TotalAmount_NonNegative", "\"TotalAmount\" >= 0"));

        builder.HasOne(o => o.DiningTable)
            .WithMany(table => table.Orders)
            .HasForeignKey(o => o.DiningTableId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
