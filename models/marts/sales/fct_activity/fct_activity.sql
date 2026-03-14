with activity as (
    select
        *
    from {{ ref('int_activity') }}
),
activity_types as (
    select
        *
    from {{ ref('dim_activity_types') }}
),
users as (
    select
        *
    from {{ ref('dim_users') }}
),
w_joined as (
    select
        a.activity_id,
        a.deal_id,
        at.activity_type_id,
        a.activity_type,
        at.activity_type_name,
        at.funnel_step_label,
        at.funnel_step_order,
        a.assigned_to_user_id,
        u.user_name,
        u.user_email,
        a.is_done,
        a.due_at,
        a.activity_status
    from activity as a
    left join activity_types as at
        on a.activity_type = at.activity_type
    left join users as u
        on a.assigned_to_user_id = u.user_id
)
select
    *
from w_joined
