-- Generate random results for all bets

UPDATE bets
SET goals_home = random_between(0, 4), goals_away = random_between(0,4);

-- Update Points for all bets
CREATE PROCEDURE updateAllBets()

    language sql
BEGIN ATOMIC
 UPDATE bets b SET points =
         CASE
             WHEN ((m.team_away_goals = b.goals_away) AND (m.team_home_goals = b.goals_home)) THEN 8
             WHEN (((m.team_away_goals - m.team_home_goals) = (b.goals_away - b.goals_home)) AND (b.goals_home <> b.goals_away)) THEN 6
             WHEN ((((m.team_away_goals - m.team_home_goals) >= 0) AND ((b.goals_away - b.goals_home) >= 0)) OR (((m.team_away_goals - m.team_home_goals) <= 0) AND ((b.goals_away - b.goals_home) <= 0))) THEN 4
             ELSE 0
         END
    FROM matches m,
     users u
   WHERE ((m.id = b.match_id) AND (u.id = b.user_id));
END;

-- Preview 
SELECT *
FROM globalleaderboard
WHERE row IN (
    SELECT row FROM globalleaderboard WHERE row <= 3
    UNION all
    SELECT row FROM globalleaderboard WHERE id = userID
    UNION all
    SELECT row + 1 FROM globalleaderboard WHERE id = userID
    UNION all
    SELECT row - 1 FROM globalleaderboard WHERE id = userID
    UNION all
    SELECT MAX(row) FROM globalleaderboard
)
ORDER BY rank;


-- Put all existing users in a community
INSERT INTO user_community(user_id, community_id)
SELECT id, '87c9351e-87d1-4111-baac-7d1b1545217c' FROM users