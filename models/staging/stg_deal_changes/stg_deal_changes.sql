with deal_changes as (
    select
        *
    from {{ source('postgres_public', 'deal_changes') }}
),
w_cleaned as (
    select
        deal_id,
        change_time       as changed_at,
        changed_field_key,
        new_value
    from deal_changes
)
select
    *
from w_cleaned
