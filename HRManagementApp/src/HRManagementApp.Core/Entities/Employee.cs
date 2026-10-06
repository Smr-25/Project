namespace HRManagementApp.Core.Entities;

public class Employee
{
    public int Id { get; set; }
    public string? No { get; set; }
    public string FullName { get; set; } = null!;
    public string Position { get; set; } = null!;
    public decimal Salary { get; set; }
    public int DepartmentId { get; set; }
    public Department Department { get; set; } = null!;
}
