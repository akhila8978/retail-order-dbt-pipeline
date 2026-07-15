-- Staging models do light cleaning only: renaming, casting, no business logic.
-- Keeps a 1:1 grain with the source so downstream models can trust it.

with source as (

    select * from {{ source('retail_raw', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        product_id,
        cast(order_date as date)          as order_date,
        cast(quantity as integer)         as quantity,
        cast(unit_price as decimal(10,2)) as unit_price,
        cast(quantity as integer) * cast(unit_price as decimal(10,2)) as order_total,
        upper(trim(order_status))         as order_status,
        _loaded_at

    from source

)

select * from renamed
