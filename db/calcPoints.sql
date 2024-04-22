--Procudure to calculate the points for each bet and update the table "Bets"

UPDATE bets b
SET points = CASE WHEN --Korrektes Ergebnis
    m.team_away_goals = b.goals_away AND m.team_home_goals = b.goals_home
    THEN 8
    WHEN -- Richtige Tordifferenz
        (m.team_away_goals - m.team_home_goals) = (b.goals_away - b.goals_home) AND -- Richtige Differenz
        b.goals_home != b.goals_away -- kein Unentschieden
    THEN 6
    WHEN -- Richtige Tendenz
        (m.team_away_goals - m.team_home_goals) >= 0 AND (b.goals_away - b.goals_home) >= 0 OR
        (m.team_away_goals - m.team_home_goals) <= 0 AND (b.goals_away - b.goals_home) <= 0
    THEN 4
    ELSE 0
END
FROM matches m, benutzer u
WHERE m.id = b.match_id AND u.id = b.user_id;