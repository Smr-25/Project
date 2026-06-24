namespace HRManagementApp.Business.DTOs;

public class DepartmentDto
{
    public string Name { get; set; } = null!;
    public int WorkerLimit { get; set; }
    public double SalaryLimit { get; set; }
}
