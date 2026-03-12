with activity_types as (
    select
        *
    from {{ ref('stg_activity_types') }}
),
w_added_column as (
    select
        activity_type_id,
        case when lower(activity_type) = 'meeting' then 'Step 2.1'
             when lower(activity_type) = 'sc_2' then 'Step 3.1'
             else null
        end as funnel_step_label, -- Add a new column for funnel step label based on activity_type, in real-world scenarios, we should consider using a more robust method to determine the funnel step label, such as a mapping table/seed file.
        case when lower(activity_type) = 'meeting' then 2.1
             when lower(activity_type) = 'sc_2' then 3.1
             else null
        end as funnel_step_order, -- Add a new column for funnel step order based on activity_type
        activity_type_name,
        is_active,
        activity_type
    from activity_types
)
select
    *
from w_added_column
