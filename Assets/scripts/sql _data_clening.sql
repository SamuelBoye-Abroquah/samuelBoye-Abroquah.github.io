SELECT
    shipment_id,

    -- Clean origin warehouse
    TRIM(UPPER(origin_warehouse)) AS origin_warehouse,

    -- Clean destination city
    COALESCE(NULLIF(TRIM(destination_city), ''), TRIM(destination_state)) AS destination_city,

    -- Clean destination state
    COALESCE(NULLIF(UPPER(TRIM(destination_state)), ''), UPPER(TRIM(destination_city))) AS destination_state,

    -- Normalize carrier name: Capitalize first letter only
    CONCAT(
        UPPER(LEFT(TRIM(carrier), 1)),
        LOWER(SUBSTRING(TRIM(carrier), 2))
    ) AS carrier,

    -- Clean ship_date from multiple formats or fallback to (delivery - 2 days)
    COALESCE(
        STR_TO_DATE(ship_date, '%Y-%m-%d'),
        STR_TO_DATE(ship_date, '%m/%d/%Y'),
        STR_TO_DATE(ship_date, '%b %d %Y'),
        STR_TO_DATE(ship_date, '%M %d %Y'),
        DATE_SUB(delivery_date, INTERVAL 2 DAY)
    ) AS ship_date,

    -- Clean delivery_date from multiple formats
    COALESCE(
        STR_TO_DATE(delivery_date, '%Y-%m-%d'),
        STR_TO_DATE(delivery_date, '%m/%d/%Y'),
        STR_TO_DATE(delivery_date, '%b %d %Y'),
        STR_TO_DATE(delivery_date, '%M %d %Y')
    ) AS delivery_date_date,

    -- Weight as positive numeric
    ABS(weight_kg) AS weight_kg,

    -- Replace incorrect freight cost
    CASE
        WHEN freight_cost = 15000 THEN (
            SELECT round(AVG(freight_cost),0) 
            FROM dirty_shipments
            WHERE freight_cost <> 15000
        )
        ELSE freight_cost
    END AS freight_cost,

    -- Normalize shipment status
    CONCAT(
        UPPER(LEFT(TRIM(shipment_status), 1)),
        LOWER(SUBSTRING(TRIM(shipment_status), 2))
    ) AS shipment_status,

    items_count,

    -- Clean and infer damage report status
    CASE
        WHEN TRIM(damage_reported) IS NULL AND shipment_status LIKE '%transit%' THEN 'Not yet delivered'
        WHEN TRIM(damage_reported) IS NULL AND shipment_status LIKE '%delivered%' THEN 'Not reported'
        ELSE CONCAT(
                UPPER(LEFT(TRIM(damage_reported), 1)),
                LOWER(SUBSTRING(TRIM(damage_reported), 2))
             )
    END AS damage_reported

FROM dirty_shipments
WHERE items_count > 0;
