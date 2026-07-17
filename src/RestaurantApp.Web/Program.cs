using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.Mac.json", optional: true, reloadOnChange: true);

// Add services to the container.
builder.Services.AddControllersWithViews();

builder.Services.AddDbContext<RestaurantApp.Infrastructure.Data.RestaurantDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped(typeof(RestaurantApp.Application.Abstractions.IRepository<>), typeof(RestaurantApp.Infrastructure.Repositories.Concretes.Repository<>));
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.ICategoryService, RestaurantApp.Application.Services.CategoryService>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.IMenuItemService, RestaurantApp.Application.Services.MenuItemService>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.IOrderService, RestaurantApp.Application.Services.OrderService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
