-- Database function to optimize dashboard party fetching
-- This replaces the need to fetch full attendee details for dashboard

-- Drop the existing function first to change the return type
DROP FUNCTION IF EXISTS get_party_attendee_counts(uuid[],uuid);

CREATE OR REPLACE FUNCTION get_party_attendee_counts(
    party_ids UUID[],
    current_user_id UUID
)
RETURNS TABLE (
    party_id UUID,
    attendee_count BIGINT,
    current_user_status TEXT,
    current_user_role TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.party_id,
        COUNT(pm.id) as attendee_count,
        MAX(CASE 
            WHEN pm.user_id = current_user_id THEN pm.status::TEXT 
            ELSE NULL 
        END) as current_user_status,
        MAX(CASE 
            WHEN pm.user_id = current_user_id THEN pm.role::TEXT 
            ELSE NULL 
        END) as current_user_role
    FROM party_members pm
    WHERE pm.party_id = ANY(party_ids)
    GROUP BY pm.party_id;
END;
$$ LANGUAGE plpgsql;

-- Alternative approach using a view (if you prefer views over functions)
CREATE OR REPLACE VIEW party_attendee_summary AS
SELECT 
    p.id as party_id,
    p.name,
    p.description,
    p.start_date,
    p.end_date,
    p.cover_image_url,
    p.theme_id,
    p.party_type,
    p.party_vibe_tags,
    COUNT(pm.id) as attendee_count,
    c.id as city_id,
    c.city,
    c.state_or_province,
    c.country,
    c.timezone
FROM parties p
LEFT JOIN party_members pm ON p.id = pm.party_id
LEFT JOIN cities c ON p.city_id = c.id
GROUP BY p.id, p.name, p.description, p.start_date, p.end_date, 
         p.cover_image_url, p.theme_id, p.party_type, p.party_vibe_tags,
         c.id, c.city, c.state_or_province, c.country, c.timezone;

-- Usage example for the function:
-- SELECT * FROM get_party_attendee_counts(
--     ARRAY['uuid1', 'uuid2', 'uuid3']::UUID[],
--     'current-user-uuid'::UUID
-- );
