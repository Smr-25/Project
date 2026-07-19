namespace RestaurantApp.Application.Security;

public static class RestaurantRoles
{
    public const string Admin = "Admin";
    public const string Manager = "Manager";
    public const string Waiter = "Waiter";
    public const string Kitchen = "Kitchen";

    public static readonly string[] All = [Admin, Manager, Waiter, Kitchen];
    public const string Management = Admin + "," + Manager;
    public const string OrderStaff = Admin + "," + Manager + "," + Waiter + "," + Kitchen;
}
