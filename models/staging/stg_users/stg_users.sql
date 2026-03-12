with users as (
    select
        *
    from {{ source('postgres_public', 'users') }}
),
w_cleaned as (
    select
        id       as user_id,
        name     as user_name,
        email    as user_email,
        modified as modified_at
    from users
)
select
    *
from w_cleaned
