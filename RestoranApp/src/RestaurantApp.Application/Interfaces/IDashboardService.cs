using RestaurantApp.Application.Dtos.Dashboard;

namespace RestaurantApp.Application.Interfaces;

public interface IDashboardService
{
    Task<DashboardDto> GetAsync();
}
