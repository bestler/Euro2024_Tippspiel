--Procudure to calculate the points for each bet and update the table "Bets"

CREATE PROCEDURE updateallbets()
    LANGUAGE sql
    BEGIN ATOMIC
 UPDATE public.bets b SET points =
         CASE
             WHEN ((m.team_away_goals = b.goals_away) AND (m.team_home_goals = b.goals_home)) THEN 8
             WHEN (((m.team_away_goals - m.team_home_goals) = (b.goals_away - b.goals_home)) AND (b.goals_home <> b.goals_away)) THEN 6
             WHEN ((((m.team_away_goals - m.team_home_goals) > 0) AND ((b.goals_away - b.goals_home) > 0)) OR (((m.team_away_goals - m.team_home_goals) < 0) AND ((b.goals_away - b.goals_home) < 0))) THEN 4
             WHEN (((m.team_away_goals - m.team_home_goals) = 0) AND ((b.goals_away - b.goals_home) = 0)) THEN 4
             ELSE 0
         END
    FROM public.matches m,
     public.users u
   WHERE ((m.id = b.match_id) AND (u.id = b.user_id));
END;

CREATE PROCEDURE updatepointsbets(IN for_match_id uuid)
    LANGUAGE sql
    BEGIN ATOMIC
 UPDATE public.bets b SET points =
         CASE
             WHEN ((m.team_away_goals = b.goals_away) AND (m.team_home_goals = b.goals_home)) THEN 8
             WHEN (((m.team_away_goals - m.team_home_goals) = (b.goals_away - b.goals_home)) AND (b.goals_home <> b.goals_away)) THEN 6
             WHEN ((((m.team_away_goals - m.team_home_goals) > 0) AND ((b.goals_away - b.goals_home) > 0)) OR (((m.team_away_goals - m.team_home_goals) < 0) AND ((b.goals_away - b.goals_home) < 0))) THEN 4
             WHEN (((m.team_away_goals - m.team_home_goals) = 0) AND ((b.goals_away - b.goals_home) = 0)) THEN 4
             ELSE 0
         END
    FROM public.matches m,
     public.users u
   WHERE ((m.id = b.match_id) AND (u.id = b.user_id) AND (m.id = updatepointsbets.for_match_id));
END;