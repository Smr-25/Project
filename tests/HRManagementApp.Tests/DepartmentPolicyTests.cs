using HRManagementApp.Core.Entities;

namespace HRManagementApp.Tests;

public class DepartmentPolicyTests
{
    [Fact]
    public void HasAvailablePosition_StopsAtWorkerLimit()
    {
        var department = new Department { WorkerLimit = 1 };
        Assert.True(DepartmentPolicy.HasAvailablePosition(department));

        department.Employees.Add(new Employee { Salary = 500m });
        Assert.False(DepartmentPolicy.HasAvailablePosition(department));
    }

    [Fact]
    public void FitsSalaryBudget_RejectsNewEmployeeAboveLimit()
    {
        var department = new Department { SalaryLimit = 1_000m };
        department.Employees.Add(new Employee { Salary = 800m });

        Assert.True(DepartmentPolicy.FitsSalaryBudget(department, 200m));
        Assert.False(DepartmentPolicy.FitsSalaryBudget(department, 250m));
    }

    [Fact]
    public void FitsSalaryBudget_ReplacesExistingSalaryOnEdit()
    {
        var department = new Department { SalaryLimit = 1_000m };
        department.Employees.AddRange([
            new Employee { Salary = 400m },
            new Employee { Salary = 500m }
        ]);

        Assert.True(DepartmentPolicy.FitsSalaryBudget(department, 500m, 400m));
        Assert.False(DepartmentPolicy.FitsSalaryBudget(department, 601m, 500m));
    }
}
