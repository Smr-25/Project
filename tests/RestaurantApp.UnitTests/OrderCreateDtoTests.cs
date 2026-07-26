using System.ComponentModel.DataAnnotations;
using RestaurantApp.Application.Dtos.OrderItems;
using RestaurantApp.Application.Dtos.Orders;

namespace RestaurantApp.UnitTests;

public sealed class OrderCreateDtoTests
{
    [Fact]
    public void Validation_requires_a_table_and_at_least_one_complete_item()
    {
        var missingTable = new OrderCreateDto
        {
            OrderItems = [new OrderItemCreateDto { MenuItemId = 1, Quantity = 1 }]
        };
        var missingItems = new OrderCreateDto
        {
            DiningTableId = 2,
            OrderItems = [new OrderItemCreateDto()]
        };

        var tableErrors = Validate(missingTable);
        var itemErrors = Validate(missingItems);

        Assert.Contains(tableErrors, error => error.MemberNames.Contains(nameof(OrderCreateDto.DiningTableId)));
        Assert.Contains(itemErrors, error => error.MemberNames.Contains(nameof(OrderCreateDto.OrderItems)));
    }

    [Fact]
    public void Validation_accepts_a_complete_order()
    {
        var model = new OrderCreateDto
        {
            DiningTableId = 2,
            Notes = "Birthday table",
            OrderItems = [new OrderItemCreateDto { MenuItemId = 9, Quantity = 2 }]
        };

        Assert.Empty(Validate(model));
    }

    private static List<ValidationResult> Validate(object model)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(model, new ValidationContext(model), results, validateAllProperties: true);
        return results;
    }
}
