-- Explore the source data

-- 1. How many records are in the source table?
-- activity = 4579 rows
select count(*)
from postgres.public.activity;

-- activity_types = 4 rows
select count(*)
from postgres.public.activity_types;

-- deal_changes = 15406 rows
select count(*)
from postgres.public.deal_changes;

-- fields = 4 rows
select count(*)
from postgres.public.fields;

-- stages = 9 rows
select count(*)
from postgres.public.stages;

-- users = 1787 rows
select count(*)
from postgres.public.users;


-- 2. What are the column names and data types for each table?
-- activity
-- The sales representative's activity log
select column_name, data_type
from information_schema.columns
where table_name = 'activity';

-- activity_types
-- The types of activities, including Sales Call 1 and Sales Call 2 that we will use in analysis of step 2.1 and 3.1
select column_name, data_type
from information_schema.columns
where table_name = 'activity_types';

-- deal_changes
-- The changes made to deals with timestamps, including the stage changes that we will use in analysis for step 1 to 9
select column_name, data_type
from information_schema.columns
where table_name = 'deal_changes';

-- fields
-- The fields information with explanations of what they represent
select column_name, data_type
from information_schema.columns
where table_name = 'fields';

-- stages
-- The master data for the stages of the sales process, including the stage names that we will use in analysis for step 1 to 9
select column_name, data_type
from information_schema.columns
where table_name = 'stages';

-- users
-- The sales representatives' information
select column_name, data_type
from information_schema.columns
where table_name = 'users';

----------------------------------------------------------------
-- from above exploration, we can see that the key tables with historic data for our analysis are:
-- 1. activity: to analyze the sales reps' activities that mentioned in the project description for the Sales Call 1 and Sales Call 2
-- 2. deal_changes: to analyze the changes made to deals, especially the stage changes with timestamps
-- The other tables are more for reference and master data, such as the activity_types for the activity types, fields for the field explanations, stages for the stage names, and users for the sales reps' information.
----------------------------------------------------------------


-- 3. understand the data distribution and quality for the key tables
-- activity table:
-- check the distribution of activity types -- The most common activity type is After Close Call, followed by Sales Call 1. But the number of all types are in the same level (1.1k), which is good for our analysis.
select
    at.name as activity_type,
    count(activity_id) as count
from postgres.public.activity as a
join postgres.public.activity_types as at on a.type = at.type
group by at.name
order by count desc;

-- check if there are duplicated records for the same activity_id -- There are 11 duplicated records for the same activity_id, which is a data quality issue that we need to address in our analysis.
select
    a.activity_id,
    count(*)
from postgres.public.activity as a
group by 1
having count(*)>1;

-- check for missing values -- There is no missing value
select
    count(*) as total_records,
    count(a.activity_id) as activity_id_present,
    count(a.type) as type_present,
    count(a.assigned_to_user) as assigned_to_user_present,
    count(a.deal_id) as deal_id_present,
    count(distinct a.deal_id) as distinct_deal_id_present,
    count(a.done) as done_present,
    count(a.due_to) as due_to_present
from postgres.public.activity as a;


-- deal_changes table:
-- check the distribution of change fields -- The most common change field is stage_id (8.9k), which is the key field for our analysis. The other change fields are in much smaller number.
select
    dc.changed_field_key,
    count(*) as count
from postgres.public.deal_changes as dc
group by 1
order by count desc;

-- check if there are duplicated records for the same deal_id, changed_field_key, and new_value -- There are 17 duplicated records but different change_time that means the deal can change to the same stage/lost_reason multiple times.
select
    dc.deal_id,
    dc.changed_field_key,
    dc.new_value,
    -- dc.change_time,
    count(*)
from postgres.public.deal_changes as dc
group by 1, 2, 3  --, 4
having count(*)>1;


-- check the distribution of stage changes count for each deal -- The average stage changes count is 4.5, with a minimum of 1 and a maximum of 10, which means most deals have multiple stage changes.
select
    avg(stage_changes_count) as avg_stage_changes_count,
    min(stage_changes_count) as min_stage_changes_count,
    max(stage_changes_count) as max_stage_changes_count
from (
    select
        dc.deal_id,
        count(*) as stage_changes_count
    from postgres.public.deal_changes as dc
    where dc.changed_field_key = 'stage_id'
    group by 1
) as subquery;

-- check the distinct changed_field_key to see how many different change fields we have -- There are 4 different change fields
select distinct dc.changed_field_key
from postgres.public.deal_changes dc;

-- check how many deals have less than 4 changed fields, to check if there is any deal with no lost_reason -- There is no deal without lost_reason
select
    dc.deal_id,
	count(distinct dc.changed_field_key)
from postgres.public.deal_changes as dc
group by 1
having count(distinct dc.changed_field_key) < 4;

-- check the stage changes for each deal, and only keep the records where the stage changed backwards or re-entered -- There are 10 cases
select
    deal_id,
    stage_id,
    prev_stage_id
from (
    select
        dc.deal_id,
        dc.new_value::int as stage_id,
        dc.change_time,
        lag(dc.new_value::int) over (
            partition by dc.deal_id
            order by dc.change_time
        ) as prev_stage_id
    from postgres.public.deal_changes as dc
    where dc.changed_field_key = 'stage_id'
    order by dc.deal_id, dc.change_time
) as subquery
where stage_id <= prev_stage_id;

-- check for missing values -- There is no missing value
select
    count(*) as total_records,
    count(dc.deal_id) as deal_id_present,
    count(distinct dc.deal_id) as distinct_deal_id_present,
    count(dc.change_time) as change_time_present,
    count(dc.changed_field_key) as changed_field_key_present,
    count(dc.new_value) as new_value_present
from postgres.public.deal_changes as dc;


-- Between the two tables:
-- check deals link between activity and deal_changes
-- There are 4564 out of 4572 leads in activity that not exist in deal_changes.
select count(distinct a.deal_id) as total_deals_in_activity
from postgres.public.activity a
where not exists (
    select 1 from postgres.public.deal_changes dc
    where dc.deal_id = a.deal_id
);

-- There are 1987 out of 1995 deals in deal_changes that not exist in activity
select count(distinct dc.deal_id) as total_deals_in_dc
from postgres.public.deal_changes dc
where not exists (
    select 1 from postgres.public.activity a
    where a.deal_id = dc.deal_id
);


----------------------------------------------------------------
-- Summary of data distribution and quality:
-- 1. The activity table has a good distribution of activity types, with around 1.1k records for each type.
---- However, there are 11 duplicated records for the same activity_id.
-- 2. The deal_changes table has a good distribution of change fields, with stage_id being the most common change field.
---- There are 4 different change fields, and there is no deal without lost_reason. This means that all deals have a lost_reason, it doesn't make sense for real world scenarios.
---- The average stage changes count for each deal is 4.5, with a minimum of 1 and a maximum of 10, which means most deals have multiple stage changes.
---- There are 17 duplicated records for the same deal_id, changed_field_key, and new_value but different change_time, which means the deal can change to the same stage/lost_reason multiple times.
---- There are 10 cases where the stage changed backwards or re-entered.
-- 3. Between the two tables, there is a very small overlap of deals, with 4564 out of 4572 leads in activity that not exist in deal_changes,
---- and 1987 out of 1995 deals in deal_changes that not exist in activity. This could be a data quality issue or it could be that the two tables are capturing different sets of deals.
-- Overall, the data quality is good with no missing values, but there are some duplicated records and a very small overlap of deals between the two tables that we need to address in our analysis.
----------------------------------------------------------------
