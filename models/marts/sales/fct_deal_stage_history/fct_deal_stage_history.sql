with deal_stage_history as (
    select
        *
    from {{ ref('int_deal_stage_history') }}
),
stages as (
    select
        *
    from {{ ref('dim_stages') }}
),
w_joined as (
    select
        dsh.deal_id,
        dsh.stage_id,
        s.stage_name,
        s.funnel_step_label,
        dsh.stage_started_at,
        dsh.stage_ended_at,
        dsh.stage_duration_days,
        dsh.is_current_stage
    from deal_stage_history as dsh
    left join stages as s
        on dsh.stage_id = s.stage_id
)
select
    *
from w_joined
