{{ config(
    materialized='table',
    partition_by={
      "field": "transaction_created_at",
      "data_type": "timestamp",
      "granularity": "DAY"
    }
) }}


SELECT
    *
FROM card_transactions
WHERE s = 'test'
    {% if is_incremental() %}
        AND d >= CURRENT_DATE() - {{ var('DAYS_TO_SYNC_EVENTS') }}
    {% endif %}
