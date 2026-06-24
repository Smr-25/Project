namespace HRManagementApp.Core.Entities;

public class Employee
{
    public string No { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Position { get; set; } = null!;
    public double Salary { get; set; }
    public string DepartmentName { get; set; } = null!;
}
