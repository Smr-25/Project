using FluentValidation;
using HRManagementApp.DataAccess.Context;
using HRManagementApp.DataAccess.Extensions;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDataAccessServices(connectionString);

// Changing from Singleton to Scoped because DbContext must be Scoped
builder.Services.AddScoped<HRManagementApp.Core.Interfaces.IHumanResourceManager, HRManagementApp.Business.Services.HumanResourceManager>();
builder.Services.AddValidatorsFromAssemblyContaining<HRManagementApp.Business.Validators.EmployeeDtoValidator>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await DatabaseInitializer.InitializeAsync(context);
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapGet("/healthz", () => Results.Ok(new { status = "ok" }));

app.Run();
