{{config({
    "materialized": "incremental",
    "schema": "incident_collaboration",
    "tags":"hourly",
    "unique_key":"id",
    "warehouse":"ANALYST_XS"
  })
}}
 
WITH min_dates AS (
    SELECT
        COALESCE(user_id, anonymous_id)         AS server_id
      , COALESCE(plugin_version, pluginversion) AS plugin_version
      , MIN(timestamp)                    AS first_version_date
      , MAX(timestamp) AS last_active
    FROM {{ ref('incident_response_events') }}
    WHERE timestamp::DATE <= CURRENT_TIMESTAMP
    GROUP BY 1, 2
                      ),
  
  version_dates AS (
      SELECT server_id
           , plugin_version
           , first_version_date::date                       AS first_version_date
           , COALESCE(
                  LAG(first_version_date) OVER (PARTITION BY server_id ORDER BY first_version_date DESC) -
                  INTERVAL '1 day',
                  CURRENT_DATE)::date                             AS last_version_date
           , COALESCE(
                  LAG(first_version_date) OVER (PARTITION BY server_id ORDER BY first_version_date DESC) -
                  INTERVAL '1 day',
                  last_active)                             AS last_active
      FROM min_dates
     ),
     
  dates AS (
      SELECT
          d.date
        , vd.server_id
        , vd.plugin_version
        , vd.first_version_date
        , vd.last_version_date
      FROM {{ ref('dates') }} d 
      JOIN version_dates vd
        ON d.date >= vd.first_version_date
        AND d.date <= CURRENT_DATE
     ),

