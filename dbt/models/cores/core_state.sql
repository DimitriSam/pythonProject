SELECT
    *
FROM purchases
        {% if is_incremental() %} --noqa: L003
            AND d >= CURRENT_DATE() - 3
        {% endif %} --noqa: L003;
