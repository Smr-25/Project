# Project — Application Portfolio

Three independent applications in one repository: two ASP.NET Core web apps and one native iPhone app. Each project has its own setup guide and README.

| Project | Purpose | Stack | Run locally |
|---|---|---|---|
| [HR Management App](HRManagementApp/README.md) | Manage departments, employees, capacity, and salary budgets. | .NET 10, ASP.NET Core MVC, EF Core, PostgreSQL | Docker Compose or .NET SDK |
| [Ember & Oak — Restaurant Operations](RestoranApp/README.md) | Coordinate menus, tables, orders, kitchen work, and reporting. | .NET 10, ASP.NET Core MVC, EF Core, PostgreSQL | Docker Compose or .NET SDK |
| [WordRevisit](WordRevisit/README.md) | Practise English and Azerbaijani words with offline iPhone quizzes. | SwiftUI, Foundation, UserNotifications | Xcode and an iPhone with iOS 18+ |

## A look inside

| HR Management | Restaurant Operations |
|:---:|:---:|
| ![HR dashboard with team and salary totals](HRManagementApp/docs/screenshots/dashboard.jpg) | ![Restaurant dashboard with operational metrics](RestoranApp/docs/screenshots/dashboard.jpg) |
| [Features, setup, architecture, and tests →](HRManagementApp/README.md) | [Features, setup, architecture, and tests →](RestoranApp/README.md) |

### WordRevisit

<p align="center">
  <img src="WordRevisit/docs/screenshots/today.png" alt="WordRevisit Today screen" width="205">
  <img src="WordRevisit/docs/screenshots/words.png" alt="WordRevisit word library" width="205">
  <img src="WordRevisit/docs/screenshots/quiz.png" alt="WordRevisit quiz" width="205">
</p>

<p align="center"><a href="WordRevisit/README.md">Features, iPhone setup, and all screenshots →</a></p>

## Getting started

Both web applications can run with Docker Compose. They each use port `8080`, so run one at a time unless you change the host port. Commands are run inside the selected project directory, not from this repository root.

**HR Management App** generates its local database credential during first startup:

```bash
cd HRManagementApp
docker compose up --build -d
```

Open `http://localhost:8080`. See the [HR setup guide](HRManagementApp/README.md#quick-start) for the published-image option, development commands, and data-volume notes. This app has no login system and is intended for local demonstration, not real employee data.

**Ember & Oak** requires two distinct locally generated passwords before startup:

```bash
cd RestoranApp
cp .env.example .env
```

Follow the [restaurant setup guide](RestoranApp/README.md#quick-start) to fill in `.env` and start the stack. Do not commit the local `.env` file. The restaurant app uses staff roles; its README covers the demo login and workflows.

**WordRevisit** runs locally on an iPhone through Xcode with a free Apple Account; it has no Docker service or App Store deployment. See the [iPhone setup steps](WordRevisit/README.md#run-on-an-iphone-without-the-app-store).

## Repository map

```text
Project/
├── HRManagementApp/        HR application, solution, tests, and Docker files
├── RestoranApp/            Restaurant application, solution, tests, and Docker files
├── WordRevisit/             Native iPhone app, screenshots, and setup guide
└── .github/workflows/      Container publishing workflows for each application
```

The projects are intentionally separate: there is no root-level solution or shared database. The GitHub Actions workflows publish container images only for the two web applications when their files change on `main`.

## Scope and licensing

These are portfolio and learning applications. Review each web project's security notes before using it beyond a local demo. The restaurant and WordRevisit projects each include an MIT license; the HR project does not include a separate license file.