incident_daily_details AS (
    SELECT
        d.date
      , {{ dbt_utils.surrogate_key(['d.date',
                 'd.server_id', 'd.plugin_version'])}}                                                AS id
      , d.server_id
      , d.plugin_version
      , d.first_version_date
      , d.last_version_date
      , MIN(events.timestamp)                                                                         AS first_active
      , MAX(events.timestamp)                                                                         AS last_active
      , count(distinct COALESCE(events.playbook_id, events.playbookid))                               AS playbooks
      , COUNT(DISTINCT CASE WHEN event = 'playbook' and action = 'create' 
                            THEN events.id
                            ELSE NULL END)                                                            AS playbooks_created
      , COUNT(DISTINCT CASE WHEN event = 'playbook' and action = 'update' 
                            THEN events.id
                            ELSE NULL END)                                                            AS playbooks_edited
      , COUNT(DISTINCT CASE WHEN event = 'playbook' and action = 'deleted' 
                            THEN events.id
                            ELSE NULL END)                                                            AS playbooks_deleted
      , COUNT(DISTINCT CASE WHEN COALESCE(currentstatus, current_status) = 'Reported' 
                              THEN COALESCE(events.incident_id, events.incidentid) ELSE NULL END)     AS reported_incidents
      , COUNT(DISTINCT CASE WHEN COALESCE(currentstatus, current_status) = 'Active'  
                              THEN COALESCE(events.incident_id, events.incidentid) ELSE NULL END)     AS acknowledged_incidents
      , COUNT(DISTINCT CASE WHEN COALESCE(currentstatus, current_status) = 'Archived'  
                              THEN COALESCE(events.incident_id, events.incidentid) ELSE NULL END)     AS archived_incidents
      , COUNT(DISTINCT CASE WHEN COALESCE(currentstatus, current_status) = 'Resolved'  
                              THEN COALESCE(events.incident_id, events.incidentid) ELSE NULL END)     AS resolved_incidents
      , COUNT(DISTINCT COALESCE(events.useractualid, events.user_actual_id))                          AS incident_contributors
      , COUNT(DISTINCT CASE
                  WHEN event = 'incident' AND action = 'update_status' THEN events.id
                                                                       ELSE NULL END)                 AS status_updates
      , COUNT(DISTINCT CASE
                  WHEN event = 'incident' AND action = 'change_stage' THEN events.id
                                                                      ELSE NULL END)                  AS stages_changed
      , COUNT(DISTINCT CASE
                  WHEN event = 'incident' AND action = 'add_timeline_event_from_post' THEN events.id
                                                                                      ELSE NULL END)  AS timeline_events_added
      , COUNT(DISTINCT CASE
                  WHEN event = 'incident' AND action = 'change_commander' THEN events.id
                                                                          ELSE NULL END)              AS commanders_changed
      , COUNT(DISTINCT CASE WHEN event = 'frontend' AND action = 'timeline_tab_clicked' 
                  THEN events.id ELSE NULL END)                                                       AS timeline_tab_clicks
      , COUNT(DISTINCT CASE WHEN event = 'incident' AND action = 'end' THEN events.id ELSE NULL END)  AS ended_incident
      , COUNT(
                DISTINCT CASE WHEN event = 'incident' AND action = 'restart' 
                THEN events.id ELSE NULL END)                                                         AS restarted_incident
      , COUNT(DISTINCT CASE
                  WHEN event = 'tasks' AND action = 'publish_retrospective' THEN events.id
                                                                            ELSE NULL END)            AS retrospectives_published
      , COUNT(DISTINCT CASE
                  WHEN event = 'tasks' AND action = 'update_retrospective' THEN events.id
                                                                            ELSE NULL END)            AS retrospectives_updated
      , COUNT(DISTINCT CASE
                  WHEN event = 'tasks' AND action = 'set_assignee_for_task' THEN events.id
                                                                            ELSE NULL END)            AS task_assignees_set
      , COUNT(DISTINCT CASE
                  WHEN event = 'tasks' AND action = 'modify_task_state' THEN events.id
                                                                        ELSE NULL END)                AS task_states_modified
      , COUNT(DISTINCT CASE WHEN event = 'tasks' AND action = 'add_task' 
                THEN events.id ELSE NULL END)                                                         AS tasks_added
      , COUNT(DISTINCT CASE WHEN event = 'tasks' AND action = 'remove_task' 
                THEN events.id ELSE NULL END)                                                         AS tasks_removed
      , COUNT(DISTINCT CASE WHEN event = 'tasks' AND action = 'rename_task' 
              THEN events.id ELSE NULL END)                                                           AS tasks_renamed
      , COUNT(DISTINCT CASE
                  WHEN event = 'tasks' AND action = 'run_task_slash_command' THEN events.id
                                                                             ELSE NULL END)           AS task_slash_commands_run
      , COUNT(CASE WHEN event = 'tasks' AND action = 'move_task' THEN events.id ELSE NULL END)          AS tasks_moved
      , COUNT(DISTINCT COALESCE(events.user_actual_id, useractualid)) AS version_users_to_date
      , COUNT(DISTINCT CASE WHEN events.timestamp::date = d.date 
                        THEN COALESCE(events.user_actual_id, useractualid) ELSE NULL END)             AS daily_active_users
      , COUNT(DISTINCT CASE WHEN events.timestamp::date >= d.date - INTERVAL '7 DAYS' 
                  THEN COALESCE(events.user_actual_id, useractualid) ELSE NULL END)                   AS weekly_active_users
      , COUNT(DISTINCT CASE WHEN events.timestamp::date >= d.date - INTERVAL '30 DAYS' 
                  THEN COALESCE(events.user_actual_id, useractualid) ELSE NULL END)                   AS monthly_active_users
    FROM dates d
    JOIN {{ ref('incident_response_events') }} events
      ON d.server_id = COALESCE(events.user_id, events.anonymous_id)
      AND events.timestamp::date <= d.date
      AND COALESCE(events.plugin_version, events.pluginversion) = d.plugin_version
      AND events.timestamp::date >= d.first_version_date
    WHERE events.timestamp::DATE <= CURRENT_TIMESTAMP
    GROUP BY 1, 2, 3, 4, 5, 6
                         )

SELECT *
FROM incident_daily_details
{% if is_incremental() %}
WHERE date >= (SELECT MAX(date) FROM {{this}})
{% endif %}