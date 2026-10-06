using RestaurantApp.Application.Dtos.DiningTables;

namespace RestaurantApp.Application.Interfaces;

public interface IDiningTableService
{
    Task<List<DiningTableReturnDto>> GetAllAsync();
    Task<List<DiningTableReturnDto>> GetAvailableAsync();
    Task<DiningTableReturnDto> GetByIdAsync(int id);
    Task AddAsync(DiningTableUpsertDto dto);
    Task EditAsync(int id, DiningTableUpsertDto dto);
}
