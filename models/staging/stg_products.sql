with source as (

    select * from {{ source('retail_raw', 'products') }}

),

renamed as (

    select
        product_id,
        trim(product_name) as product_name,
        trim(category)     as category,
        cast(unit_cost as decimal(10,2)) as unit_cost

    from source

)

select * from renamed
