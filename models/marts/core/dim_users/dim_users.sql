with users as (
    select
        *
    from {{ ref('stg_users') }}
)
select
    user_id,
    user_name,
    user_email,
    modified_at
from users
