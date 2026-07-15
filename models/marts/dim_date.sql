with spine as (

    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2023-01-01' as date)",
            end_date="cast('2027-01-01' as date)"
        )
    }}

)

select
    date_day,
    extract(year from date_day)    as year,
    extract(month from date_day)   as month,
    extract(day from date_day)     as day,
    extract(dayofweek from date_day) as day_of_week,
    to_char(date_day, 'Month')     as month_name
from spine

