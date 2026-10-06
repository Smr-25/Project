using HRManagementApp.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace HRManagementApp.DataAccess.Context;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Department> Departments => Set<Department>();
    public DbSet<Employee> Employees => Set<Employee>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Department>(entity =>
        {
            entity.HasKey(department => department.Id);
            entity.Property(department => department.Name)
                .HasColumnType("citext")
                .HasMaxLength(100)
                .IsRequired();
            entity.HasIndex(department => department.Name).IsUnique();
            entity.Property(department => department.SalaryLimit)
                .HasPrecision(12, 2);
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_Departments_WorkerLimit", "\"WorkerLimit\" >= 1");
                table.HasCheckConstraint("CK_Departments_SalaryLimit", "\"SalaryLimit\" >= 250");
            });
        });

        modelBuilder.Entity<Employee>(entity =>
        {
            entity.HasKey(employee => employee.Id);
            entity.Property(employee => employee.No).HasMaxLength(32);
            entity.HasIndex(employee => employee.No).IsUnique();
            entity.Property(employee => employee.FullName).HasMaxLength(150).IsRequired();
            entity.Property(employee => employee.Position).HasMaxLength(100).IsRequired();
            entity.Property(employee => employee.Salary).HasPrecision(12, 2);
            entity.ToTable(table =>
                table.HasCheckConstraint("CK_Employees_Salary", "\"Salary\" >= 250"));
            entity.HasOne(employee => employee.Department)
                .WithMany(department => department.Employees)
                .HasForeignKey(employee => employee.DepartmentId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
