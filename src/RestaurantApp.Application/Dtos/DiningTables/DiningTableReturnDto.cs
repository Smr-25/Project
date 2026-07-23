namespace RestaurantApp.Application.Dtos.DiningTables;

public sealed class DiningTableReturnDto
{
    public int Id { get; set; }
    public string Number { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public bool IsActive { get; set; }
    public bool IsOccupied { get; set; }
    public string? ActiveOrderNumber { get; set; }
}
