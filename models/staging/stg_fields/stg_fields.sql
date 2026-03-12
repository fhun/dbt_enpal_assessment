with fields as (
    select
        *
    from {{ source('postgres_public', 'fields') }}
),
w_cleaned as (
    select
        id   as field_id,
        field_key,
        name as field_name,
        field_value_options
    from fields
)
select
    *
from w_cleaned
