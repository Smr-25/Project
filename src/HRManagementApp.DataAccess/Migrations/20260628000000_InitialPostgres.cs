using HRManagementApp.DataAccess.Context;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace HRManagementApp.DataAccess.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260628000000_InitialPostgres")]
public partial class InitialPostgres : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("CREATE EXTENSION IF NOT EXISTS citext;");

        migrationBuilder.CreateTable(
            name: "Departments",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                Name = table.Column<string>(type: "citext", maxLength: 100, nullable: false),
                WorkerLimit = table.Column<int>(type: "integer", nullable: false),
                SalaryLimit = table.Column<decimal>(type: "numeric(12,2)", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Departments", department => department.Id);
                table.CheckConstraint("CK_Departments_WorkerLimit", "\"WorkerLimit\" >= 1");
                table.CheckConstraint("CK_Departments_SalaryLimit", "\"SalaryLimit\" >= 250");
            });

        migrationBuilder.CreateTable(
            name: "Employees",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                No = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                FullName = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                Position = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                Salary = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                DepartmentId = table.Column<int>(type: "integer", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Employees", employee => employee.Id);
                table.CheckConstraint("CK_Employees_Salary", "\"Salary\" >= 250");
                table.ForeignKey(
                    name: "FK_Employees_Departments_DepartmentId",
                    column: employee => employee.DepartmentId,
                    principalTable: "Departments",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(name: "IX_Departments_Name", table: "Departments", column: "Name", unique: true);
        migrationBuilder.CreateIndex(name: "IX_Employees_DepartmentId", table: "Employees", column: "DepartmentId");
        migrationBuilder.CreateIndex(name: "IX_Employees_No", table: "Employees", column: "No", unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Employees");
        migrationBuilder.DropTable(name: "Departments");
    }
}
