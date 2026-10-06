namespace HRManagementApp.Business.Services;

public sealed class BusinessRuleException(string message) : Exception(message);
