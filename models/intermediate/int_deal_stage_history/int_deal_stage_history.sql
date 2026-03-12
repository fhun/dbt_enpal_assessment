-- This intermediate model is a comprehensive history of deal stage changes by joining the deal_changes, fields, and stages staging models.
-- It filters the deal_changes to only include records where the changed field key is 'stage_id'.
-- As mentioned in the source data exploration, there are 17 cases where the stage changed backwards or re-entered,
-- which is expected in a real-world sales process. I decided to keep all the stage changes in the analysis.
-- I also calculate the duration of each stage for each deal, and whether the stage is the current stage for the deal, for future analysis on stage duration and conversion rates.

with deal_changes as (
    select
        *
    from {{ ref('stg_deal_changes') }}
),
stages as (
    select
        *
    from {{ ref('stg_stages') }}
),
w_joined as (
    select
        dc.deal_id,
        dc.changed_at,
        dc.new_value::int as stage_id,
        s.stage_name
    from deal_changes as dc
    left join stages as s
        on dc.new_value::int = s.stage_id
    where dc.changed_field_key = 'stage_id' -- Filter to only include stage changes
),
w_stage_end_time as (
    select
        deal_id,
        stage_id,
        stage_name,
        changed_at as stage_started_at,
        lead(changed_at) over (
            partition by deal_id
            order by changed_at
        )          as stage_ended_at
    from w_joined
),
w_stage_duration as (
    select
        deal_id,
        stage_id,
        stage_name,
        stage_started_at,
        stage_ended_at,
        date_part('day', coalesce(stage_ended_at, current_timestamp) - stage_started_at) as stage_duration_days,
        stage_ended_at is null                                                           as is_current_stage
    from w_stage_end_time
)
select
    *
from w_stage_duration
