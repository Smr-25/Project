namespace RestaurantApp.Application.Exceptions;
public class CountZeroException : Exception
{
    public CountZeroException(string message) : base(message) {}
}
