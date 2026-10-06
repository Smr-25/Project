namespace RestaurantApp.Application.Dtos.DiningTables;

public sealed class DiningTableUpsertDto
{
    [Required, StringLength(20, MinimumLength = 1)]
    public string Number { get; set; } = string.Empty;

    [Range(1, 30)]
    public int Capacity { get; set; } = 2;

    public bool IsActive { get; set; } = true;
}
