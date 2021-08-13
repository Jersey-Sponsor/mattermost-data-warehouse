{{config({
    "materialized": "incremental",
    "schema": "staging",
    "unique_key":'id'
  })
}}

WITH max_segment_timestamp        AS (
    SELECT
        timestamp::DATE AS date
      , user_id
      , MAX(timestamp)  AS max_timestamp
    FROM {{ source('mattermost2', 'config_message_export') }}
    WHERE timestamp::DATE <= CURRENT_DATE
    {% if is_incremental() %}

        -- this filter will only be applied on an incremental run
        AND timestamp::date >= (SELECT MAX(date) FROM {{ this }}) - INTERVAL '1 DAY'

    {% endif %}
    GROUP BY 1, 2
),

max_rudder_timestamp       AS (
    SELECT
        timestamp::DATE AS date
      , user_id
      , MAX(r.timestamp)  AS max_timestamp
    FROM {{ source('mm_telemetry_prod', 'config_message_export') }} r
    WHERE timestamp::DATE <= CURRENT_DATE
    {% if is_incremental() %}

        -- this filter will only be applied on an incremental run
        AND timestamp::date >= (SELECT MAX(date) FROM {{ this }}) - INTERVAL '1 DAY'

    {% endif %}
    GROUP BY 1, 2
),
     server_message_export_details AS (
         SELECT
             COALESCE(s.timestamp::DATE, r.timestamp::date)                        AS date
           , COALESCE(s.user_id, r.user_id)                                        AS server_id
           , MAX(COALESCE(s.batch_size, r.batch_size))                            AS batch_size
           , MAX(COALESCE(s.daily_run_time, r.daily_run_time))                        AS daily_run_time
           , MAX(COALESCE(s.enable_message_export, r.enable_message_export))                 AS enable_message_export
           , MAX(COALESCE(s.export_format, r.export_format))                         AS export_format
           , MAX(COALESCE(s.global_relay_customer_type, r.global_relay_customer_type))            AS global_relay_customer_type
           , MAX(COALESCE(s.is_default_global_relay_email_address, r.is_default_global_relay_email_address)) AS is_default_global_relay_email_address
           , MAX(COALESCE(s.is_default_global_relay_smtp_password, r.is_default_global_relay_smtp_password)) AS is_default_global_relay_smtp_password
           , MAX(COALESCE(s.is_default_global_relay_smtp_username, r.is_default_global_relay_smtp_username)) AS is_default_global_relay_smtp_username           
           , {{ dbt_utils.surrogate_key(['COALESCE(s.timestamp::DATE, r.timestamp::date)', 'COALESCE(s.user_id, r.user_id)']) }} AS id
           , COALESCE(r.CONTEXT_TRAITS_INSTALLATIONID, NULL)                   AS installation_id
           , MAX(COALESCE(r.download_export_results, NULL))        AS download_export_results
         FROM 
            (
              SELECT s.*
              FROM {{ source('mattermost2', 'config_message_export') }} s
              JOIN max_segment_timestamp        mt
                   ON s.user_id = mt.user_id
                       AND mt.max_timestamp = s.timestamp
            ) s
          FULL OUTER JOIN
            (
              SELECT r.*
              FROM {{ source('mm_telemetry_prod', 'config_message_export') }} r
              JOIN max_rudder_timestamp mt
                  ON r.user_id = mt.user_id
                    AND mt.max_timestamp = r.timestamp
            ) r
            ON s.timestamp::date = r.timestamp::date
            AND s.user_id = r.user_id
         GROUP BY 1, 2, 11, 12
     )
SELECT *
FROM server_message_export_details