using System.ComponentModel.DataAnnotations;

namespace HRManagementApp.Models;

public class EditDepartmentViewModel
{
    public string OldName { get; set; } = null!;
    
    [Required(ErrorMessage = "New name is required.")]
    [MinLength(2, ErrorMessage = "New name must be at least 2 characters long.")]
    public string NewName { get; set; } = null!;
}
