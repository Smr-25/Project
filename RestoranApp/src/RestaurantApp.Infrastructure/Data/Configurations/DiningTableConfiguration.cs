namespace RestaurantApp.Infrastructure.Data.Configurations;

public sealed class DiningTableConfiguration : IEntityTypeConfiguration<DiningTable>
{
    public void Configure(EntityTypeBuilder<DiningTable> builder)
    {
        builder.HasKey(table => table.Id);
        builder.Property(table => table.Number).IsRequired().HasMaxLength(20);
        builder.HasIndex(table => table.Number).IsUnique();
        builder.ToTable(table =>
            table.HasCheckConstraint("CK_DiningTables_Capacity_Positive", "\"Capacity\" > 0"));
    }
}
