with stages as (
    select
        *
    from {{ source('postgres_public', 'stages') }}
),
w_cleaned as ( -- without any transformations, just select the columns for consistency
    select
        stage_id,
        stage_name
    from stages
)
select
    *
from w_cleaned
