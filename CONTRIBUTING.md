# Contributing

## Development workflow

1. Create a focused branch from `main`.
2. Keep changes within the existing layer boundaries described in `docs/architecture.md`.
3. Add or update tests for business rules and persistence behavior.
4. Run the local quality gates before opening a pull request.

```bash
dotnet restore RestaurantApp.sln
dotnet build RestaurantApp.sln --configuration Release --no-restore
dotnet test RestaurantApp.sln --configuration Release --no-build
docker build --tag restaurant-app:validation .
```

Docker must be running for the PostgreSQL integration tests.

## Code expectations

- Keep nullable reference types enabled and resolve all compiler warnings.
- Validate input at the HTTP boundary and enforce important invariants in the Domain/Application layers.
- Treat submitted identifiers, quantities and prices as untrusted.
- Use asynchronous database calls and pass cancellation tokens where a public API accepts one.
- Never commit passwords, connection strings, `.env` files or local configuration overrides.
- Prefer migrations that can be reviewed and reproduced over manual schema changes.

## Pull requests

Describe the user-visible outcome, the main design choice and the checks you ran. Keep a pull request small enough to review as one coherent change. CI must pass before merge.
