{{config({
    "materialized": "incremental",
    "schema": "focalboard",
    "tags":"hourly",
    "unique_key":"id"
  })
}}

WITH max_time AS (
  SELECT 
    user_id
  , timestamp::date as date
  , MAX(received_at) AS max_time
  FROM {{ source('hacktoberboard_prod', 'config') }}
  WHERE received_at::DATE <= CURRENT_DATE
  GROUP BY 1, 2
), 

focalboard_config AS (
    SELECT 
        config.timestamp::date as logging_date
        , config.context_request_ip
        , config.timestamp
        , config.anonymous_id
        , config.port
        , config.sent_at
        , config.user_id
        , config.usessl
        , config.received_at
        , config.context_library_version
        , config.dbtype
        , config.serverroot
        , config.original_timestamp
        , config.context_ip
        , config.single_user
        , config.event
        , config.event_text
        , config.uuid_ts
      , {{ dbt_utils.surrogate_key(['config.timestamp::date', 'config.user_id'])}} as id
    FROM {{ source('hacktoberboard_prod', 'config') }} config
    JOIN max_time mt
      ON config.user_id = mt.user_id
      AND config.received_at = mt.max_time
    WHERE config.received_at::DATE <= CURRENT_DATE
    {% if is_incremental() %}
      and config.received_at >= (select max(received_at) from {{ this }})
    {% endif %}
)

SELECT *
FROM focalboard_config