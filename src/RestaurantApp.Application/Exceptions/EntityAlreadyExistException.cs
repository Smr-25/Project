namespace RestaurantApp.Application.Exceptions;
public class EntityAlreadyExistException : Exception
{
    public EntityAlreadyExistException(string message) : base(message) {}
}
