with activity_types as (
    select
        *
    from {{ source('postgres_public', 'activity_types') }}
),
w_cleaned as (
    select
        id   as activity_type_id,
        name as activity_type_name,
        case when active = 'Yes' then true
            when active = 'No' then false
            else null
        end  as is_active, -- Convert the active column to a boolean value
        type as activity_type
    from activity_types
)
select
    *
from w_cleaned
