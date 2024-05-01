-- Global Leaderboard
CREATE VIEW globalleaderboard AS
            (
             SELECT *, rank() over (order by total_points desc)
as rank FROM points_per_user
);

-- Function to get the global leaderboard for a user (Default)
CREATE function defaultGlobalLeaderBoardForUser(userID uuid) returns setof globalleaderboard
AS $$
SELECT g.id, g.name, g.total_points, g.rank, g.row
FROM globalleaderboard g
WHERE g.row IN (
    SELECT g2.row FROM globalleaderboard g2 WHERE g2.row <= 3
    UNION all
    SELECT g2.row FROM globalleaderboard g2 WHERE g2.id = userID
    UNION all
    SELECT MAX(g2.row) FROM globalleaderboard g2
)
ORDER BY g.rank
    $$
Language SQL;


-- Function to get the global leaderboard for a user (Refechting, after button click)

CREATE function refetchGlobalLeaderBoardForUser(userID uuid, numTopRows int, lowerBound int, upperBound int) returns setof globalleaderboard
AS $$
SELECT g.id, g.name, g.total_points, g.rank, g.row
FROM globalleaderboard g
WHERE g.row IN (
    SELECT g2.row FROM globalleaderboard g2 WHERE g2.row <= numTopRows
    UNION all
    SELECT g2.row FROM globalleaderboard g2 WHERE g2.id = userID
    UNION ALL
    SELECT g2.row FROM globalleaderboard g2 WHERE g2.row BETWEEN lowerBound AND upperBound
    UNION all
    SELECT MAX(g2.row) FROM globalleaderboard g2
)
ORDER BY g.rank
    $$
Language SQL;

