namespace HRManagementApp.Business.DTOs;

public class DepartmentDto
{
    public string Name { get; set; } = null!;
    public int WorkerLimit { get; set; }
    public decimal SalaryLimit { get; set; }
}
