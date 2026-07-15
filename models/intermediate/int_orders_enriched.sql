-- Intermediate layer: this is where joins and business logic live,
-- kept separate from staging (no logic) and marts (final presentation).

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

enriched as (

    select
        orders.order_id,
        orders.order_date,
        orders.quantity,
        orders.unit_price,
        orders.order_total,
        orders.order_status,

        customers.customer_id,
        customers.customer_name,
        customers.country       as customer_country,

        products.product_id,
        products.product_name,
        products.category       as product_category,
        products.unit_cost,

        -- business logic: margin per order line
        orders.order_total - (orders.quantity * products.unit_cost) as gross_margin

    from orders
    left join customers on orders.customer_id = customers.customer_id
    left join products  on orders.product_id  = products.product_id

)

select * from enriched
