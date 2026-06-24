using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace HRManagementApp.DataAccess.Migrations
{
    /// <inheritdoc />
    public partial class AddSeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Departments",
                columns: new[] { "Name", "SalaryLimit", "WorkerLimit" },
                values: new object[,]
                {
                    { "HR", 10000.0, 5 },
                    { "IT", 25000.0, 10 },
                    { "Marketing", 12000.0, 8 }
                });

            migrationBuilder.InsertData(
                table: "Employees",
                columns: new[] { "No", "DepartmentName", "FullName", "Position", "Salary" },
                values: new object[,]
                {
                    { "HR1003", "HR", "Vüqar Kərimov", "HR Specialist", 1500.0 },
                    { "IT1001", "IT", "Samir Həsənov", "Senior Backend Developer", 3500.0 },
                    { "IT1002", "IT", "Leyla Əliyeva", "Frontend Developer", 2000.0 },
                    { "MA1004", "Marketing", "Nigar Rüstəmova", "Marketing Manager", 2500.0 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Employees",
                keyColumn: "No",
                keyValue: "HR1003");

            migrationBuilder.DeleteData(
                table: "Employees",
                keyColumn: "No",
                keyValue: "IT1001");

            migrationBuilder.DeleteData(
                table: "Employees",
                keyColumn: "No",
                keyValue: "IT1002");

            migrationBuilder.DeleteData(
                table: "Employees",
                keyColumn: "No",
                keyValue: "MA1004");

            migrationBuilder.DeleteData(
                table: "Departments",
                keyColumn: "Name",
                keyValue: "HR");

            migrationBuilder.DeleteData(
                table: "Departments",
                keyColumn: "Name",
                keyValue: "IT");

            migrationBuilder.DeleteData(
                table: "Departments",
                keyColumn: "Name",
                keyValue: "Marketing");
        }
    }
}
