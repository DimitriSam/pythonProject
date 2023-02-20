{{ config(
    materialized='table',
    partition_by={
      "field": "transaction_created_at",
      "data_type": "timestamp",
      "granularity": "DAY"
    }
) }}

WITH card_in AS (SELECT
    t.id
    , a.user_id
    , a.id AS account_id
    , t.created_at AS transaction_created_at
    , t.currency
    , t.amount
    , CASE WHEN t.currency = 'GBP' THEN t.amount ELSE t.amount / ex.gbp_eur END AS amount_gbp_equivalent
    , CASE WHEN t.type = 'card_credit' THEN 'deposit_to_card_pocket' ELSE JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.card_transaction_type') END AS type_rs
    , t.status
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.merchant_name') AS merchant_name
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.merchant_category_code') AS merchant_category_code
    , m.merchant_type
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.transfer_leg_id') AS transfer_leg_id
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.chargeback_id') AS chargeback_id
    , ARRAY_TO_STRING(JSON_EXTRACT_ARRAY(t.extra_data, '$.failure_reasons'), '--') AS failure_reasons
    FROM {{ ref('stg_app_tables__transaction') }} AS t
    INNER JOIN {{ ref('stg_app_tables__account') }} AS a ON a.id = t.destination_id
    LEFT JOIN {{ ref('int_currency_exchange_rate_daily') }} AS ex ON ex.date = DATE(t.created_at)
    LEFT JOIN {{ ref('stg_google_sheets__mcc_codes') }} AS m
        ON m.mcc_codes = CAST(JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.merchant_category_code') AS INT64)
    WHERE t.type IN ('card_credit', 'card_pay_in')
)

, card_out AS (SELECT
    t.id
    , a.user_id
    , a.id AS account_id
    , t.created_at AS transaction_created_at
    , t.currency
    , t.amount
    , CASE WHEN t.currency = 'GBP' THEN t.amount ELSE t.amount / ex.gbp_eur END AS amount_gbp_equivalent
    , CASE WHEN t.type = 'card_payout' THEN JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.card_transaction_type') ELSE 'withdrawal_from_card_pocket' END AS type_rs
    , t.status
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.merchant_name') AS merchant_name
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.merchant_category_code') AS merchant_category_code
    , m.merchant_type
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.transfer_leg_id') AS transfer_leg_id
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.chargeback_id') AS chargeback_id
    , ARRAY_TO_STRING(JSON_EXTRACT_ARRAY(t.extra_data, '$.failure_reasons'), '--') AS failure_reasons
    FROM {{ ref('stg_app_tables__transaction') }} AS t
    INNER JOIN {{ ref('stg_app_tables__account') }} AS a ON a.id = t.source_id
    LEFT JOIN {{ ref('int_currency_exchange_rate_daily') }} AS ex ON ex.date = DATE(t.created_at)
    LEFT JOIN {{ ref('stg_google_sheets__mcc_codes') }} AS m
        ON m.mcc_codes = CAST(JSON_EXTRACT_SCALAR(t.extra_data, '$.railsbank.merchant_category_code') AS INT64)
    WHERE t.type IN ('card_debit', 'card_payout')
)

, card_chargeback AS (
    SELECT
        t.id
        , a.user_id
        , a.id AS account_id
        , t.created_at AS transaction_created_at
        , t.currency
        , t.amount
        , CASE WHEN t.currency = 'GBP' THEN t.amount ELSE t.amount / ex.gbp_eur END AS amount_gbp_equivalent
        , 'charge_back' AS type_rs
        , t.status
        , JSON_EXTRACT_SCALAR(t.extra_data, '$.merchant_name') AS merchant_name
        , JSON_EXTRACT_SCALAR(t.extra_data, '$.merchant_category_code') AS merchant_category_code
        , m.merchant_type
        , JSON_EXTRACT_SCALAR(t.extra_data, '$.transfer_leg_id') AS transfer_leg_id
        , JSON_EXTRACT_SCALAR(t.extra_data, '$.chargeback_id') AS chargeback_id
        , ARRAY_TO_STRING(JSON_EXTRACT_ARRAY(t.extra_data, '$.failure_reasons'), '--') AS failure_reasons
    FROM {{ ref('stg_app_tables__transaction') }} AS t
    INNER JOIN {{ ref('stg_app_tables__account') }} AS a ON a.id = t.source_id
    LEFT JOIN {{ ref('int_currency_exchange_rate_daily') }} AS ex ON ex.date = DATE(t.created_at)
    LEFT JOIN {{ ref('stg_google_sheets__mcc_codes') }} AS m
        ON m.mcc_codes = CAST(JSON_EXTRACT_SCALAR(t.extra_data, '$.merchant_category_code') AS INT64)
    WHERE t.type = 'card_chargeback'
)

, card_chargeback_reversal AS (SELECT
    t.id
    , a.user_id
    , a.id AS account_id
    , t.created_at AS transaction_created_at
    , t.currency
    , t.amount
    , CASE WHEN t.currency = 'GBP' THEN t.amount ELSE t.amount / ex.gbp_eur END AS amount_gbp_equivalent
    , 'charge_back_reversal' AS type_rs
    , t.status
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.merchant_name') AS merchant_name
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.merchant_category_code') AS merchant_category_code
    , m.merchant_type
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.transfer_leg_id') AS transfer_leg_id
    , JSON_EXTRACT_SCALAR(t.extra_data, '$.chargeback_id') AS chargeback_id
    , ARRAY_TO_STRING(JSON_EXTRACT_ARRAY(t.extra_data, '$.failure_reasons'), '--') AS failure_reasons
    FROM {{ ref('stg_app_tables__transaction') }} AS t
    INNER JOIN {{ ref('stg_app_tables__account') }} AS a ON a.id = t.source_id
    LEFT JOIN {{ ref('int_currency_exchange_rate_daily') }} AS ex ON ex.date = DATE(t.created_at)
    LEFT JOIN {{ ref('stg_google_sheets__mcc_codes') }} AS m
        ON m.mcc_codes = CAST(JSON_EXTRACT_SCALAR(t.extra_data, '$.merchant_category_code') AS INT64)
    WHERE t.type = 'card_chargeback_reversal'
        AND t.status = 'succeeded'
)

, card_transactions AS (SELECT
    *
    , 'card_in' AS transaction_side
    FROM card_in
    UNION ALL
    SELECT
        *
        , 'card_out' AS transaction_side
    FROM card_out
    UNION ALL
    SELECT
        *
        , 'card_chargeback' AS transaction_side
    FROM card_chargeback
    UNION ALL
    SELECT
        *
        , 'card_chargeback_reversal' AS transaction_side
    FROM card_chargeback_reversal
)

SELECT
    *
FROM card_transactions
