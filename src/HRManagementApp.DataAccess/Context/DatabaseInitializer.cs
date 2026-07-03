using HRManagementApp.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace HRManagementApp.DataAccess.Context;

public static class DatabaseInitializer
{
    public static async Task InitializeAsync(AppDbContext context, CancellationToken cancellationToken = default)
    {
        await context.Database.MigrateAsync(cancellationToken);
        if (await context.Departments.AnyAsync(cancellationToken)) return;

        var it = new Department { Name = "IT", WorkerLimit = 10, SalaryLimit = 25_000m };
        var hr = new Department { Name = "HR", WorkerLimit = 5, SalaryLimit = 10_000m };
        var marketing = new Department { Name = "Marketing", WorkerLimit = 8, SalaryLimit = 12_000m };
        context.Departments.AddRange(it, hr, marketing);
        await context.SaveChangesAsync(cancellationToken);

        var employees = new[]
        {
            new Employee { FullName = "Samir Həsənov", Position = "Senior Backend Developer", Salary = 3_500m, DepartmentId = it.Id },
            new Employee { FullName = "Leyla Əliyeva", Position = "Frontend Developer", Salary = 2_000m, DepartmentId = it.Id },
            new Employee { FullName = "Vüqar Kərimov", Position = "HR Specialist", Salary = 1_500m, DepartmentId = hr.Id },
            new Employee { FullName = "Nigar Rüstəmova", Position = "Marketing Manager", Salary = 2_500m, DepartmentId = marketing.Id }
        };
        context.Employees.AddRange(employees);
        await context.SaveChangesAsync(cancellationToken);

        foreach (var employee in employees)
        {
            var prefix = employee.DepartmentId == hr.Id ? "HR"
                : employee.DepartmentId == marketing.Id ? "MA" : "IT";
            employee.No = $"{prefix}{employee.Id + 1000}";
        }
        await context.SaveChangesAsync(cancellationToken);
    }
}
