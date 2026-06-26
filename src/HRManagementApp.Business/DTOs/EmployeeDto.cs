namespace HRManagementApp.Business.DTOs;

public class EmployeeDto
{
    public string FullName { get; set; } = null!;
    public string Position { get; set; } = null!;
    public decimal Salary { get; set; }
    public int DepartmentId { get; set; }
}
