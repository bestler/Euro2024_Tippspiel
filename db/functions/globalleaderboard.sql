-- Global Leaderboard
create function leaderboardforuser(userid uuid) returns table(id uuid, name text, total_points int, rank int, "row" int, isfriend boolean)
language sql as
$$
with combined as (SELECT *
                  FROM leaderboard l
                  WHERE l.row IN (SELECT l2.row
                                  FROM leaderboard l2
                                  WHERE l2.row <= 3
                                     or l2.id = userid
                                  UNION ALL
                                  SELECT MAX(l2.row)
                                  FROM leaderboard l2)
                  UNION ALL
                  SELECT *
                  FROM leaderboard l
                  WHERE id IN (SELECT f.friend_id
                               FROM friends f
                               WHERE user_id = userid))
SELECT distinct c.*, CASE WHEN f.id IS NULL THEN false else true END as isfriend
FROM combined c
         LEFT JOIN friends f ON f.friend_id = c.id and f.user_id = userid order by c.row
$$


-- Function to get the global leaderboard for a user (Refechting, after button click)

CREATE function refetchLeaderBoardForUser(userID uuid, numTopRows int, lowerBound int, upperBound int) returns table(id uuid, name text, total_points int, rank int, "row" int, isfriend boolean)
AS
$$
with combined as (SELECT l.id, l.name, l.total_points, l.rank, l.row
                   FROM leaderboard l
                   WHERE l.row IN (SELECT l2.row
                                   FROM leaderboard l2
                                   WHERE l2.row <= numTopRows
                                   UNION all
                                   SELECT l2.row
                                   FROM leaderboard l2
                                   WHERE l2.id = userID
                                   UNION ALL
                                   SELECT l2.row
                                   FROM leaderboard l2
                                   WHERE l2.row BETWEEN lowerBound AND upperBound
                                   UNION all
                                   SELECT MAX(l2.row)
                                   FROM leaderboard l2)
                   UNION ALL
                   SELECT *
                   FROM leaderboard l
                   WHERE id IN (SELECT f.friend_id
                                FROM friends f
                                WHERE user_id = userID)
                   )
SELECT distinct c.*, CASE WHEN f.id IS NULL THEN false else true END as isfriend
FROM combined c
         LEFT JOIN friends f ON f.friend_id = c.id and f.user_id = userid order by c.row
$$
    Language SQL;

