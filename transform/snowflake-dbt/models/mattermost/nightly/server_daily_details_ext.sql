{{config({
    "materialized": 'incremental',
    "schema": "mattermost",
    "unique_key":'id'
  })
}}

{% if is_incremental() %}

WITH max_date AS (
  SELECT MAX(DATE) - interval '1 day' as max_date
  FROM {{ this }}
),

server_daily_details_ext AS (

{% else %}

WITH server_daily_details_ext AS (

{% endif %}
--
    SELECT
        s.date
      , s.server_id
      , s.ip_address
      , s.location
      , s.version
      , s.context_library_version
      , s.edition
      , s.active_user_count
      , s.user_count
      , s.system_admins
      , s.operating_system
      , s.database_type
      , s.account_sfid
      , s.license_id1
      , s.license_id2
      , s.in_security
      , s.in_mm2_server
      , s.tracking_disabled
      , s.has_dupes
      , s.has_multi_ips
      , s.timestamp
      , sc.active_users
      , sc.active_users_daily
      , sc.active_users_monthly
      , sc.bot_accounts
      , sc.bot_posts_previous_day
      , sc.direct_message_channels
      , sc.incoming_webhooks
      , sc.outgoing_webhooks
      , sc.posts
      , sc.posts_previous_day
      , sc.private_channels
      , sc.private_channels_deleted
      , sc.public_channels
      , sc.public_channels_deleted
      , sc.registered_deactivated_users
      , sc.registered_inactive_users
      , sc.registered_users
      , sc.slash_commands
      , sc.teams
      , sc.used_apiv3
      , sc.isdefault_max_users_for_statistics
      , sc.allow_banner_dismissal
      , sc.enable_banner
      , sc.isdefault_banner_color
      , sc.isdefault_banner_text_color
      , sc.allow_edit_post_client
      , sc.android_latest_version
      , sc.android_min_version
      , sc.desktop_latest_version
      , sc.desktop_min_version
      , sc.enable_apiv3_client
      , sc.enable_channel_viewed_messages_client
      , sc.enable_commands_client
      , sc.enable_custom_emoji_client
      , sc.enable_developer_client
      , sc.enable_emoji_picker_client
      , sc.enable_incoming_webhooks_client
      , sc.enable_insecure_outgoing_connections_client
      , sc.enable_multifactor_authentication_client
      , sc.enable_oauth_service_provider_client
      , sc.enable_only_admin_integrations_client
      , sc.ios_latest_version
      , sc.ios_min_version
      , sc.advertise_address
      , sc.bind_address
      , sc.enable_cluster
      , sc.network_interface
      , sc.read_only_config
      , sc.use_experimental_gossip
      , sc.use_ip_address
      , sc.enable_compliance
      , sc.enable_compliance_daily
      , sc.message_retention_days
      , sc.file_retention_days
      , sc.enable_message_deletion
      , sc.enable_file_deletion
      , sc.experimental_timezone
      , sc.isdefault_custom_url_schemes
      , sc.enable_autocomplete
      , sc.enable_indexing
      , sc.enable_searching
      , sc.isdefault_connection_url
      , sc.isdefault_index_prefix
      , sc.isdefault_password
      , sc.isdefault_username
      , sc.live_indexing_batch_size
      , sc.skip_tls_verification
      , sc.sniff
      , sc.trace_elasticsearch
      , sc.connection_security_email
      , sc.email_batching_buffer_size
      , sc.email_notification_contents_type
      , sc.enable_email_batching
      , sc.enable_preview_mode_banner
      , sc.enable_sign_in_with_email
      , sc.enable_sign_in_with_username
      , sc.enable_sign_up_with_email
      , sc.enable_smtp_auth
      , sc.isdefault_feedback_email
      , sc.isdefault_feedback_name
      , sc.isdefault_feedback_organization
      , sc.isdefault_login_button_border_color_email
      , sc.isdefault_login_button_color_email
      , sc.isdefault_login_button_text_color_email
      , sc.isdefault_reply_to_address
      , sc.push_notification_contents
      , sc.require_email_verification
      , sc.send_email_notifications
      , sc.send_push_notifications
      , sc.skip_server_certificate_verification
      , sc.use_channel_in_email_notifications
      , sc.client_side_cert_enable
      , sc.enable_click_to_reply
      , sc.enable_post_metadata
      , sc.isdefault_client_side_cert_check
      , sc.restrict_system_admin
      , sc.use_new_saml_library
      , sc.enable_experimental_extensions
      , sc.amazon_s3_signv2
      , sc.amazon_s3_sse
      , sc.amazon_s3_ssl
      , sc.amazon_s3_trace
      , sc.driver_name_file
      , sc.enable_file_attachments
      , sc.enable_mobile_download
      , sc.enable_mobile_upload
      , sc.enable_public_links
      , sc.isabsolute_directory
      , sc.isdefault_directory
      , sc.max_file_size
      , sc.preview_height
      , sc.preview_width
      , sc.profile_height
      , sc.profile_width
      , sc.thumbnail_height
      , sc.thumbnail_width
      , sc.allow_email_accounts
      , sc.enable_guest_accounts
      , sc.enforce_multifactor_authentication_guest
      , sc.isdefault_restrict_creation_to_domains
      , sc.enable_image_proxy
      , sc.image_proxy_type
      , sc.isdefault_remote_image_proxy_options
      , sc.isdefault_remote_image_proxy_url
      , sc.connection_security_ldap
      , sc.enable_ldap
      , sc.enable_admin_filter
      , sc.enable_sync
      , sc.isdefault_email_attribute_ldap
      , sc.isdefault_first_name_attribute_ldap
      , sc.isdefault_group_display_name_attribute
      , sc.isdefault_group_id_attribute
      , sc.isdefault_id_attribute_ldap
      , sc.isdefault_last_name_attribute_ldap
      , sc.isdefault_login_button_border_color_ldap
      , sc.isdefault_login_button_color_ldap
      , sc.isdefault_login_button_text_color_ldap
      , sc.isdefault_login_field_name
      , sc.isdefault_login_id_attribute
      , sc.isdefault_nickname_attribute_ldap
      , sc.isdefault_position_attribute_ldap
      , sc.isdefault_username_attribute_ldap
      , sc.isempty_admin_filter
      , sc.isempty_group_filter
      , sc.isempty_guest_filter
      , sc.max_page_size
      , sc.query_timeout_ldap
      , sc.segment_dedupe_id_ldap
      , sc.skip_certificate_verification
      , sc.sync_interval_minutes
      , sc.license_id
      , sc.start_date
      , sc.edition AS license_edition
      , sc.expire_date
      , sc.feature_cluster
      , sc.feature_compliance
      , sc.feature_custom_brand
      , sc.feature_custom_permissions_schemes
      , sc.feature_data_retention
      , sc.feature_elastic_search
      , sc.feature_email_notification_contents
      , sc.feature_future
      , sc.feature_google
      , sc.feature_guest_accounts
      , sc.feature_guest_accounts_permissions
      , sc.feature_id_loaded
      , sc.feature_ldap
      , sc.feature_ldap_groups
      , sc.feature_lock_teammate_name_display
      , sc.feature_message_export
      , sc.feature_metrics
      , sc.feature_mfa
      , sc.feature_mhpns
      , sc.feature_office365
      , sc.feature_password
      , sc.feature_saml
      , sc.issued_date
      , sc.users
      , sc.available_locales
      , sc.default_client_locale
      , sc.default_server_locale
      , sc.console_json_log
      , sc.console_level_log
      , sc.enable_console_log
      , sc.enable_file_log
      , sc.enable_webhook_debugging
      , sc.file_json_log
      , sc.file_level_log
      , sc.isdefault_file_format
      , sc.isdefault_file_location_log
      , sc.batch_size
      , sc.daily_run_time
      , sc.enable_message_export
      , sc.export_format
      , sc.global_relay_customer_type
      , sc.is_default_global_relay_email_address
      , sc.is_default_global_relay_smtp_password
      , sc.is_default_global_relay_smtp_username
      , sc.block_profile_rate
      , sc.enable_metrics
      , sc.isdefault_android_app_download_link
      , sc.isdefault_app_download_link
      , sc.isdefault_iosapp_download_link
      , sc.console_json_notifications
      , sc.console_level_notifications
      , sc.enable_console_notifications
      , sc.enable_file_notifications
      , sc.file_json_notifications
      , sc.file_level_notifications
      , sc.isdefault_file_location_notifications
      , sc.enable_office365_oauth
      , sc.enable_google_oauth
      , sc.enable_gitlab_oauth
      , sc.enable_lowercase
      , sc.enable_uppercase
      , sc.enable_symbol
      , sc.enable_number
      , sc.password_minimum_length
      , sc.phase_1_migration_complete
      , sc.phase_2_migration_complete
      , sc.channel_admin_permissions
      , sc.channel_guest_permissions
      , sc.channel_user_permissions
      , sc.system_admin_permissions
      , sc.system_user_permissions
      , sc.team_admin_permissions
      , sc.team_guest_permissions
      , sc.team_user_permissions
      , sc.allow_insecure_download_url
      , sc.automatic_prepackaged_plugins
      , sc.enable_plugins
      , sc.enable_antivirus
      , sc.enable_autolink
      , sc.enable_aws_sns
      , sc.enable_custom_user_attributes
      , sc.enable_github
      , sc.enable_gitlab
      , sc.enable_health_check
      , sc.enable_jenkins
      , sc.enable_jira
      , sc.enable_marketplace
      , sc.enable_nps
      , sc.enable_nps_survey
      , sc.enable_remote_marketplace
      , sc.enable_uploads
      , sc.enable_webex
      , sc.enable_welcome_bot
      , sc.enable_zoom
      , sc.is_default_marketplace_url
      , sc.require_plugin_signature
      , sc.signature_public_key_files
      , sc.version_antivirus
      , sc.version_autolink
      , sc.version_aws_sns
      , sc.version_custom_user_attributes
      , sc.version_github
      , sc.version_gitlab
      , sc.version_jenkins
      , sc.version_jira
      , sc.version_nps
      , sc.version_webex
      , sc.version_welcome_bot
      , sc.version_zoom
      , sc.active_backend_plugins
      , sc.active_plugins
      , sc.active_webapp_plugins
      , sc.disabled_backend_plugins
      , sc.disabled_plugins
      , sc.disabled_webapp_plugins
      , sc.enabled_backend_plugins
      , sc.enabled_plugins
      , sc.enabled_webapp_plugins
      , sc.inactive_backend_plugins
      , sc.inactive_plugins
      , sc.inactive_webapp_plugins
      , sc.plugins_with_broken_manifests
      , sc.plugins_with_settings
      , sc.show_email_address
      , sc.show_full_name
      , sc.enable_rate_limiter
      , sc.isdefault_vary_by_header
      , sc.max_burst
      , sc.memory_store_size
      , sc.per_sec
      , sc.vary_by_remote_address
      , sc.vary_by_user
      , sc.enable_saml
      , sc.enable_admin_attribute
      , sc.enable_sync_with_ldap
      , sc.enable_sync_with_ldap_include_auth
      , sc.encrypt_saml
      , sc.isdefault_admin_attribute
      , sc.isdefault_canonical_algorithm
      , sc.isdefault_email_attribute_saml
      , sc.isdefault_first_name_attribute_saml
      , sc.isdefault_guest_attribute
      , sc.isdefault_id_attribute_saml
      , sc.isdefault_last_name_attribute_saml
      , sc.isdefault_locale_attribute
      , sc.isdefault_login_button_border_color_saml
      , sc.isdefault_login_button_color_saml
      , sc.isdefault_login_button_text
      , sc.isdefault_login_button_text_color_saml
      , sc.isdefault_nickname_attribute_saml
      , sc.isdefault_position_attribute_saml
      , sc.isdefault_scoping_idp_name
      , sc.isdefault_scoping_idp_provider_id
      , sc.isdefault_signature_algorithm
      , sc.isdefault_username_attribute_saml
      , sc.sign_request
      , sc.verify_saml
      , sc.allow_cookies_for_subdomains
      , sc.allow_edit_post_service
      , sc.close_unused_direct_messages
      , sc.connection_security_service
      , sc.cors_allow_credentials
      , sc.cors_debug
      , sc.custom_service_terms_enabled_service
      , sc.disable_bots_when_owner_is_deactivated
      , sc.disable_legacy_mfa
      , sc.enable_apiv3_service
      , sc.enable_api_team_deletion
      , sc.enable_bot_account_creation
      , sc.enable_channel_viewed_messages_service
      , sc.enable_commands_service
      , sc.enable_custom_emoji_service
      , sc.enable_developer_service
      , sc.enable_email_invitations
      , sc.enable_emoji_picker_service
      , sc.enable_gif_picker
      , sc.enable_incoming_webhooks_service
      , sc.enable_insecure_outgoing_connections_service
      , sc.enable_latex
      , sc.enable_multifactor_authentication_service
      , sc.enable_oauth_service_provider_service
      , sc.enable_only_admin_integrations_service
      , sc.enable_outgoing_webhooks
      , sc.enable_post_icon_override
      , sc.enable_post_search
      , sc.enable_post_username_override
      , sc.enable_preview_features
      , sc.enable_security_fix_alert
      , sc.enable_svgs
      , sc.enable_testing
      , sc.enable_tutorial
      , sc.enable_user_access_tokens
      , sc.enable_user_statuses
      , sc.enable_user_typing_messages
      , sc.enforce_multifactor_authentication_service
      , sc.experimental_channel_organization
      , sc.experimental_enable_authentication_transfer
      , sc.experimental_enable_default_channel_leave_join_messages
      , sc.experimental_enable_hardened_mode
      , sc.experimental_group_unread_channels
      , sc.experimental_ldap_group_sync
      , sc.experimental_limit_client_config
      , sc.experimental_strict_csrf_enforcement
      , sc.forward_80_to_443
      , sc.gfycat_api_key
      , sc.gfycat_api_secret
      , sc.isdefault_allowed_untrusted_internal_connections
      , sc.isdefault_allowed_untrusted_inteznal_connections
      , sc.isdefault_allow_cors_from
      , sc.isdefault_cors_exposed_headers
      , sc.isdefault_google_developer_key
      , sc.isdefault_image_proxy_options
      , sc.isdefault_image_proxy_type
      , sc.isdefault_image_proxy_url
      , sc.isdefault_read_timeout
      , sc.isdefault_site_url
      , sc.isdefault_tls_cert_file
      , sc.isdefault_tls_key_file
      , sc.isdefault_write_timeout
      , sc.maximum_login_attempts
      , sc.minimum_hashtag_length
      , sc.post_edit_time_limit
      , sc.restrict_custom_emoji_creation
      , sc.restrict_post_delete
      , sc.session_cache_in_minutes
      , sc.session_idle_timeout_in_minutes
      , sc.session_length_mobile_in_days
      , sc.session_length_sso_in_days
      , sc.session_length_web_in_days
      , sc.tls_strict_transport
      , sc.uses_letsencrypt
      , sc.websocket_url
      , sc.web_server_mode
      , sc.driver_name_sql
      , sc.enable_public_channels_materialization
      , sc.max_idle_conns
      , sc.max_open_conns
      , sc.query_timeout_sql
      , sc.trace_sql
      , sc.custom_service_terms_enabled_support
      , sc.custom_terms_of_service_enabled
      , sc.custom_terms_of_service_re_acceptance_period
      , sc.isdefault_about_link
      , sc.isdefault_help_link
      , sc.isdefault_privacy_policy_link
      , sc.isdefault_report_a_problem_link
      , sc.isdefault_support_email
      , sc.isdefault_terms_of_service_link
      , sc.segment_dedupe_id_support
      , sc.enable_confirm_notifications_to_channel
      , sc.enable_custom_brand
      , sc.enable_open_server
      , sc.enable_team_creation
      , sc.enable_user_creation
      , sc.enable_user_deactivation
      , sc.enable_x_to_leave_channels_from_lhs
      , sc.experimental_default_channels
      , sc.experimental_enable_automatic_replies
      , sc.experimental_primary_team
      , sc.experimental_town_square_is_hidden_in_lhs
      , sc.experimental_town_square_is_read_only
      , sc.experimental_view_archived_channels
      , sc.isdefault_custom_brand_text
      , sc.isdefault_custom_description_text
      , sc.isdefault_site_name
      , sc.isdefault_user_status_away_timeout
      , sc.lock_teammate_name_display
      , sc.max_channels_per_team
      , sc.max_notifications_per_channel
      , sc.max_users_per_team
      , sc.restrict_direct_message
      , sc.restrict_private_channel_creation
      , sc.restrict_private_channel_deletion
      , sc.restrict_private_channel_management
      , sc.restrict_private_channel_manage_members
      , sc.restrict_public_channel_creation
      , sc.restrict_public_channel_deletion
      , sc.restrict_public_channel_management
      , sc.restrict_team_invite
      , sc.teammate_name_display
      , sc.view_archived_channels
      , sc.allowed_themes
      , sc.allow_custom_themes
      , sc.enable_theme_selection
      , sc.isdefault_default_theme
      , sc.isdefault_supported_timezones_path
      , sc.enable
      , sc.isdefault_stun_uri
      , sc.isdefault_turn_uri
      , {{ dbt_utils.surrogate_key(['s.date', 's.server_id']) }} as id
      , sc.data_source_replicas
      , sc.data_source_search_replicas
      , sc.enable_confluence
      , sc.enable_jitsi
      , sc.enable_mscalendar
      , sc.enable_todo
      , sc.enable_skype4business
      , sc.enable_giphy
      , sc.enable_digital_ocean
      , sc.enable_incident_response
      , sc.enable_memes
      , sc.version_giphy
      , sc.version_digital_ocean
      , sc.version_confluence
      , sc.version_mscalendar
      , sc.version_incident_response
      , sc.version_todo
      , sc.version_memes
      , sc.enable_ask_community_link
      , sc.guest_accounts
      , sc.enable_experimental_gossip_encryption
      , sc.version_jitsi
      , sc.version_skype4business
      , sc.file_compress_audit
      , sc.file_enabled_audit
      , sc.file_max_age_days_audit
      , sc.file_max_backups_audit
      , sc.file_max_queue_size_audit
      , sc.file_max_size_mb_audit
      , sc.syslog_enabled_audit
      , sc.syslog_insecure_audit
      , sc.syslog_max_queue_size_audit
      , sc.bulk_indexing_time_window_bleve
      , sc.enable_autocomplete_bleve
      , sc.enable_indexing_bleve
      , sc.enable_searching_bleve
      , sc.warn_metric_number_of_active_users_200
      , sc.warn_metric_number_of_active_users_400
      , sc.warn_metric_number_of_active_users_500
      , sc.advanced_logging_config_audit
      , sc.cloud_billing
      , sc.advanced_logging_config_notifications
      , sc.feature_advanced_logging
      , sc.feature_cloud
      , sc.channel_scheme_count
      , sc.create_post_guest_disabled_count
      , sc.create_post_user_disabled_count
      , sc.manage_members_user_disabled_count
      , sc.post_reactions_guest_disabled_count
      , sc.post_reactions_user_disabled_count
      , sc.use_channel_mentions_guest_disabled_count
      , sc.use_channel_mentions_user_disabled_count
      , sc.experimental_channel_sidebar_organization
      , sc.experimental_data_prefetch
      , sc.extend_session_length_with_activity
      , sc.system_user_manager_permissions_modified
      , sc.system_user_manager_permissions
      , sc.system_user_manager_count
      , sc.system_read_only_admin_permissions_modified
      , sc.system_read_only_admin_permissions
      , sc.system_read_only_admin_count
      , sc.system_manager_permissions_modified
      , sc.system_manager_permissions
      , sc.system_manager_count
      , sc.enable_api_channel_deletion
      , sc.enable_api_user_deletion
      , sc.isnotempty_private_key
      , sc.isnotempty_public_certificate
      , sc.enable_shared_channels
      , sc.cloud_user_limit
      , sc.warn_metric_email_domain
      , sc.warn_metric_mfa
      , sc.warn_metric_number_of_teams_5
      , sc.enable_mattermostprofanityfilter
      , sc.version_mattermostprofanityfilter
      , sc.warn_metric_number_of_active_users_100
      , sc.warn_metric_number_of_active_users_300
      , sc.warn_metric_number_of_channels_50
      , sc.warn_metric_number_of_posts_2m
      , sc.admin_notices_enabled
      , sc.user_notices_enabled
      , sc.download_export_results
      , sc.enable_comgithubmatterpollmatterpoll
      , sc.version_comgithubmatterpollmatterpoll
      , sc.enable_commattermostpluginincidentmanagement
      , sc.version_commattermostpluginincidentmanagement
      , sc.enable_comgithubjespinorecommend
      , sc.version_comgithubjespinorecommend
      , sc.enable_commattermostagenda
      , sc.version_commattermostagenda
      , sc.enable_commattermostmsteamsmeetings
      , sc.enable_commattermostpluginchannelexport
      , sc.enable_comnilsbrinkmannicebreaker
      , sc.version_commattermostmsteamsmeetings
      , sc.version_commattermostpluginchannelexport
      , sc.version_comnilsbrinkmannicebreaker
      , sc.enable_remote_cluster
      , sc.extract_content
      , sc.archive_recursion
      , sc.isdefault_app_custom_url_schemes
      , sc.version_mattermost_apps
      , sc. enable_mattermost_apps
      , sc.version_circleci
      , sc.enable_circleci
      , sc.version_diceroller
      , sc.enable_diceroller
      , sc.enable_link_previews
      , sc.restrict_link_previews
      , sc.enable_file_search
      , sc.thread_autofollow
      , sc.enable_custom_user_statuses
      , sc.export_retention_days
      , sc.group_team_count
      , sc.group_member_count
      , sc.group_channel_count
      , sc.distinct_group_member_count
      , sc.group_synced_team_count
      , sc.group_count
      , sc.group_synced_channel_count
      , sc.group_count_with_allow_reference
      , sc.enable_legacy_sidebar
      , sc.managed_resource_paths
      , sc.openid_google
      , sc.openid_gitlab
      , sc.openid_office365
      , sc.enable_openid
      , sc.enable_gossip_compression
      , sc.ignore_guests_ldap_sync
      , sc.conn_max_idletime_milliseconds
      , sc.collapsed_threads
    FROM {{ ref('server_daily_details') }}         s
    {% if is_incremental() %}
    JOIN max_date
         ON s.date >= max_date.max_date
    {% endif %}
         LEFT JOIN {{ ref('server_config_details') }} sc
                   ON s.server_id = sc.server_id
                       AND s.date = sc.date
    WHERE s.date >= '2016-04-01'
    {{ dbt_utils.group_by(n=595) }}
)

SELECT *
FROM server_daily_details_ext