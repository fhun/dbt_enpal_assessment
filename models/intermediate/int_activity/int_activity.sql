-- This intermediate model is a pass-through for activities.
-- Currently no transformations are needed beyond what staging provides.
-- This layer exists as a placeholder for future transformations and to maintain a consistent structure in the data pipeline.

with activity as (
    select
        *
    from {{ ref('stg_activity') }}
)
select
    a.activity_id,
    a.activity_type,
    a.assigned_to_user_id,
    a.deal_id,
    a.is_done,
    a.due_at
from activity as a
