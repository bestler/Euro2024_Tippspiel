create function sneakpeekcommunity(communityid uuid, userid uuid)
    returns TABLE(id uuid, name character varying, total_points bigint, rank bigint, "row" bigint)
    language plpgsql
as
$$
declare
num_rows integer;
user_row integer;

begin
    select count(*) into num_rows FROM community_view c WHERE community_id = communityID;
    select c.row into user_row FROM community_view c where user_id = userID and community_id = communityID;

    -- Community has not more than 7 members
    if num_rows <= 7 THEN
        RETURN QUERY SELECT c.user_id AS id, c.name, c.total_points, c.rank, c.row FROM community_view c WHERE c.community_id = communityID order by c.row;

    -- User is in TOP3 or 4th (-> Last place + first 6)
    elsif user_row <= 4 then
            RETURN QUERY SELECT c.user_id AS id, c.name, c.total_points, c.rank, c.row FROM community_view c
                          WHERE c.community_id = communityID and
                                (c.row <= 6 OR
                                c.row = num_rows)
                          ORDER BY c.row;

    -- User is on last or penultimate place
    elsif user_row = num_rows or user_row + 1 = num_rows then
        RETURN QUERY SELECT c.user_id AS id, c.name, c.total_points, c.rank, c.row FROM community_view c
                              WHERE c.community_id = communityID and (
                                    c.row <= 3 OR
                                    c.row BETWEEN num_rows - 3 AND num_rows)
                              ORDER BY c.row;

    else
    -- Everyting else
    RETURN QUERY SELECT c.user_id AS id, c.name, c.total_points, c.rank, c.row FROM community_view c
                              WHERE c.community_id = communityID and (c.row <= 3 OR
                                    c.row = user_row OR
                                    c.row BETWEEN user_row - 1 AND user_row + 1 or
                                    c.row = num_rows)
                              ORDER BY c.row;
    end if;
end;
$$;


--- Global

create or replace function sneakPeekGlobal(userID uuid)
returns TABLE(id uuid, name varchar, total_points bigint, rank bigint, "row" bigint)
language plpgsql
as
$$
declare
num_rows integer;
user_row integer;

begin
    select count(*) into num_rows FROM leaderboard l;
    select l.row into user_row FROM leaderboard l where l.id = userID;

    -- Community has not more than 7 members
    if num_rows <= 7 THEN
        RETURN QUERY SELECT * FROM community_view c order by c.row;

    -- User is in TOP3 or 4th (-> Last place + first 6)
    elsif user_row <= 4 then
            RETURN QUERY SELECT * FROM leaderboard l
                          WHERE l.row <= 6 OR
                                l.row = num_rows
                          ORDER BY l.row;

    -- User is on last or penultimate place
    elsif user_row = num_rows or user_row + 1 = num_rows then
        RETURN QUERY SELECT * FROM leaderboard l
                              WHERE l.row <= 3 OR
                                    l.row BETWEEN num_rows - 3 AND num_rows
                              ORDER BY l.row;

    else
    -- Everyting else
    RETURN QUERY SELECT * FROM leaderboard l
                              WHERE l.row <= 3 OR
                                    l.row = user_row OR
                                    l.row BETWEEN user_row - 1 AND user_row + 1 or
                                    l.row = num_rows
                              ORDER BY l.row;
    end if;
end;
$$