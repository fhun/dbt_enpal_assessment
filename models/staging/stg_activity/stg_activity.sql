with activity as (
    select
        *
    from {{ source('postgres_public', 'activity') }}
),
-- From the source data exploration, we found that there are 11 duplicate records in the activity table for the same activity_id.
-- Deduplicate the activity table to keep only the most recent record for each activity_id.
w_deduped as (
    select
        *,
        row_number() over (
            partition by activity_id
            order by due_to desc
        ) as rn
    from activity
),
w_cleaned as (
    select
        activity_id,
        type             as activity_type,
        assigned_to_user as assigned_to_user_id,
        deal_id,
        done             as is_done,
        due_to           as due_at
    from w_deduped
    where rn = 1
)
select
    *
from w_cleaned
