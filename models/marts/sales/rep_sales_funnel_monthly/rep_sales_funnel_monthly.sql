-- To answer the business question of how many deals are in each stage of the sales funnel on a monthly basis,
-- we need to combine data from both the activity and deal stage history tables. The following SQL code achieves
-- this by aggregating the number of deals at each funnel step for each month, based on both completed activities and stage changes.
-- There are some assumptions made in this code:
-- 1. I use the due_at date of activities as a proxy for the month in which the activity was created, as the activity table does not have a created_at timestamp.
-- 2. I only consider completed activities (is_done = true) for the activity-based funnel steps, as these are more indicative of actual progress in the sales funnel.

with activity as (
    select
        *
    from {{ ref('fct_activity') }}
),
deal_stage_history as (
    select
        *
    from {{ ref('fct_deal_stage_history') }}
),
w_agg_monthly_activity as (
    select
        date_trunc('month', a.due_at) as month, -- as a proxy for activity created month
        a.funnel_step_label           as funnel_step,
        a.funnel_step_order,
        a.activity_type_name          as kpi_name,
        count(distinct a.deal_id)     as deals_count
    from activity as a
    where a.due_at is not null -- Filter out activities without a due date, as they cannot be assigned to a specific month
        and a.funnel_step_label is not null -- Filter out activities that do not have a funnel step label, as they cannot be assigned to a specific funnel step
        and a.is_done = true -- Consider only completed activities, as they are more indicative of actual progress in the sales funnel
    group by
        date_trunc('month', a.due_at),
        a.funnel_step_label,
        a.funnel_step_order,
        a.activity_type_name
),
w_agg_monthly_stage as (
    select
        date_trunc('month', dsh.stage_started_at) as month,
        dsh.funnel_step_label                     as funnel_step,
        dsh.stage_id                              as funnel_step_order,
        dsh.stage_name                            as kpi_name,
        count(distinct dsh.deal_id)               as deals_count
    from deal_stage_history as dsh
    where dsh.stage_started_at is not null -- Filter out stage changes without a start date, as they cannot be assigned to a specific month
        and dsh.funnel_step_label is not null -- Filter out stages that do not have a funnel step label, as they cannot be assigned to a specific funnel step
    group by
        date_trunc('month', dsh.stage_started_at),
        dsh.funnel_step_label,
        dsh.stage_id,
        dsh.stage_name
),
w_combined as (
    select
        *
    from w_agg_monthly_activity
    union all
    select
        *
    from w_agg_monthly_stage
)
select
    month,
    kpi_name,
    funnel_step,
    deals_count
from w_combined
order by
    month desc,
    funnel_step_order
