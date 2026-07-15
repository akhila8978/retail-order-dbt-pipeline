with orders_enriched as (

    select * from {{ ref('int_orders_enriched') }}

)

select
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    order_total,
    gross_margin,
    order_status
from orders_enriched
