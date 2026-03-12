-- This intermediate model joins the activity and activity types staging models
-- to provide a more comprehensive view of activities, including their activity_type_name (Sales Call 1, Sales Call 2) and related information.

with activity as (
    select
        *
    from {{ ref('stg_activity') }}
),
activity_types as (
    select
        *
    from {{ ref('stg_activity_types') }}
),
w_joined as (
    select
        a.activity_id,
        a.activity_type,
        at.activity_type_name,
        a.assigned_to_user_id,
        a.deal_id,
        a.is_done,
        a.due_at
    from activity as a
    left join activity_types as at -- To prevent losing any activity records that do not have a matching activity type in the future.
        on a.activity_type = at.activity_type
)
select
    *
from w_joined
