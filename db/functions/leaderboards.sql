-- Points per user: View
create view points_per_user(id, name, total_points) as
SELECT u. id,
       u. name,
       COALESCE(sum(b. points), 0) AS total_points
FROM benutzer u
         LEFT JOIN bets b ON u. id = b. user_id
GROUP BY u. id, u. name;


--Global Leaderboard
SELECT * , rank() over (ORDER BY p.total_points DESC) as place FROM points_per_user p;

