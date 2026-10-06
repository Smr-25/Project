namespace RestaurantApp.Application.Dtos.Orders;
public class OrderCreateDto : IValidatableObject
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a dining table.")]
    public int DiningTableId { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }

    public List<OrderItemCreateDto> OrderItems { get; set; } = new();

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (OrderItems.Count > 25)
        {
            yield return new ValidationResult("An order cannot contain more than 25 rows.", [nameof(OrderItems)]);
        }

        var selectedItems = OrderItems
            .Where(item => item.MenuItemId > 0 || item.Quantity > 0)
            .ToList();
        if (selectedItems.Count == 0)
        {
            yield return new ValidationResult("Select at least one menu item.", [nameof(OrderItems)]);
        }

        if (selectedItems.Any(item => item.MenuItemId <= 0 || item.Quantity is <= 0 or > 99))
        {
            yield return new ValidationResult(
                "Every selected menu item needs a quantity between 1 and 99.",
                [nameof(OrderItems)]);
        }
    }
}
