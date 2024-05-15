-- Function to enforce the constraint that a user cannot be part of more than 5 communities
CREATE OR REPLACE FUNCTION enforce_max_communities()
RETURNS TRIGGER AS $$
BEGIN
    -- Count the number of communities the user is in
    IF (SELECT COUNT(*) FROM user_community WHERE user_id = NEW.user_id) >= 5 THEN
        RAISE EXCEPTION 'A user cannot be part of more than 5 communities';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce the constraint that a user cannot be part of more than 5 communities
CREATE TRIGGER check_max_communities
BEFORE INSERT OR UPDATE ON user_community
FOR EACH ROW
EXECUTE FUNCTION enforce_max_communities();
