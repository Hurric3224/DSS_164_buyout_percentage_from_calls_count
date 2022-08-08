SELECT
    --orders_and_calls_table.lifetime AS days_before_approve,
    orders_and_calls_table.calls_count_between_new_and_approved AS call_attempt,
    COUNT(CASE WHEN is_buyout = 1 THEN orders_and_calls_table.order_id END)/COUNT(CASE WHEN status_group = 'approved' THEN orders_and_calls_table.order_id END)*100 AS buyout_percentage,
    COUNT(DISTINCT orders_and_calls_table.order_id) AS lead_qty,
    SUM(orders_and_calls_table.call_duration_sec) AS call_duration_sec
FROM umberto_report_power_bi AS stat
INNER JOIN
    (
    SELECT erp_order_id     AS order_id,
        SUM(total_count) AS calls_count_between_new_and_approved,
        new_final_table.lifetime,
        SUM(billsec_sum) AS call_duration_sec
    FROM calls_by_day_count
    INNER JOIN
        (
        SELECT
           final_table.order_id  AS order_id,
           final_date - new_date AS lifetime,
           new_date,
           final_date,
           new_status,
           final_status

        FROM
            (
            SELECT
                DISTINCT order_id,
                TO_TIMESTAMP(created_at)::DATE AS final_date,
                "new" AS final_status
            FROM erp_order_log_status
            WHERE
                "new" = 6
                AND TO_TIMESTAMP(created_at)::DATE BETWEEN '2022-01-01' AND '2022-08-01'
            ) AS final_table
            INNER JOIN
                (
                SELECT
                    DISTINCT order_id,
                    TO_TIMESTAMP(created_at)::DATE AS new_date,
                    "new"                          AS new_status
                FROM erp_order_log_status
                WHERE
                    "new" IN (1, 2, 3, 30)
                    AND TO_TIMESTAMP(created_at)::DATE BETWEEN '2022-01-01' AND '2022-08-01'
                ) AS new_table
                    ON final_table.order_id = new_table.order_id
        ) AS new_final_table
            ON calls_by_day_count.erp_order_id = new_final_table.order_id
    WHERE day BETWEEN new_final_table.new_date AND new_final_table.final_date
    GROUP BY erp_order_id, new_final_table.lifetime
    ) AS orders_and_calls_table
        ON stat.order_id = orders_and_calls_table.order_id
GROUP BY
    --orders_and_calls_table.lifetime,
    orders_and_calls_table.calls_count_between_new_and_approved
HAVING
    COUNT(CASE WHEN status_group = 'approved' THEN orders_and_calls_table.order_id END) > 0
    --AND orders_and_calls_table.lifetime <= 14
    AND orders_and_calls_table.calls_count_between_new_and_approved <= 20
ORDER BY
    --orders_and_calls_table.lifetime,
    orders_and_calls_table.calls_count_between_new_and_approved