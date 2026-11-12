# Australian FHIR Data Pipeline

A small data engineering project that extracts **synthetic Australian FHIR data**,
organizes the source files, and loads supported resources into PostgreSQL.

## What it does

1. Extracts FHIR JSON files from the configured source.
2. Sorts the files into a more navigable structure.
3. Parses and validates supported resources.
4. Loads the resulting data into PostgreSQL.

See [Architecture](docs/ARCHITECTURE.md) for the component and data-flow overview.

## Prerequisites

- Python [verified version]
- PostgreSQL [verified version]
- `make`
- [Any other required tools, such as `git` or `curl`]

## Quick start

1. Clone the repository and move into its directory.
2. Rename `.env.example` to `.env`
3. Review and update the configuration files:
    - `.env`
    - `config/data.yaml` (don't change the `user` or `password` here, but in `.env`)
    - `config/fhir_resources.yaml`
4. Run the documented setup command:

   ```bash
   make setup
   ```

5. Run the pipeline using the commands documented in
   [Setup](docs/SETUP.md).

> `make setup` prepares the environment and database only if that is what its
> Makefile target actually does. Check `make help` or the Makefile for available
> targets and their effects.

## Configuration

Configuration is stored in `config/`. Do not commit credentials or other secrets.
Use the example values and instructions in [Setup](docs/SETUP.md).

## Data and schema

- `data/raw/` — extracted source data
- `data/processed/` — [describe what the pipeline writes here]
- `data/schema/` — [describe its contents here]

For table definitions, FHIR-to-column mappings, keys, and nullability, see
[Schema](docs/SCHEMA.md).

## Tests

Run the tests with:

```bash
[verified test command]
```

See [Setup](docs/SETUP.md) for separate unit and integration test commands, if
they differ.

## Documentation

- [Setup](docs/SETUP.md) — prerequisites, configuration, database setup, and run commands
- [Architecture](docs/ARCHITECTURE.md) — pipeline flow and component responsibilities
- [Schema](docs/SCHEMA.md) — tables, relationships, and FHIR mappings
- [Troubleshooting](docs/TROUBLESHOOTING.md) — common errors and remedies

## Data notice

The project is intended to use synthetic data. Do not use real patient information
unless the project has been explicitly approved and designed for that purpose.
