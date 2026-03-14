with stages as (
    select
        *
    from {{ ref('stg_stages') }}
),
w_added_column as (
    select
        stage_id,
        'Step ' || cast(stage_id as text) as funnel_step_label, -- Add a new column for funnel step label based on stage_id
        stage_name
    from stages
)
select
    *
from w_added_column
