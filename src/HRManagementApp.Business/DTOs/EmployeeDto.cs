namespace HRManagementApp.Business.DTOs;

public class EmployeeDto
{
    public string FullName { get; set; } = null!;
    public string Position { get; set; } = null!;
    public double Salary { get; set; }
    public string DepartmentName { get; set; } = null!;
}
