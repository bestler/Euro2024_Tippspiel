-- Purpose: Create a materialized view that will be used to display the leaderboard of a community.
create materialized view community_view as
(
select uc.user_id, ppu.name, ppu.total_points, uc.community_id, rank() over (community_sorted), row_number() over (community_sorted) as row
FROM points_per_user ppu
         INNER JOIN user_community uc ON uc.user_id = ppu.id
window community_sorted as (partition by uc.community_id order by total_points desc)
);


-- Function to get the leaderboard for a community and user
create function communityleaderboard(userid uuid, communityid uuid) returns table(id uuid, name text, total_points int, rank int, "row" int, isfriend boolean)
    language sql as
    $$
with selected_community as (
    SELECT user_id, name, total_points, rank, row FROM community_view WHERE community_id = communityid
), combined as (SELECT *
                  FROM selected_community as sc
                  WHERE sc.row IN (SELECT sc2.row
                                  FROM selected_community sc2
                                  WHERE sc2.row <= 3
                                     or sc2.user_id = userid
                                  UNION ALL
                                  SELECT MAX(sc2.row)
                                  FROM selected_community sc2)
                  UNION ALL
                  SELECT *
                  FROM selected_community as sl
                  WHERE sl.user_id IN (SELECT f.friend_id
                               FROM friends f
                               WHERE user_id = userid))
SELECT distinct c.*, CASE WHEN f.id IS NULL THEN false else true END as isfriend
FROM combined c
         LEFT JOIN friends f ON f.friend_id = c.user_id and f.user_id = userid order by c.row;
$$;

-- Function to refetch the leaderboard for a community and user
create function refetchcommunityleaderboard(userid uuid, communityid uuid, numtoprows integer, lowerbound integer, upperbound integer)
    returns TABLE(id uuid, name text, total_points integer, rank integer, "row" integer, isfriend boolean)
    language sql
as
$$
with selected_community as (
    SELECT user_id, name, total_points, rank, row FROM community_view WHERE community_id = communityid
), combined as (SELECT sc.user_id as id, sc.name, sc.total_points, sc.rank, sc.row
                   FROM selected_community sc
                   WHERE sc.row IN (SELECT sc2.row
                                   FROM selected_community sc2
                                   WHERE sc2.row <= numTopRows
                                   UNION all
                                   SELECT sc2.row
                                   FROM selected_community sc2
                                   WHERE sc2.user_id = userID
                                   UNION ALL
                                   SELECT sc2.row
                                   FROM selected_community sc2
                                   WHERE sc2.row BETWEEN lowerBound AND upperBound
                                   UNION all
                                   SELECT MAX(sc2.row)
                                   FROM selected_community sc2)
                   UNION ALL
                   SELECT *
                   FROM selected_community sc
                   WHERE user_id IN (SELECT f.friend_id
                                FROM friends f
                                WHERE user_id = userID)
                   )
SELECT distinct c.*, CASE WHEN f.id IS NULL THEN false else true END as isfriend
FROM combined c
         LEFT JOIN friends f ON f.friend_id = c.id and f.user_id = userid order by c.row;
$$;