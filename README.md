# 🧱 Retail Order Analytics — dbt Transformation Layer

![dbt](https://img.shields.io/badge/dbt-1.7-FF694B?style=flat-square&logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=flat-square&logo=snowflake&logoColor=white)
![SQL](https://img.shields.io/badge/Advanced_SQL-4479A1?style=flat-square&logo=postgresql&logoColor=white)
![Testing](https://img.shields.io/badge/Data_Testing-Automated-FF6B35?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)

> Extends the [Retail Snowflake Pipeline](https://github.com/akhila8978/Retail-Snowflake-Project) (Snowpipe, Streams & Tasks, CDC) with a tested, documented dbt transformation layer — turning raw ingested data into a version-controlled, query-ready star schema.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Snowflake Raw Layer (existing)              │
│         Snowpipe ingestion | Streams & Tasks CDC          │
└────────────┬────────────────────────────────────────────┘
             │
    ┌────────▼────────┐
    │   STAGING        │  1:1 with source — renaming, casting only
    │   stg_orders     │  No business logic
    │   stg_customers  │  → schema tests: not_null, unique
    │   stg_products   │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │   INTERMEDIATE    │  Joins + business logic
    │   int_orders_     │  Gross margin calculation
    │   enriched        │  Customer + product context merge
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │   MARTS           │  Star schema (final presentation layer)
    │   fact_orders     │  fact_orders + dim_customer + dim_product + dim_date
    │   dim_customer     │  → relationship + accepted_values tests
    │   dim_product      │
    │   dim_date         │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │   TEST + DOCS      │  dbt test — schema + custom singular tests
    │                     │  dbt docs generate — lineage graph
    └─────────────────┘
```

---

## 📁 Project Structure

```
retail_dbt/
├── models/
│   ├── staging/
│   │   ├── stg_orders.sql          # cleaned, typed order lines
│   │   ├── stg_customers.sql       # cleaned customer records
│   │   ├── stg_products.sql        # cleaned product catalog
│   │   ├── _sources.yml            # source table definitions + tests
│   │   └── _staging.yml            # staging model tests
│   ├── intermediate/
│   │   └── int_orders_enriched.sql # joins + gross margin logic
│   └── marts/
│       ├── fact_orders.sql         # grain: one row per order line
│       ├── dim_customer.sql
│       ├── dim_product.sql
│       ├── dim_date.sql            # generated calendar spine
│       └── _marts.yml              # mart model tests + docs
├── tests/
│   ├── assert_order_total_not_negative.sql
│   └── assert_no_orphaned_orders.sql
├── macros/
│   └── generate_schema_name.sql
├── dbt_project.yml
├── packages.yml                    # dbt_utils
└── profiles.yml.example            # connection template (no real credentials)
```

---

## ⚙️ Key Features

### ✅ Layered Transformation Model
- **Staging** — 1:1 cleaning layer, no business logic, keeps a stable contract with raw sources
- **Intermediate** — joins customer + product context onto orders, computes gross margin per line
- **Marts** — final star schema: one fact table, three dimension tables, ready for BI tools

### ✅ Automated Testing
| Test type | Coverage |
|---|---|
| `not_null` / `unique` | Primary keys across staging, intermediate, and mart layers |
| `relationships` | Referential integrity between `fact_orders` and both dimensions |
| `accepted_values` | `order_status` restricted to a known set of states |
| Custom singular test | `assert_order_total_not_negative` — catches bad data before it reaches dashboards |
| Custom singular test | `assert_no_orphaned_orders` — catches failed joins from upstream CDC |

### ✅ Documentation & Lineage
- Every model and column documented in `schema.yml` files
- `dbt docs generate` produces an interactive lineage graph showing raw → staging → intermediate → marts

### ✅ Star Schema Design
```sql
-- fact_orders: grain = one row per order line
fact_orders (order_id, customer_id, product_id, order_date,
             quantity, unit_price, order_total, gross_margin,
             order_status)

-- dim_customer: one row per customer
dim_customer (customer_id, customer_name, email, country, signup_date)

-- dim_product: one row per catalog item
dim_product (product_id, product_name, category, unit_cost)

-- dim_date: generated calendar spine, 2023–2026
dim_date (date_day, year, month, day, day_of_week, month_name)
```

---

## 🚀 Getting Started

### Prerequisites
- Access to a Snowflake account with the raw tables from the [Retail Snowflake Pipeline](https://github.com/akhila8978/Retail-Snowflake-Project) already loaded
- Python 3.8+

### Setup
```bash
# 1. Clone the repo
git clone https://github.com/akhila8978/retail-order-dbt-pipeline.git
cd retail-order-dbt-pipeline

# 2. Install dbt
pip install dbt-snowflake

# 3. Install packages (dbt_utils)
dbt deps

# 4. Configure connection
cp profiles.yml.example ~/.dbt/profiles.yml
# fill in your Snowflake account/user/password (or set as env vars —
# see profiles.yml.example for the exact env var names)

# 5. Verify connection
dbt debug

# 6. Build all models
dbt run

# 7. Run all tests
dbt test

# 8. Generate + view documentation
dbt docs generate && dbt docs serve
```

---

## 📊 Sample Queries Enabled by the Star Schema

**Monthly revenue by product category:**
```sql
SELECT
    d.year,
    d.month_name,
    p.category,
    SUM(f.order_total)   AS revenue,
    SUM(f.gross_margin)  AS margin
FROM fact_orders f
JOIN dim_date d    ON f.order_date = d.date_day
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY d.year, d.month_name, p.category
ORDER BY d.year, d.month_name;
```

**Top customers by lifetime margin contribution:**
```sql
SELECT
    c.customer_name,
    c.country,
    COUNT(f.order_id)     AS order_count,
    SUM(f.gross_margin)   AS total_margin
FROM fact_orders f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_name, c.country
ORDER BY total_margin DESC
LIMIT 10;
```

---

## 💡 Concepts Demonstrated

| Concept | Implementation |
|---|---|
| Layered transformation architecture | staging → intermediate → marts separation |
| Star schema modeling | Fact + dimension tables, documented grain |
| Data testing | Schema tests + custom singular business-rule tests |
| Source freshness contracts | `_sources.yml` defines and tests the raw source boundary |
| Reusable macros | Custom `generate_schema_name` override |
| Generated dimensions | `dim_date` built via `dbt_utils.date_spine` |
| Documentation as code | Auto-generated lineage graph + column-level descriptions |
| CDC-aware modeling | Built on top of an existing Streams/Tasks CDC pipeline |

---

## 🔗 Tech Stack

`Python` `dbt-core` `dbt-snowflake` `Snowflake` `dbt_utils` `SQL` `Git`

---

## 🔮 Future Improvements

- Incremental materialization on `fact_orders` once order volume justifies it
- Snapshot (SCD Type 2) on `dim_customer` to track attribute changes over time
- CI pipeline (GitHub Actions) running `dbt test` on every pull request

---

## 👩‍💻 Author

**Akhila Kurre** — Data Engineer @ TCS

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/akhila-kurre-75582a1bb/)
[![GitHub](https://img.shields.io/badge/GitHub-akhila8978-181717?style=flat-square&logo=github)](https://github.com/akhila8978)

---

*"Good data engineering is invisible — it just works."*
