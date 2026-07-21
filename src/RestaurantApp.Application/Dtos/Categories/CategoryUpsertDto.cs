using System.ComponentModel.DataAnnotations;

namespace RestaurantApp.Application.Dtos.Categories;

public sealed class CategoryUpsertDto
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [Required, StringLength(300, MinimumLength = 10)]
    public string Description { get; set; } = string.Empty;

    [Range(0, 100)]
    public int DisplayOrder { get; set; }

    public bool IsActive { get; set; } = true;
}
