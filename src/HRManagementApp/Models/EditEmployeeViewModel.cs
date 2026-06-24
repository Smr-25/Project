using System.ComponentModel.DataAnnotations;

namespace HRManagementApp.Models;

public class EditEmployeeViewModel
{
    public string No { get; set; } = null!;
    
    [Required(ErrorMessage = "Position is required.")]
    [MinLength(2, ErrorMessage = "Position must be at least 2 characters long.")]
    public string Position { get; set; } = null!;
    
    [Required(ErrorMessage = "Salary is required.")]
    [Range(250, double.MaxValue, ErrorMessage = "Salary cannot be less than 250.")]
    public double Salary { get; set; }
}
