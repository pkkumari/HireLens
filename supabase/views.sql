-- Analytics Views for HireLens
-- These views provide optimized queries for dashboard analytics

-- Funnel Analytics View
CREATE OR REPLACE VIEW funnel_analytics AS
SELECT 
    organization_id,
    to_stage AS stage,
    COUNT(DISTINCT candidate_id) AS candidate_count,
    COUNT(*) AS total_events,
    MIN(moved_at) AS first_entry,
    MAX(moved_at) AS last_entry
FROM candidate_stage_events
GROUP BY organization_id, to_stage;

-- Stage Conversion View
CREATE OR REPLACE VIEW stage_conversion AS
WITH stage_counts AS (
    SELECT 
        organization_id,
        to_stage AS stage,
        COUNT(DISTINCT candidate_id) AS entered_count
    FROM candidate_stage_events
    GROUP BY organization_id, to_stage
),
next_stage_counts AS (
    SELECT 
        e1.organization_id,
        e1.to_stage AS from_stage,
        e2.to_stage AS to_stage,
        COUNT(DISTINCT e1.candidate_id) AS converted_count
    FROM candidate_stage_events e1
    JOIN candidate_stage_events e2 
        ON e1.candidate_id = e2.candidate_id 
        AND e1.organization_id = e2.organization_id
        AND e2.moved_at > e1.moved_at
    WHERE NOT EXISTS (
        SELECT 1 FROM candidate_stage_events e3
        WHERE e3.candidate_id = e1.candidate_id
        AND e3.moved_at > e1.moved_at
        AND e3.moved_at < e2.moved_at
    )
    GROUP BY e1.organization_id, e1.to_stage, e2.to_stage
)
SELECT 
    sc.organization_id,
    sc.stage AS from_stage,
    nsc.to_stage,
    sc.entered_count,
    COALESCE(nsc.converted_count, 0) AS converted_count,
    CASE 
        WHEN sc.entered_count > 0 
        THEN ROUND((COALESCE(nsc.converted_count, 0)::NUMERIC / sc.entered_count::NUMERIC) * 100, 2)
        ELSE 0 
    END AS conversion_rate
FROM stage_counts sc
LEFT JOIN next_stage_counts nsc 
    ON sc.organization_id = nsc.organization_id 
    AND sc.stage = nsc.from_stage;

-- Drop-off Reasons View
CREATE OR REPLACE VIEW dropoff_reasons AS
SELECT 
    organization_id,
    to_stage AS stage,
    action_type,
    reason_code,
    COUNT(*) AS count,
    COUNT(DISTINCT candidate_id) AS candidate_count
FROM candidate_stage_events
WHERE action_type IN ('reject', 'withdraw')
GROUP BY organization_id, to_stage, action_type, reason_code;

-- Time in Stage View
CREATE OR REPLACE VIEW time_in_stage AS
WITH stage_durations AS (
    SELECT 
        e1.organization_id,
        e1.candidate_id,
        e1.to_stage AS stage,
        e1.moved_at AS entered_at,
        COALESCE(
            MIN(e2.moved_at),
            NOW()
        ) AS exited_at,
        EXTRACT(EPOCH FROM (COALESCE(MIN(e2.moved_at), NOW()) - e1.moved_at)) / 86400 AS days_in_stage
    FROM candidate_stage_events e1
    LEFT JOIN candidate_stage_events e2 
        ON e1.candidate_id = e2.candidate_id 
        AND e1.organization_id = e2.organization_id
        AND e2.moved_at > e1.moved_at
    GROUP BY e1.organization_id, e1.candidate_id, e1.to_stage, e1.moved_at
)
SELECT 
    organization_id,
    stage,
    COUNT(*) AS candidate_count,
    ROUND(AVG(days_in_stage)::NUMERIC, 2) AS avg_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_in_stage)::NUMERIC, 2) AS median_days,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_in_stage)::NUMERIC, 2) AS p90_days,
    ROUND(MIN(days_in_stage)::NUMERIC, 2) AS min_days,
    ROUND(MAX(days_in_stage)::NUMERIC, 2) AS max_days
FROM stage_durations
GROUP BY organization_id, stage;

-- Offer Analytics View
CREATE OR REPLACE VIEW offer_analytics AS
WITH offer_events AS (
    SELECT 
        organization_id,
        candidate_id,
        moved_at,
        action_type,
        reason_code
    FROM candidate_stage_events
    WHERE to_stage = 'Offer Extended'
),
acceptance_events AS (
    SELECT 
        organization_id,
        candidate_id,
        moved_at,
        action_type
    FROM candidate_stage_events
    WHERE to_stage = 'Offer Accepted'
)
SELECT 
    o.organization_id,
    COUNT(DISTINCT o.candidate_id) AS offers_extended,
    COUNT(DISTINCT a.candidate_id) AS offers_accepted,
    CASE 
        WHEN COUNT(DISTINCT o.candidate_id) > 0 
        THEN ROUND((COUNT(DISTINCT a.candidate_id)::NUMERIC / COUNT(DISTINCT o.candidate_id)::NUMERIC) * 100, 2)
        ELSE 0 
    END AS acceptance_rate,
    COUNT(DISTINCT CASE WHEN o.action_type = 'reject' THEN o.candidate_id END) AS offers_rejected,
    COUNT(DISTINCT CASE WHEN o.reason_code = 'Compensation mismatch' THEN o.candidate_id END) AS compensation_mismatch_count
FROM offer_events o
LEFT JOIN acceptance_events a 
    ON o.organization_id = a.organization_id 
    AND o.candidate_id = a.candidate_id
GROUP BY o.organization_id;

-- Source Performance View
CREATE OR REPLACE VIEW source_performance AS
SELECT 
    c.organization_id,
    c.source,
    COUNT(DISTINCT c.candidate_id) AS total_candidates,
    COUNT(DISTINCT CASE WHEN c.status = 'hired' THEN c.candidate_id END) AS hired_count,
    CASE 
        WHEN COUNT(DISTINCT c.candidate_id) > 0 
        THEN ROUND((COUNT(DISTINCT CASE WHEN c.status = 'hired' THEN c.candidate_id END)::NUMERIC / COUNT(DISTINCT c.candidate_id)::NUMERIC) * 100, 2)
        ELSE 0 
    END AS hire_rate,
    COUNT(DISTINCT CASE WHEN c.status = 'rejected' THEN c.candidate_id END) AS rejected_count,
    COUNT(DISTINCT CASE WHEN c.status = 'withdrawn' THEN c.candidate_id END) AS withdrawn_count
FROM candidates c
GROUP BY c.organization_id, c.source;

