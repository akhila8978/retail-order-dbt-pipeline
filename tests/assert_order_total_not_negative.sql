-- Singular test: fails (returns rows) if any order has a negative total.
-- dbt tests pass when the query returns zero rows.

select
    order_id,
    order_total
from {{ ref('fact_orders') }}
where order_total < 0
