🧱 Retail Order Analytics — dbt Transformation Layer

![dbt](https://img.shields.io/badge/dbt-1.7-orange) ![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Warehouse-29B5E8) ![SQL](https://img.shields.io/badge/SQL-Transformations-blue) ![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

> Extends the [Retail Order Pipeline](../retail-order-pipeline) (Snowflake, Streams & Tasks, Snowpipe) with a tested, documented dbt transformation layer — turning raw ingested data into a query-ready star schema.

## Business problem

The upstream pipeline reliably lands and CDC-upserts raw order data into Snowflake, but the "analytics" layer was hand-written SQL with no version control, no automated tests, and no documentation of what each table meant. Analysts querying it had no way to trust the numbers without reading raw SQL scripts. This project rebuilds that layer in dbt so every transformation is version-controlled, tested, and self-documenting.

## Architecture

```
Raw (Snowpipe + Streams/Tasks CDC)
        │
        ▼
┌─────────────────┐
│  staging models  │  1:1 with source, light typing/renaming only
│  stg_orders      │
│  stg_customers   │
│  stg_products    │
└────────┬─────────┘
         ▼
┌─────────────────────┐
│  intermediate models │  joins + business logic (e.g. margin calc)
│  int_orders_enriched │
└────────┬──────────────┘
         ▼
┌──────────────────────────────┐
│  marts (star schema)          │
│  fact_orders                  │
│  dim_customer / dim_product   │
│  dim_date                     │
└────────┬───────────────────────┘
         ▼
   dbt tests + dbt docs (lineage graph)
```

## Tech stack

Python · dbt-core · dbt-snowflake · Snowflake · dbt_utils · Git

## Repo structure

```
retail_dbt/
├── models/
│   ├── staging/          # 1:1 cleaning layer + source definitions
│   ├── intermediate/     # joins + business logic
│   └── marts/            # star schema: fact_orders, dim_customer, dim_product, dim_date
├── tests/                # custom singular tests (business rules)
├── macros/                # reusable Jinja/SQL macros
├── dbt_project.yml
├── packages.yml
└── profiles.yml.example  # connection template (no real credentials)
```

## Data model

**fact_orders** (grain: one row per order line)
| column | description |
|---|---|
| order_id | primary key |
| customer_id | FK → dim_customer |
| product_id | FK → dim_product |
| order_date | order date |
| order_total | quantity × unit price |
| gross_margin | order_total − (quantity × unit_cost) |
| order_status | placed / shipped / delivered / cancelled / returned |

**dim_customer**, **dim_product** — standard dimension tables.
**dim_date** — generated calendar spine (2023–2026) via `dbt_utils.date_spine`.

## Testing

- Schema tests: `not_null`, `unique`, `relationships`, `accepted_values` on every key column (see `models/**/schema.yml`).
- Custom singular tests:
  - `assert_order_total_not_negative` — catches bad data before it reaches dashboards.
  - `assert_no_orphaned_orders` — catches failed joins (missing customer/product match).

Run all tests with:
```bash
dbt test
```

## Setup

```bash
git clone <this-repo>
cd retail_dbt
pip install dbt-snowflake
dbt deps                                   # installs dbt_utils
cp profiles.yml.example ~/.dbt/profiles.yml
# fill in your Snowflake credentials (or set as env vars, see profiles.yml.example)
dbt debug                                  # verify connection
dbt run                                    # build all models
dbt test                                   # run all tests
dbt docs generate && dbt docs serve        # view lineage graph + docs
```

## Documentation & lineage

`dbt docs generate` produces an interactive lineage graph showing how raw sources flow through staging → intermediate → marts. Screenshot below (regenerate locally with `dbt docs serve`):

`[add your own screenshot here after running dbt docs serve]`

## Future improvements

- Incremental materialization on `fact_orders` once order volume justifies it (currently full-refresh table).
- Snapshot (SCD Type 2) on `dim_customer` to track customer attribute changes over time.
- CI pipeline (GitHub Actions) running `dbt test` on every PR.

## Lessons learned

Separating staging/intermediate/marts made it much easier to isolate where a bad number originated during testing — a join issue in the intermediate layer would otherwise have been invisible inside one large mart query.
