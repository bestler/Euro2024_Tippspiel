create procedure createbetsforuser(IN userid uuid)
    language sql
BEGIN ATOMIC
 INSERT INTO bets (user_id, match_id, goals_home, goals_away, created_at, modified_at, points, id)  SELECT createbetsforuser.userid AS userid,
             matches.id,
             NULL::unknown,
             NULL::unknown,
             now() AS now,
             NULL::unknown,
             0,
             uuid_generate_v1() AS uuid_generate_v1
            FROM matches;
END;

alter procedure createbetsforuser(uuid) owner to admin;