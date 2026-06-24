using HRManagementApp.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace HRManagementApp.DataAccess.Context;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Department> Departments { get; set; } = null!;
    public DbSet<Employee> Employees { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Department>().HasKey(d => d.Name);
        modelBuilder.Entity<Employee>().HasKey(e => e.No);

        modelBuilder.Entity<Employee>()
            .HasOne<Department>()
            .WithMany(d => d.Employees)
            .HasForeignKey(e => e.DepartmentName)
            .OnDelete(DeleteBehavior.Cascade);

        // Seed Data 
        modelBuilder.Entity<Department>().HasData(
            new Department { Name = "IT", WorkerLimit = 10, SalaryLimit = 25000 },
            new Department { Name = "HR", WorkerLimit = 5, SalaryLimit = 10000 },
            new Department { Name = "Marketing", WorkerLimit = 8, SalaryLimit = 12000 }
        );

        modelBuilder.Entity<Employee>().HasData(
            new Employee { No = "IT1001", FullName = "Samir Həsənov", Position = "Senior Backend Developer", Salary = 3500, DepartmentName = "IT" },
            new Employee { No = "IT1002", FullName = "Leyla Əliyeva", Position = "Frontend Developer", Salary = 2000, DepartmentName = "IT" },
            new Employee { No = "HR1003", FullName = "Vüqar Kərimov", Position = "HR Specialist", Salary = 1500, DepartmentName = "HR" },
            new Employee { No = "MA1004", FullName = "Nigar Rüstəmova", Position = "Marketing Manager", Salary = 2500, DepartmentName = "Marketing" }
        );

        base.OnModelCreating(modelBuilder);
    }
}
