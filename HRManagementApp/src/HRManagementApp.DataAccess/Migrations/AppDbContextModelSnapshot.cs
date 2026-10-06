using HRManagementApp.DataAccess.Context;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace HRManagementApp.DataAccess.Migrations;

[DbContext(typeof(AppDbContext))]
public partial class AppDbContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.0");
        modelBuilder.HasPostgresExtension("citext");

        modelBuilder.Entity("HRManagementApp.Core.Entities.Department", entity =>
        {
            entity.Property<int>("Id").ValueGeneratedOnAdd().HasColumnType("integer")
                .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);
            entity.Property<string>("Name").IsRequired().HasMaxLength(100).HasColumnType("citext");
            entity.Property<int>("WorkerLimit").HasColumnType("integer");
            entity.Property<decimal>("SalaryLimit").HasPrecision(12, 2).HasColumnType("numeric(12,2)");
            entity.HasKey("Id");
            entity.HasIndex("Name").IsUnique();
            entity.ToTable("Departments", table =>
            {
                table.HasCheckConstraint("CK_Departments_WorkerLimit", "\"WorkerLimit\" >= 1");
                table.HasCheckConstraint("CK_Departments_SalaryLimit", "\"SalaryLimit\" >= 250");
            });
        });

        modelBuilder.Entity("HRManagementApp.Core.Entities.Employee", entity =>
        {
            entity.Property<int>("Id").ValueGeneratedOnAdd().HasColumnType("integer")
                .HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);
            entity.Property<string>("No").HasMaxLength(32).HasColumnType("character varying(32)");
            entity.Property<string>("FullName").IsRequired().HasMaxLength(150).HasColumnType("character varying(150)");
            entity.Property<string>("Position").IsRequired().HasMaxLength(100).HasColumnType("character varying(100)");
            entity.Property<decimal>("Salary").HasPrecision(12, 2).HasColumnType("numeric(12,2)");
            entity.Property<int>("DepartmentId").HasColumnType("integer");
            entity.HasKey("Id");
            entity.HasIndex("DepartmentId");
            entity.HasIndex("No").IsUnique();
            entity.ToTable("Employees", table =>
                table.HasCheckConstraint("CK_Employees_Salary", "\"Salary\" >= 250"));
        });

        modelBuilder.Entity("HRManagementApp.Core.Entities.Employee", entity =>
        {
            entity.HasOne("HRManagementApp.Core.Entities.Department", "Department")
                .WithMany("Employees")
                .HasForeignKey("DepartmentId")
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired();
            entity.Navigation("Department");
        });

        modelBuilder.Entity("HRManagementApp.Core.Entities.Department", entity =>
            entity.Navigation("Employees"));
    }
}
