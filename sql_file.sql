select *, PARSE_DATE('%Y%m%d',_TABLE_SUFFIX) as d
from {{ source('snapshots', 'chargeback_and_late_failure_prediction_output_*') }}

