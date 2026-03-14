-- This intermediate model exists as a placeholder for future transformations and to maintain a consistent structure in the data pipeline.
-- Currently, it simply selects all records from the `stg_activity` staging model and calculates an `activity_status` field.


with activity as (
    select
        *
    from {{ ref('stg_activity') }}
),
w_calculated as (
    select
        a.activity_id,
        a.activity_type,
        a.assigned_to_user_id,
        a.deal_id,
        a.is_done,
        a.due_at,
        case
            when a.is_done = true then 'completed'
            when a.is_done = false and a.due_at > now() then 'pending'
            when a.is_done = false and a.due_at <= now() then 'overdue'
        end as activity_status
    from activity as a
)
select
    *
from w_calculated
