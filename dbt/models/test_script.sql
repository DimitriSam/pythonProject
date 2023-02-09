{{ config(
    materialized='table',
    partition_by={
      "field": "time",
      "data_type": "timestamp",
      "granularity": "DAY"
    }
)}}

WITH
  get_started_events AS (
  SELECT
    DISTINCT distinct_id AS user_id,
    properties__os AS platform,
    up.country,
    CASE
      WHEN name IN ('get_started_tap') AND properties_page_name = 'home_screen' THEN 'get_started_first_tap'
      WHEN name IN ('get_started_screen')
    AND properties_page_name = 'actions_list' THEN 'get_started_actions_list'
    --Deposits--
      WHEN name IN ('get_started_tap') AND properties_page_name = 'actions_list' AND properties_button_name = 'first_deposit' THEN 'get_started_tap_on_first_deposit'
      WHEN name IN ('get_started_tap')
    AND properties_page_name = 'first_deposit_1' THEN 'get_started_first_deposit_start_screen'
      WHEN name IN ('get_started_tap') AND properties_page_name = 'first_deposit_1' AND properties_button_name = 'next' THEN 'get_started_tap_on_make_deposit'
    --Brain--
      WHEN name IN ('get_started_tap')
    AND properties_page_name = 'actions_list'
    AND properties_button_name = 'intro_brain' THEN 'get_started_tap_on_brain'
      WHEN name IN ('get_started_screen') AND properties_page_name = 'intro_brain_1' THEN 'get_started_brain_start_screen_1'
      WHEN name IN ('get_started_screen')
    AND properties_page_name = 'intro_brain_2' THEN 'get_started_brain_start_screen_2'
      WHEN name IN ('get_started_screen') AND properties_page_name = 'intro_brain_3' THEN 'get_started_brain_start_screen_3'
      WHEN name IN ('get_started_tap')
    AND properties_page_name = 'intro_brain_3'
    AND properties_button_name = 'next' THEN 'get_started_tap_on_activate_pay_day'
  END
    AS event_name,
    time
  FROM
     {{ ref('int_analytics_events') }} ae
  LEFT JOIN
    {{ ref('int_user_profile_users') }} up
  ON
    ae.distinct_id = up.id
  WHERE
    DATE(ae.time) >= '2023-02-04'

     {% if is_incremental() %}
     where DATE(time) >= CURRENT_DATE() - {{ var('DAYS_TO_SYNC_EVENTS') }}
     {% endif %}
    )
SELECT
  *
FROM
  get_started_events
WHERE
  event_name IS NOT NULL