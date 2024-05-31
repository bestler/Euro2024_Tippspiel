--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.1

-- Started on 2024-05-26 19:29:44 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3449 (class 1262 OID 16384)
-- Name: check24_tippspiel; Type: DATABASE; Schema: -; Owner: admin
--


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16395)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3450 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 254 (class 1255 OID 24673)
-- Name: communityleaderboard(uuid, uuid); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.communityleaderboard(userid uuid, communityid uuid) RETURNS TABLE(id uuid, name text, total_points integer, rank integer, "row" integer, isfriend boolean)
    LANGUAGE sql
    AS $$
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
                               WHERE f.user_id = userid))
SELECT distinct c.*, CASE WHEN f.id IS NULL THEN false else true END as isfriend
FROM combined c
         LEFT JOIN friends f ON f.friend_id = c.user_id and f.user_id = userid order by c.row;
$$;


ALTER FUNCTION public.communityleaderboard(userid uuid, communityid uuid) OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16426)
-- Name: bets; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.bets (
    user_id uuid NOT NULL,
    match_id uuid NOT NULL,
    goals_home integer,
    goals_away integer,
    created_at timestamp without time zone NOT NULL,
    modified_at timestamp without time zone,
    points integer DEFAULT 0,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.bets OWNER TO admin;

--
-- TOC entry 217 (class 1259 OID 16412)
-- Name: matches; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.matches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_home_name character varying NOT NULL,
    team_away_name character varying NOT NULL,
    game_starts_at timestamp without time zone NOT NULL,
    team_home_goals integer,
    team_away_goals integer
);


ALTER TABLE public.matches OWNER TO admin;

--
-- TOC entry 250 (class 1255 OID 24584)
-- Name: createbetsforuser(uuid); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.createbetsforuser(IN userid uuid)
    LANGUAGE sql
    BEGIN ATOMIC
 INSERT INTO public.bets (user_id, match_id, goals_home, goals_away, created_at, modified_at, points, id)  SELECT createbetsforuser.userid AS userid,
             matches.id,
             NULL::unknown AS unknown,
             NULL::unknown AS unknown,
             now() AS now,
             NULL::unknown AS unknown,
             0,
             public.uuid_generate_v1() AS uuid_generate_v1
            FROM public.matches;
END;


ALTER PROCEDURE public.createbetsforuser(IN userid uuid) OWNER TO admin;

--
-- TOC entry 238 (class 1255 OID 24694)
-- Name: enforce_max_communities(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.enforce_max_communities() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Count the number of communities the user is in
    IF (SELECT COUNT(*) FROM user_community WHERE user_id = NEW.user_id) >= 5 THEN
        RAISE EXCEPTION 'A user cannot be part of more than 5 communities';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.enforce_max_communities() OWNER TO admin;

--
-- TOC entry 251 (class 1255 OID 24662)
-- Name: leaderboardforuser(uuid); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.leaderboardforuser(userid uuid) RETURNS TABLE(id uuid, name text, total_points integer, rank integer, "row" integer, isfriend boolean)
    LANGUAGE sql
    AS $$
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
$$;


ALTER FUNCTION public.leaderboardforuser(userid uuid) OWNER TO admin;

--
-- TOC entry 235 (class 1255 OID 24593)
-- Name: random_between(integer, integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.random_between(low integer, high integer) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$;


ALTER FUNCTION public.random_between(low integer, high integer) OWNER TO admin;

--
-- TOC entry 253 (class 1255 OID 24687)
-- Name: refetchcommunityleaderboard(uuid, uuid, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.refetchcommunityleaderboard(userid uuid, communityid uuid, numtoprows integer, lowerbound integer, upperbound integer) RETURNS TABLE(id uuid, name text, total_points integer, rank integer, "row" integer, isfriend boolean)
    LANGUAGE sql
    AS $$
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


ALTER FUNCTION public.refetchcommunityleaderboard(userid uuid, communityid uuid, numtoprows integer, lowerbound integer, upperbound integer) OWNER TO admin;

--
-- TOC entry 252 (class 1255 OID 24664)
-- Name: refetchleaderboardforuser(uuid, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.refetchleaderboardforuser(userid uuid, numtoprows integer, lowerbound integer, upperbound integer) RETURNS TABLE(id uuid, name text, total_points integer, rank integer, "row" integer, isfriend boolean)
    LANGUAGE sql
    AS $$
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
$$;


ALTER FUNCTION public.refetchleaderboardforuser(userid uuid, numtoprows integer, lowerbound integer, upperbound integer) OWNER TO admin;

--
-- TOC entry 255 (class 1255 OID 24704)
-- Name: sneakpeekcommunity(uuid, uuid); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.sneakpeekcommunity(communityid uuid, userid uuid) RETURNS TABLE(id uuid, name character varying, total_points bigint, rank bigint, "row" bigint)
    LANGUAGE plpgsql
    AS $$
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


ALTER FUNCTION public.sneakpeekcommunity(communityid uuid, userid uuid) OWNER TO admin;

--
-- TOC entry 256 (class 1255 OID 24705)
-- Name: sneakpeekglobal(uuid); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.sneakpeekglobal(userid uuid) RETURNS TABLE(id uuid, name character varying, total_points bigint, rank bigint, "row" bigint)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.sneakpeekglobal(userid uuid) OWNER TO admin;

--
-- TOC entry 216 (class 1259 OID 16389)
-- Name: users; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_DATE
);


ALTER TABLE public.users OWNER TO admin;

--
-- TOC entry 236 (class 1255 OID 24623)
-- Name: updateallbets(); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.updateallbets()
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


ALTER PROCEDURE public.updateallbets() OWNER TO admin;

--
-- TOC entry 237 (class 1255 OID 24587)
-- Name: updatepointsbets(uuid); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.updatepointsbets(IN for_match_id uuid)
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


ALTER PROCEDURE public.updatepointsbets(IN for_match_id uuid) OWNER TO admin;

--
-- TOC entry 220 (class 1259 OID 24594)
-- Name: communities; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.communities (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.communities OWNER TO admin;

--
-- TOC entry 219 (class 1259 OID 24589)
-- Name: points_per_user; Type: VIEW; Schema: public; Owner: admin
--

CREATE VIEW public.points_per_user AS
SELECT
    NULL::uuid AS id,
    NULL::character varying(50) AS name,
    NULL::bigint AS total_points,
    NULL::timestamp without time zone AS created_at;


ALTER VIEW public.points_per_user OWNER TO admin;

--
-- TOC entry 221 (class 1259 OID 24603)
-- Name: user_community; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.user_community (
    user_id uuid NOT NULL,
    community_id uuid NOT NULL,
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL
);


ALTER TABLE public.user_community OWNER TO admin;

--
-- TOC entry 224 (class 1259 OID 24710)
-- Name: community_view; Type: MATERIALIZED VIEW; Schema: public; Owner: admin
--

CREATE MATERIALIZED VIEW public.community_view AS
 SELECT uc.user_id,
    ppu.name,
    ppu.total_points,
    uc.community_id,
    rank() OVER (community_sorted) AS rank,
    row_number() OVER (community_sorted) AS "row"
   FROM (public.points_per_user ppu
     JOIN public.user_community uc ON ((uc.user_id = ppu.id)))
  WINDOW community_sorted AS (PARTITION BY uc.community_id ORDER BY ppu.total_points DESC, ppu.created_at)
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.community_view OWNER TO admin;

--
-- TOC entry 222 (class 1259 OID 24634)
-- Name: friends; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.friends (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    user_id uuid NOT NULL,
    friend_id uuid NOT NULL
);


ALTER TABLE public.friends OWNER TO admin;

--
-- TOC entry 223 (class 1259 OID 24706)
-- Name: leaderboard; Type: MATERIALIZED VIEW; Schema: public; Owner: admin
--

CREATE MATERIALIZED VIEW public.leaderboard AS
 SELECT id,
    name,
    total_points,
    rank() OVER (ORDER BY total_points DESC, created_at) AS rank,
    row_number() OVER (ORDER BY total_points DESC, created_at) AS "row"
   FROM public.points_per_user
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.leaderboard OWNER TO admin;

--
-- TOC entry 3438 (class 0 OID 16426)
-- Dependencies: 218
-- Data for Name: bets; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.bets (user_id, match_id, goals_home, goals_away, created_at, modified_at, points, id) FROM stdin;
2fa0908f-6b1f-4d27-aa90-cad32947ca43	0e03e3ac-af2c-4bef-9248-56af4ba71f61	4	4	2024-04-22 15:55:55.501072	\N	0	cd9c87ca-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	7564c2f9-bc07-4508-9874-c8b109063be0	3	2	2024-04-22 15:55:55.501072	\N	0	cd9c887e-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	90cd45cd-1d76-44bd-ba8f-788b33716968	1	3	2024-04-22 15:55:55.501072	\N	0	cd9c8914-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	2	2	2024-04-22 15:55:55.501072	\N	0	cd9c89a0-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	fcddb2df-ca24-4547-aea8-0e365e19df5c	4	0	2024-04-22 15:55:55.501072	\N	0	cd9c8a2c-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	4	2	2024-04-22 15:55:55.501072	\N	0	cd9c8aae-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	b8137946-bfb6-4b03-9a21-7d3a29cff530	0	1	2024-04-22 15:55:55.501072	\N	0	cd9c8b6c-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	931316c1-a124-43cb-836d-e7062c99557c	3	4	2024-04-22 15:55:55.501072	\N	0	cd9c8bf8-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	d75cab45-ec3e-4269-b964-b276f9e4badf	2	4	2024-04-22 15:55:55.501072	\N	0	cd9c8c84-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	989cae66-b7a1-4599-a611-671b8673d6d7	4	2	2024-04-22 15:55:55.501072	\N	0	cd9c8d1a-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	4fda6447-4daa-48da-abfb-944b7c5d37ac	3	3	2024-04-22 15:55:55.501072	\N	0	cd9c8da6-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	4	0	2024-04-22 15:55:55.501072	\N	0	cd9c8ee6-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	36465753-8cc2-47cf-8018-96c409f097d6	3	0	2024-04-22 15:55:55.501072	\N	0	cd9c8f7c-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	1c0db01f-0d55-4ee6-978d-7eac43711009	0	2	2024-04-22 15:55:55.501072	\N	0	cd9c9008-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	b8a189d8-7c52-4a94-864c-39a9857416f1	3	2	2024-04-22 15:55:55.501072	\N	0	cd9c9094-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	df3f176b-ac53-446e-893f-ed91bf54e9c0	3	2	2024-04-22 15:55:55.501072	\N	0	cd9c9120-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	2	0	2024-04-22 15:55:55.501072	\N	0	cd9c9274-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	63cad7c3-1224-4a56-ad32-02be23a38101	1	3	2024-04-22 15:55:55.501072	\N	0	cd9c9332-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	c3154242-bca6-4c37-9bf0-a49be4a7d424	2	2	2024-04-22 15:55:55.501072	\N	0	cd9c93be-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	f8ca2700-562b-4705-a462-3f32019a054b	1	1	2024-04-22 15:55:55.501072	\N	0	cd9c944a-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	d4e59642-8134-4fd4-b007-f9dc748b8033	1	2	2024-04-22 15:55:55.501072	\N	0	cd9c94cc-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	b6e42279-0b18-46a4-83e0-59a7e1741262	4	0	2024-04-22 15:55:55.501072	\N	0	cd9c9558-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	1	4	2024-04-22 15:55:55.501072	\N	0	cd9c96ca-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	0	1	2024-04-22 15:55:55.501072	\N	0	cd9c9850-00c0-11ef-93ee-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	aa05f762-0d4d-425b-982d-d994baafc6be	3	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.295165	0	bb2369fe-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	532917a6-fa6d-4628-a836-b884a3c26153	2	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.298546	0	bb236ac6-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	2	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.30217	0	bb236ba2-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.310101	0	bb236d1e-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	1	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.314259	0	bb236e04-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	2	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.317421	0	bb236ed6-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	2b1865c5-25ef-4754-b654-3e34877ef96e	4	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.320741	0	bb237160-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	bd0565db-03ab-47df-8792-f929f608d088	1	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.327941	0	bb237282-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	3d5d543e-8140-4e08-8be1-4817ea2cff78	3	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.331343	0	bb233740-fcbc-11ee-84e7-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	aa05f762-0d4d-425b-982d-d994baafc6be	3	4	2024-04-22 15:55:55.501072	\N	0	cd9c9904-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	532917a6-fa6d-4628-a836-b884a3c26153	4	1	2024-04-22 15:55:55.501072	\N	0	cd9c999a-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	4	2	2024-04-22 15:55:55.501072	\N	0	cd9c9a26-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	2	1	2024-04-22 15:55:55.501072	\N	0	cd9c9ad0-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	4	4	2024-04-22 15:55:55.501072	\N	0	cd9c9b52-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	3	3	2024-04-22 15:55:55.501072	\N	0	cd9c9d6e-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	2b1865c5-25ef-4754-b654-3e34877ef96e	2	4	2024-04-22 15:55:55.501072	\N	0	cd9c9e2c-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	bd0565db-03ab-47df-8792-f929f608d088	0	1	2024-04-22 15:55:55.501072	\N	0	cd9c9ed6-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	709b5a9a-b435-47c9-abfe-6ff96967686a	2	4	2024-04-22 15:55:55.501072	\N	0	cd9c9f6c-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	df2d11bf-3749-4eac-bc22-bad13cad4d85	4	4	2024-04-22 15:55:55.501072	\N	0	cd9c9ff8-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	096e0ae4-4b80-4f52-9495-9abb10454fcf	2	1	2024-04-22 15:55:55.501072	\N	0	cd9ca07a-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	7e0da98b-4e38-41b2-adef-d7f8281700a4	1	0	2024-04-22 15:55:55.501072	\N	0	cd9ca106-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	62266b5d-6d3c-402c-b57b-14a5e74f6a22	4	3	2024-04-22 15:55:55.501072	\N	0	cd9ca192-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	fa6fb251-d015-40ab-98d8-0d775ef7f086	0	4	2024-04-22 15:55:55.501072	\N	0	cd9ca21e-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	2	1	2024-04-22 15:55:55.501072	\N	0	cd9ca2a0-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	0	3	2024-04-22 15:55:55.501072	\N	0	cd9ca3ae-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	0	3	2024-04-22 15:55:55.501072	\N	0	cd9ca43a-00c0-11ef-93ee-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	3d5d543e-8140-4e08-8be1-4817ea2cff78	0	3	2024-04-22 15:34:11.445734	\N	0	c4560842-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	1	2	2024-04-22 15:34:11.445734	\N	0	c4563e7a-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	ffafa9a0-070e-40a9-8209-91ad5f701923	3	4	2024-04-22 15:34:11.445734	\N	0	c456400a-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	0	0	2024-04-22 15:34:11.445734	\N	0	c45640b4-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	1a903f72-95b8-4ee3-b2af-09266b896ad5	2	2	2024-04-22 15:34:11.445734	\N	0	c456414a-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	0	3	2024-04-22 15:34:11.445734	\N	0	c45641cc-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	3	4	2024-04-22 15:34:11.445734	\N	0	c456426c-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	0e03e3ac-af2c-4bef-9248-56af4ba71f61	1	1	2024-04-22 15:34:11.445734	\N	0	c45642f8-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	7564c2f9-bc07-4508-9874-c8b109063be0	3	1	2024-04-22 15:34:11.445734	\N	0	c4564384-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	90cd45cd-1d76-44bd-ba8f-788b33716968	3	1	2024-04-22 15:34:11.445734	\N	0	c4564410-00bd-11ef-9729-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	ccda7052-59f8-4b04-b2f7-220438948978	3	3	2024-04-22 15:55:55.501072	\N	4	cd9ca4e4-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	0	4	2024-04-22 15:55:55.501072	\N	0	cd9ca570-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	0	4	2024-04-22 15:55:55.501072	\N	4	cd9ca5fc-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	3d5d543e-8140-4e08-8be1-4817ea2cff78	4	3	2024-04-22 15:56:00.604451	\N	0	d0a6320e-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	0	4	2024-04-22 15:56:00.604451	\N	0	d0a63484-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	ffafa9a0-070e-40a9-8209-91ad5f701923	4	4	2024-04-22 15:56:00.604451	\N	0	d0a6359c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	4	4	2024-04-22 15:56:00.604451	\N	0	d0a63632-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	1a903f72-95b8-4ee3-b2af-09266b896ad5	3	3	2024-04-22 15:56:00.604451	\N	0	d0a636be-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	2	1	2024-04-22 15:56:00.604451	\N	0	d0a6374a-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	1	0	2024-04-22 15:56:00.604451	\N	0	d0a637d6-00c0-11ef-93ee-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	df3f176b-ac53-446e-893f-ed91bf54e9c0	2	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.252074	0	bb2362ce-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	2	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.131544	0	bb238506-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	ccda7052-59f8-4b04-b2f7-220438948978	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.1355	4	bb238e20-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	0	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.139371	4	bb238f9c-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	0	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.144425	4	bb234ce4-fcbc-11ee-84e7-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	0e03e3ac-af2c-4bef-9248-56af4ba71f61	3	0	2024-04-22 15:56:00.604451	\N	0	d0a63862-00c0-11ef-93ee-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.148254	0	bb234f96-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	ffafa9a0-070e-40a9-8209-91ad5f701923	3	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.151689	0	bb235086-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.155863	0	bb235176-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	1a903f72-95b8-4ee3-b2af-09266b896ad5	3	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.164122	0	bb23525c-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	0	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.167773	0	bb235338-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	4	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.171337	0	bb23541e-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	0e03e3ac-af2c-4bef-9248-56af4ba71f61	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.179094	0	bb2354fa-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	7564c2f9-bc07-4508-9874-c8b109063be0	3	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.183387	0	bb2355cc-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	90cd45cd-1d76-44bd-ba8f-788b33716968	3	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.187004	0	bb2356a8-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	4	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.19519	0	bb235784-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	fcddb2df-ca24-4547-aea8-0e365e19df5c	3	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.198777	0	bb23596e-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.20241	0	bb235a7c-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	b8137946-bfb6-4b03-9a21-7d3a29cff530	2	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.207524	0	bb235b4e-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	931316c1-a124-43cb-836d-e7062c99557c	3	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.212489	0	bb235c2a-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	d75cab45-ec3e-4269-b964-b276f9e4badf	2	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.216672	0	bb235cfc-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	989cae66-b7a1-4599-a611-671b8673d6d7	1	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.22047	0	bb235dce-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	4fda6447-4daa-48da-abfb-944b7c5d37ac	3	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.230094	0	bb235e96-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	4	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.234203	0	bb235f68-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	1c0db01f-0d55-4ee6-978d-7eac43711009	2	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.24703	0	bb236102-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	36465753-8cc2-47cf-8018-96c409f097d6	3	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.249901	0	bb23603a-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	b8a189d8-7c52-4a94-864c-39a9857416f1	2	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.256287	0	bb2361ca-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	63cad7c3-1224-4a56-ad32-02be23a38101	3	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.261731	0	bb23645e-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	1	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.264963	0	bb236396-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	c3154242-bca6-4c37-9bf0-a49be4a7d424	1	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.268798	0	bb236530-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	f8ca2700-562b-4705-a462-3f32019a054b	2	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.27221	0	bb236602-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	d4e59642-8134-4fd4-b007-f9dc748b8033	4	1	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.279143	0	bb2366ca-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	b6e42279-0b18-46a4-83e0-59a7e1741262	2	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.282867	0	bb236792-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	4	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.286381	0	bb236864-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	4	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.291661	0	bb236936-fcbc-11ee-84e7-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	df3f176b-ac53-446e-893f-ed91bf54e9c0	0	2	2024-04-22 15:34:11.445734	\N	0	c4564cee-00bd-11ef-9729-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	1	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.127402	4	bb2383c6-fcbc-11ee-84e7-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	1	3	2024-04-22 15:34:11.445734	\N	0	c4564492-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	fcddb2df-ca24-4547-aea8-0e365e19df5c	0	4	2024-04-22 15:34:11.445734	\N	0	c4564514-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	2	2	2024-04-22 15:34:11.445734	\N	0	c45645aa-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	b8137946-bfb6-4b03-9a21-7d3a29cff530	3	2	2024-04-22 15:34:11.445734	\N	0	c45646fe-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	931316c1-a124-43cb-836d-e7062c99557c	1	2	2024-04-22 15:34:11.445734	\N	0	c45647b2-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	d75cab45-ec3e-4269-b964-b276f9e4badf	4	0	2024-04-22 15:34:11.445734	\N	0	c456483e-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	989cae66-b7a1-4599-a611-671b8673d6d7	1	0	2024-04-22 15:34:11.445734	\N	0	c45649a6-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	4fda6447-4daa-48da-abfb-944b7c5d37ac	1	1	2024-04-22 15:34:11.445734	\N	0	c4564a46-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	1	2	2024-04-22 15:34:11.445734	\N	0	c4564ad2-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	36465753-8cc2-47cf-8018-96c409f097d6	4	2	2024-04-22 15:34:11.445734	\N	0	c4564b5e-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	1c0db01f-0d55-4ee6-978d-7eac43711009	1	3	2024-04-22 15:34:11.445734	\N	0	c4564be0-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	b8a189d8-7c52-4a94-864c-39a9857416f1	3	2	2024-04-22 15:34:11.445734	\N	0	c4564c62-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	4	2	2024-04-22 15:34:11.445734	\N	0	c4564d70-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	63cad7c3-1224-4a56-ad32-02be23a38101	4	2	2024-04-22 15:34:11.445734	\N	0	c4564e10-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	c3154242-bca6-4c37-9bf0-a49be4a7d424	4	3	2024-04-22 15:34:11.445734	\N	0	c4564e92-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	f8ca2700-562b-4705-a462-3f32019a054b	2	2	2024-04-22 15:34:11.445734	\N	0	c4564f14-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	d4e59642-8134-4fd4-b007-f9dc748b8033	0	2	2024-04-22 15:34:11.445734	\N	0	c4564fa0-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	b6e42279-0b18-46a4-83e0-59a7e1741262	0	0	2024-04-22 15:34:11.445734	\N	0	c4565036-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	4	0	2024-04-22 15:34:11.445734	\N	0	c45650b8-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	2	2	2024-04-22 15:34:11.445734	\N	0	c4565144-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	aa05f762-0d4d-425b-982d-d994baafc6be	2	3	2024-04-22 15:34:11.445734	\N	0	c4565234-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	532917a6-fa6d-4628-a836-b884a3c26153	4	0	2024-04-22 15:34:11.445734	\N	0	c45652e8-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	1	0	2024-04-22 15:34:11.445734	\N	0	c4565374-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	4	1	2024-04-22 15:34:11.445734	\N	0	c4565400-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	4	3	2024-04-22 15:34:11.445734	\N	0	c4565482-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	0	2	2024-04-22 15:34:11.445734	\N	0	c456550e-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	2b1865c5-25ef-4754-b654-3e34877ef96e	3	1	2024-04-22 15:34:11.445734	\N	0	c4565590-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	bd0565db-03ab-47df-8792-f929f608d088	2	0	2024-04-22 15:34:11.445734	\N	0	c456561c-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	709b5a9a-b435-47c9-abfe-6ff96967686a	3	0	2024-04-22 15:34:11.445734	\N	0	c456569e-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	df2d11bf-3749-4eac-bc22-bad13cad4d85	2	3	2024-04-22 15:34:11.445734	\N	0	c4565720-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	096e0ae4-4b80-4f52-9495-9abb10454fcf	0	4	2024-04-22 15:34:11.445734	\N	0	c45657ac-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	7e0da98b-4e38-41b2-adef-d7f8281700a4	2	4	2024-04-22 15:34:11.445734	\N	0	c456582e-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	2	1	2024-04-22 15:34:11.445734	\N	4	c4565c16-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	62266b5d-6d3c-402c-b57b-14a5e74f6a22	1	4	2024-04-22 15:34:11.445734	\N	0	c45659f0-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	fa6fb251-d015-40ab-98d8-0d775ef7f086	0	2	2024-04-22 15:34:11.445734	\N	0	c4565acc-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	4	4	2024-04-22 15:34:11.445734	\N	0	c4565b80-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	3	1	2024-04-22 15:34:11.445734	\N	4	c4565c98-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	ccda7052-59f8-4b04-b2f7-220438948978	1	2	2024-04-22 15:34:11.445734	\N	4	c4565d24-00bd-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	4	4	2024-04-22 15:34:11.445734	\N	4	c4565db0-00bd-11ef-9729-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	7564c2f9-bc07-4508-9874-c8b109063be0	1	1	2024-04-22 15:56:00.604451	\N	0	d0a63a74-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	90cd45cd-1d76-44bd-ba8f-788b33716968	3	0	2024-04-22 15:56:00.604451	\N	0	d0a63b0a-00c0-11ef-93ee-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	df3f176b-ac53-446e-893f-ed91bf54e9c0	1	4	2024-04-22 15:38:57.690591	\N	0	6ef1f658-00be-11ef-9729-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	4	0	2024-04-22 15:34:11.445734	\N	4	c4565e32-00bd-11ef-9729-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	4	0	2024-04-22 15:56:00.604451	\N	0	d0a63b96-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	fcddb2df-ca24-4547-aea8-0e365e19df5c	1	0	2024-04-22 15:56:00.604451	\N	0	d0a63c54-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	3	0	2024-04-22 15:56:00.604451	\N	0	d0a63ce0-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	b8137946-bfb6-4b03-9a21-7d3a29cff530	4	0	2024-04-22 15:56:00.604451	\N	0	d0a63d6c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	931316c1-a124-43cb-836d-e7062c99557c	3	1	2024-04-22 15:56:00.604451	\N	0	d0a63e02-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	d75cab45-ec3e-4269-b964-b276f9e4badf	0	0	2024-04-22 15:56:00.604451	\N	0	d0a63e8e-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	989cae66-b7a1-4599-a611-671b8673d6d7	1	0	2024-04-22 15:56:00.604451	\N	0	d0a63f1a-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	4fda6447-4daa-48da-abfb-944b7c5d37ac	0	3	2024-04-22 15:56:00.604451	\N	0	d0a63fa6-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	0	4	2024-04-22 15:56:00.604451	\N	0	d0a64032-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	36465753-8cc2-47cf-8018-96c409f097d6	0	3	2024-04-22 15:56:00.604451	\N	0	d0a640b4-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	1c0db01f-0d55-4ee6-978d-7eac43711009	2	0	2024-04-22 15:56:00.604451	\N	0	d0a64140-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	b8a189d8-7c52-4a94-864c-39a9857416f1	3	3	2024-04-22 15:56:00.604451	\N	0	d0a641c2-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	df3f176b-ac53-446e-893f-ed91bf54e9c0	4	2	2024-04-22 15:56:00.604451	\N	0	d0a6424e-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	4	4	2024-04-22 15:56:00.604451	\N	0	d0a642da-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	63cad7c3-1224-4a56-ad32-02be23a38101	1	4	2024-04-22 15:56:00.604451	\N	0	d0a6435c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	c3154242-bca6-4c37-9bf0-a49be4a7d424	3	1	2024-04-22 15:56:00.604451	\N	0	d0a643e8-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	f8ca2700-562b-4705-a462-3f32019a054b	0	2	2024-04-22 15:56:00.604451	\N	0	d0a6447e-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	d4e59642-8134-4fd4-b007-f9dc748b8033	0	4	2024-04-22 15:56:00.604451	\N	0	d0a6450a-00c0-11ef-93ee-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	3d5d543e-8140-4e08-8be1-4817ea2cff78	2	0	2024-04-22 15:38:57.690591	\N	0	6ef1ed66-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	0	4	2024-04-22 15:38:57.690591	\N	0	6ef1f144-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	ffafa9a0-070e-40a9-8209-91ad5f701923	3	1	2024-04-22 15:38:57.690591	\N	0	6ef1f194-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	0	1	2024-04-22 15:38:57.690591	\N	0	6ef1f1c6-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	1a903f72-95b8-4ee3-b2af-09266b896ad5	1	0	2024-04-22 15:38:57.690591	\N	0	6ef1f202-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	0	2	2024-04-22 15:38:57.690591	\N	0	6ef1f234-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	4	3	2024-04-22 15:38:57.690591	\N	0	6ef1f25c-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	0e03e3ac-af2c-4bef-9248-56af4ba71f61	3	4	2024-04-22 15:38:57.690591	\N	0	6ef1f28e-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	7564c2f9-bc07-4508-9874-c8b109063be0	3	4	2024-04-22 15:38:57.690591	\N	0	6ef1f2c0-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	90cd45cd-1d76-44bd-ba8f-788b33716968	2	0	2024-04-22 15:38:57.690591	\N	0	6ef1f2f2-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	3	2	2024-04-22 15:38:57.690591	\N	0	6ef1f324-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	fcddb2df-ca24-4547-aea8-0e365e19df5c	4	2	2024-04-22 15:38:57.690591	\N	0	6ef1f34c-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	1	0	2024-04-22 15:38:57.690591	\N	0	6ef1f37e-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	b8137946-bfb6-4b03-9a21-7d3a29cff530	3	2	2024-04-22 15:38:57.690591	\N	0	6ef1f3b0-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	931316c1-a124-43cb-836d-e7062c99557c	3	3	2024-04-22 15:38:57.690591	\N	0	6ef1f3d8-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	d75cab45-ec3e-4269-b964-b276f9e4badf	1	2	2024-04-22 15:38:57.690591	\N	0	6ef1f414-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	989cae66-b7a1-4599-a611-671b8673d6d7	2	1	2024-04-22 15:38:57.690591	\N	0	6ef1f478-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	4fda6447-4daa-48da-abfb-944b7c5d37ac	0	3	2024-04-22 15:38:57.690591	\N	0	6ef1f4c8-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	4	3	2024-04-22 15:38:57.690591	\N	0	6ef1f4fa-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	36465753-8cc2-47cf-8018-96c409f097d6	3	0	2024-04-22 15:38:57.690591	\N	0	6ef1f5ae-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	1c0db01f-0d55-4ee6-978d-7eac43711009	4	4	2024-04-22 15:38:57.690591	\N	0	6ef1f5ea-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	b8a189d8-7c52-4a94-864c-39a9857416f1	3	1	2024-04-22 15:38:57.690591	\N	0	6ef1f61c-00be-11ef-9729-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	0e03e3ac-af2c-4bef-9248-56af4ba71f61	0	4	2024-04-23 17:42:17.114389	\N	0	d3c22898-0198-11ef-b991-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	0	2	2024-04-22 15:38:57.690591	\N	0	6ef1f68a-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	63cad7c3-1224-4a56-ad32-02be23a38101	0	0	2024-04-22 15:38:57.690591	\N	0	6ef1f6bc-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	c3154242-bca6-4c37-9bf0-a49be4a7d424	4	2	2024-04-22 15:38:57.690591	\N	0	6ef1f6ee-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	f8ca2700-562b-4705-a462-3f32019a054b	3	3	2024-04-22 15:38:57.690591	\N	0	6ef1f720-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	d4e59642-8134-4fd4-b007-f9dc748b8033	1	0	2024-04-22 15:38:57.690591	\N	0	6ef1f748-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	b6e42279-0b18-46a4-83e0-59a7e1741262	3	0	2024-04-22 15:38:57.690591	\N	0	6ef1f77a-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	4	4	2024-04-22 15:38:57.690591	\N	0	6ef1f7ac-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	1	3	2024-04-22 15:38:57.690591	\N	0	6ef1f7de-00be-11ef-9729-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	b6e42279-0b18-46a4-83e0-59a7e1741262	1	3	2024-04-22 15:56:00.604451	\N	0	d0a6458c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	4	0	2024-04-22 15:56:00.604451	\N	0	d0a64618-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	2	3	2024-04-22 15:56:00.604451	\N	0	d0a646ae-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	aa05f762-0d4d-425b-982d-d994baafc6be	2	0	2024-04-22 15:56:00.604451	\N	0	d0a6473a-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	532917a6-fa6d-4628-a836-b884a3c26153	1	0	2024-04-22 15:56:00.604451	\N	0	d0a647c6-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	4	4	2024-04-22 15:56:00.604451	\N	0	d0a6485c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	1	1	2024-04-22 15:56:00.604451	\N	0	d0a648e8-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	3	2	2024-04-22 15:56:00.604451	\N	0	d0a64974-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	4	4	2024-04-22 15:56:00.604451	\N	0	d0a649f6-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	2b1865c5-25ef-4754-b654-3e34877ef96e	1	1	2024-04-22 15:56:00.604451	\N	0	d0a64a78-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	bd0565db-03ab-47df-8792-f929f608d088	0	4	2024-04-22 15:56:00.604451	\N	0	d0a64b04-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	709b5a9a-b435-47c9-abfe-6ff96967686a	0	3	2024-04-22 15:56:00.604451	\N	0	d0a64d3e-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	df2d11bf-3749-4eac-bc22-bad13cad4d85	2	2	2024-04-22 15:56:00.604451	\N	0	d0a64e74-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	096e0ae4-4b80-4f52-9495-9abb10454fcf	2	2	2024-04-22 15:56:00.604451	\N	0	d0a64f0a-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	7e0da98b-4e38-41b2-adef-d7f8281700a4	4	1	2024-04-22 15:56:00.604451	\N	0	d0a64f96-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	62266b5d-6d3c-402c-b57b-14a5e74f6a22	1	1	2024-04-22 15:56:00.604451	\N	0	d0a6502c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	fa6fb251-d015-40ab-98d8-0d775ef7f086	0	0	2024-04-22 15:56:00.604451	\N	0	d0a650b8-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	2	4	2024-04-22 15:56:00.604451	\N	0	d0a65144-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	2	0	2024-04-22 15:56:00.604451	\N	6	d0a65360-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	1	2	2024-04-22 15:56:00.604451	\N	0	d0a65428-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	ccda7052-59f8-4b04-b2f7-220438948978	3	1	2024-04-22 15:56:00.604451	\N	4	d0a654be-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	3	4	2024-04-22 15:56:00.604451	\N	0	d0a65554-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	1	0	2024-04-22 15:56:00.604451	\N	4	d0a655d6-00c0-11ef-93ee-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	7564c2f9-bc07-4508-9874-c8b109063be0	2	4	2024-04-23 17:42:17.114389	\N	0	d3c22adc-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	90cd45cd-1d76-44bd-ba8f-788b33716968	4	4	2024-04-23 17:42:17.114389	\N	0	d3c22b72-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	1	2	2024-04-23 17:42:17.114389	\N	0	d3c22c08-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	fcddb2df-ca24-4547-aea8-0e365e19df5c	0	1	2024-04-23 17:42:17.114389	\N	0	d3c22c94-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	4	4	2024-04-23 17:42:17.114389	\N	0	d3c22d20-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	b8137946-bfb6-4b03-9a21-7d3a29cff530	2	0	2024-04-23 17:42:17.114389	\N	0	d3c22da2-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	931316c1-a124-43cb-836d-e7062c99557c	4	1	2024-04-23 17:42:17.114389	\N	0	d3c22e2e-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	d75cab45-ec3e-4269-b964-b276f9e4badf	4	3	2024-04-23 17:42:17.114389	\N	0	d3c22eba-0198-11ef-b991-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	2b1865c5-25ef-4754-b654-3e34877ef96e	0	2	2024-04-22 15:38:57.690591	\N	0	6ef1f98c-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	bd0565db-03ab-47df-8792-f929f608d088	4	0	2024-04-22 15:38:57.690591	\N	0	6ef1f9be-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	709b5a9a-b435-47c9-abfe-6ff96967686a	3	2	2024-04-22 15:38:57.690591	\N	0	6ef1f9e6-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	df2d11bf-3749-4eac-bc22-bad13cad4d85	1	2	2024-04-22 15:38:57.690591	\N	0	6ef1fa18-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	096e0ae4-4b80-4f52-9495-9abb10454fcf	0	4	2024-04-22 15:38:57.690591	\N	0	6ef1fa40-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	7e0da98b-4e38-41b2-adef-d7f8281700a4	0	1	2024-04-22 15:38:57.690591	\N	0	6ef1fa72-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	aa05f762-0d4d-425b-982d-d994baafc6be	1	1	2024-04-22 15:38:57.690591	\N	0	6ef1f810-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	532917a6-fa6d-4628-a836-b884a3c26153	1	4	2024-04-22 15:38:57.690591	\N	0	6ef1f842-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	1	4	2024-04-22 15:38:57.690591	\N	0	6ef1f86a-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	1	1	2024-04-22 15:38:57.690591	\N	0	6ef1f89c-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	1	3	2024-04-22 15:38:57.690591	\N	0	6ef1f8d8-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	3	3	2024-04-22 15:38:57.690591	\N	0	6ef1f950-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	62266b5d-6d3c-402c-b57b-14a5e74f6a22	3	1	2024-04-22 15:38:57.690591	\N	0	6ef1fb4e-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	fa6fb251-d015-40ab-98d8-0d775ef7f086	0	2	2024-04-22 15:38:57.690591	\N	0	6ef1fb8a-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	3	2	2024-04-22 15:38:57.690591	\N	0	6ef1fbbc-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	2	0	2024-04-22 15:38:57.690591	\N	6	6ef1fbee-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	4	1	2024-04-22 15:38:57.690591	\N	8	6ef1fc20-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	ccda7052-59f8-4b04-b2f7-220438948978	2	3	2024-04-22 15:38:57.690591	\N	4	6ef1fc5c-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	0	3	2024-04-22 15:38:57.690591	\N	0	6ef1fc8e-00be-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	4	3	2024-04-22 15:38:57.690591	\N	4	6ef1fcc0-00be-11ef-9729-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	3d5d543e-8140-4e08-8be1-4817ea2cff78	1	1	2024-04-23 17:42:11.221197	\N	0	d04236e0-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	0	0	2024-04-23 17:42:11.221197	\N	0	d0428e6a-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	ffafa9a0-070e-40a9-8209-91ad5f701923	1	0	2024-04-23 17:42:11.221197	\N	0	d0428f14-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	0	4	2024-04-23 17:42:11.221197	\N	0	d0428f82-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	1a903f72-95b8-4ee3-b2af-09266b896ad5	0	4	2024-04-23 17:42:11.221197	\N	0	d0428fe6-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	1	4	2024-04-23 17:42:11.221197	\N	0	d0429054-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	0	4	2024-04-23 17:42:11.221197	\N	0	d04290ae-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	0e03e3ac-af2c-4bef-9248-56af4ba71f61	1	0	2024-04-23 17:42:11.221197	\N	0	d0429108-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	7564c2f9-bc07-4508-9874-c8b109063be0	1	2	2024-04-23 17:42:11.221197	\N	0	d042916c-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	90cd45cd-1d76-44bd-ba8f-788b33716968	4	3	2024-04-23 17:42:11.221197	\N	0	d0429216-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	4	0	2024-04-23 17:42:11.221197	\N	0	d04292a2-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	fcddb2df-ca24-4547-aea8-0e365e19df5c	0	2	2024-04-23 17:42:11.221197	\N	0	d04292fc-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	4	3	2024-04-23 17:42:11.221197	\N	0	d0429356-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	b8137946-bfb6-4b03-9a21-7d3a29cff530	0	2	2024-04-23 17:42:11.221197	\N	0	d04293b0-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	931316c1-a124-43cb-836d-e7062c99557c	4	4	2024-04-23 17:42:11.221197	\N	0	d0429400-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	d75cab45-ec3e-4269-b964-b276f9e4badf	2	3	2024-04-23 17:42:11.221197	\N	0	d042945a-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	989cae66-b7a1-4599-a611-671b8673d6d7	1	3	2024-04-23 17:42:11.221197	\N	0	d04294b4-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	4fda6447-4daa-48da-abfb-944b7c5d37ac	1	0	2024-04-23 17:42:11.221197	\N	0	d042950e-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	0	4	2024-04-23 17:42:11.221197	\N	0	d0429568-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	36465753-8cc2-47cf-8018-96c409f097d6	3	2	2024-04-23 17:42:11.221197	\N	0	d04295c2-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	1c0db01f-0d55-4ee6-978d-7eac43711009	1	0	2024-04-23 17:42:11.221197	\N	0	d0429612-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	b8a189d8-7c52-4a94-864c-39a9857416f1	0	0	2024-04-23 17:42:11.221197	\N	0	d042966c-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	df3f176b-ac53-446e-893f-ed91bf54e9c0	1	2	2024-04-23 17:42:11.221197	\N	0	d04296c6-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	1	0	2024-04-23 17:42:11.221197	\N	0	d0429720-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	63cad7c3-1224-4a56-ad32-02be23a38101	3	3	2024-04-23 17:42:11.221197	\N	0	d042977a-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	c3154242-bca6-4c37-9bf0-a49be4a7d424	1	1	2024-04-23 17:42:11.221197	\N	0	d04297d4-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	f8ca2700-562b-4705-a462-3f32019a054b	3	2	2024-04-23 17:42:11.221197	\N	0	d042a076-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	d4e59642-8134-4fd4-b007-f9dc748b8033	2	0	2024-04-23 17:42:11.221197	\N	0	d042a0e4-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	b6e42279-0b18-46a4-83e0-59a7e1741262	3	1	2024-04-23 17:42:11.221197	\N	0	d042a13e-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	1	4	2024-04-23 17:42:11.221197	\N	0	d042a198-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	0	2	2024-04-23 17:42:11.221197	\N	0	d042a1e8-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	aa05f762-0d4d-425b-982d-d994baafc6be	0	1	2024-04-23 17:42:11.221197	\N	0	d042a242-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	532917a6-fa6d-4628-a836-b884a3c26153	0	1	2024-04-23 17:42:11.221197	\N	0	d042a29c-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	2	0	2024-04-23 17:42:11.221197	\N	0	d042a2f6-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	2	4	2024-04-23 17:42:11.221197	\N	0	d042a35a-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	1	1	2024-04-23 17:42:11.221197	\N	0	d042a3b4-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	3	0	2024-04-23 17:42:11.221197	\N	0	d042a4ea-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	2b1865c5-25ef-4754-b654-3e34877ef96e	4	3	2024-04-23 17:42:11.221197	\N	0	d042a544-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	bd0565db-03ab-47df-8792-f929f608d088	1	4	2024-04-23 17:42:11.221197	\N	0	d042a5bc-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	709b5a9a-b435-47c9-abfe-6ff96967686a	1	0	2024-04-23 17:42:11.221197	\N	0	d042a616-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	df2d11bf-3749-4eac-bc22-bad13cad4d85	3	2	2024-04-23 17:42:11.221197	\N	0	d042a666-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	096e0ae4-4b80-4f52-9495-9abb10454fcf	3	3	2024-04-23 17:42:11.221197	\N	0	d042a6c0-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	7e0da98b-4e38-41b2-adef-d7f8281700a4	1	3	2024-04-23 17:42:11.221197	\N	0	d042a710-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	62266b5d-6d3c-402c-b57b-14a5e74f6a22	1	4	2024-04-23 17:42:11.221197	\N	0	d042a76a-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	fa6fb251-d015-40ab-98d8-0d775ef7f086	3	2	2024-04-23 17:42:11.221197	\N	0	d042a7ba-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	0	3	2024-04-23 17:42:11.221197	\N	0	d042a814-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	1	0	2024-04-23 17:42:11.221197	\N	4	d042a8c8-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	0	0	2024-04-23 17:42:11.221197	\N	4	d042a922-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	ccda7052-59f8-4b04-b2f7-220438948978	2	2	2024-04-23 17:42:11.221197	\N	8	d042a97c-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	0	4	2024-04-23 17:42:11.221197	\N	0	d042a9cc-0198-11ef-b991-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	4	4	2024-04-23 17:42:11.221197	\N	4	d042aa26-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	3d5d543e-8140-4e08-8be1-4817ea2cff78	2	3	2024-04-23 17:42:17.114389	\N	0	d3c222bc-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	4	0	2024-04-23 17:42:17.114389	\N	0	d3c2250a-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	ffafa9a0-070e-40a9-8209-91ad5f701923	4	2	2024-04-23 17:42:17.114389	\N	0	d3c225b4-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	2	2	2024-04-23 17:42:17.114389	\N	0	d3c2264a-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	1a903f72-95b8-4ee3-b2af-09266b896ad5	2	3	2024-04-23 17:42:17.114389	\N	0	d3c226ea-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	4	4	2024-04-23 17:42:17.114389	\N	0	d3c22776-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	1	3	2024-04-23 17:42:17.114389	\N	0	d3c2280c-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	989cae66-b7a1-4599-a611-671b8673d6d7	3	2	2024-04-23 17:42:17.114389	\N	0	d3c22f3c-0198-11ef-b991-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	3d5d543e-8140-4e08-8be1-4817ea2cff78	\N	\N	2024-05-14 21:15:17.633943	\N	0	10393128-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398c72-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	ffafa9a0-070e-40a9-8209-91ad5f701923	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398cea-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398d30-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	1a903f72-95b8-4ee3-b2af-09266b896ad5	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398d62-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398d9e-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398dd0-1237-11ef-bcd3-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	4fda6447-4daa-48da-abfb-944b7c5d37ac	0	1	2024-04-23 17:42:17.114389	\N	0	d3c239a0-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	4	1	2024-04-23 17:42:17.114389	\N	0	d3c23a4a-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	36465753-8cc2-47cf-8018-96c409f097d6	0	0	2024-04-23 17:42:17.114389	\N	0	d3c23b30-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	1c0db01f-0d55-4ee6-978d-7eac43711009	1	3	2024-04-23 17:42:17.114389	\N	0	d3c23cb6-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	b8a189d8-7c52-4a94-864c-39a9857416f1	3	4	2024-04-23 17:42:17.114389	\N	0	d3c23d74-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	df3f176b-ac53-446e-893f-ed91bf54e9c0	2	2	2024-04-23 17:42:17.114389	\N	0	d3c23e00-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	3	3	2024-04-23 17:42:17.114389	\N	0	d3c23e8c-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	63cad7c3-1224-4a56-ad32-02be23a38101	2	2	2024-04-23 17:42:17.114389	\N	0	d3c23f18-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	c3154242-bca6-4c37-9bf0-a49be4a7d424	2	0	2024-04-23 17:42:17.114389	\N	0	d3c23f9a-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	f8ca2700-562b-4705-a462-3f32019a054b	2	0	2024-04-23 17:42:17.114389	\N	0	d3c24026-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	d4e59642-8134-4fd4-b007-f9dc748b8033	0	1	2024-04-23 17:42:17.114389	\N	0	d3c240b2-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	b6e42279-0b18-46a4-83e0-59a7e1741262	3	4	2024-04-23 17:42:17.114389	\N	0	d3c24134-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	4	0	2024-04-23 17:42:17.114389	\N	0	d3c241c0-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	1	3	2024-04-23 17:42:17.114389	\N	0	d3c24242-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	aa05f762-0d4d-425b-982d-d994baafc6be	0	0	2024-04-23 17:42:17.114389	\N	0	d3c242ce-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	532917a6-fa6d-4628-a836-b884a3c26153	0	3	2024-04-23 17:42:17.114389	\N	0	d3c24530-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	0	2	2024-04-23 17:42:17.114389	\N	0	d3c245ee-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	3	0	2024-04-23 17:42:17.114389	\N	0	d3c24684-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	2	2	2024-04-23 17:42:17.114389	\N	0	d3c24710-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	4	3	2024-04-23 17:42:17.114389	\N	0	d3c247e2-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	2b1865c5-25ef-4754-b654-3e34877ef96e	4	3	2024-04-23 17:42:17.114389	\N	0	d3c24896-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	bd0565db-03ab-47df-8792-f929f608d088	2	4	2024-04-23 17:42:17.114389	\N	0	d3c249cc-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	709b5a9a-b435-47c9-abfe-6ff96967686a	1	2	2024-04-23 17:42:17.114389	\N	0	d3c24a80-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	df2d11bf-3749-4eac-bc22-bad13cad4d85	0	1	2024-04-23 17:42:17.114389	\N	0	d3c24b0c-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	096e0ae4-4b80-4f52-9495-9abb10454fcf	4	2	2024-04-23 17:42:17.114389	\N	0	d3c24bac-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	7e0da98b-4e38-41b2-adef-d7f8281700a4	3	4	2024-04-23 17:42:17.114389	\N	0	d3c24c38-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	62266b5d-6d3c-402c-b57b-14a5e74f6a22	2	2	2024-04-23 17:42:17.114389	\N	0	d3c24cc4-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	fa6fb251-d015-40ab-98d8-0d775ef7f086	4	1	2024-04-23 17:42:17.114389	\N	0	d3c24d50-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	0	1	2024-04-23 17:42:17.114389	\N	0	d3c24dd2-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	3	0	2024-04-23 17:42:17.114389	\N	4	d3c24eea-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	3	0	2024-04-23 17:42:17.114389	\N	6	d3c24f6c-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	ccda7052-59f8-4b04-b2f7-220438948978	3	3	2024-04-23 17:42:17.114389	\N	4	d3c24ff8-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	0	2	2024-04-23 17:42:17.114389	\N	0	d3c250b6-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	2	3	2024-04-23 17:42:17.114389	\N	4	d3c2514c-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	3d5d543e-8140-4e08-8be1-4817ea2cff78	3	1	2024-04-23 17:42:21.876427	\N	0	d698ccf2-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	0	3	2024-04-23 17:42:21.876427	\N	0	d698d01c-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	ffafa9a0-070e-40a9-8209-91ad5f701923	2	4	2024-04-23 17:42:21.876427	\N	0	d698d17a-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	3	3	2024-04-23 17:42:21.876427	\N	0	d698d2b0-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	1a903f72-95b8-4ee3-b2af-09266b896ad5	0	4	2024-04-23 17:42:21.876427	\N	0	d698d3f0-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	2	3	2024-04-23 17:42:21.876427	\N	0	d698d81e-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	4	4	2024-04-23 17:42:21.876427	\N	0	d698d990-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	0e03e3ac-af2c-4bef-9248-56af4ba71f61	3	3	2024-04-23 17:42:21.876427	\N	0	d698dabc-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	7564c2f9-bc07-4508-9874-c8b109063be0	1	0	2024-04-23 17:42:21.876427	\N	0	d698dbd4-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	90cd45cd-1d76-44bd-ba8f-788b33716968	2	0	2024-04-23 17:42:21.876427	\N	0	d698dcf6-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	2	2	2024-04-23 17:42:21.876427	\N	0	d698de18-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	fcddb2df-ca24-4547-aea8-0e365e19df5c	0	4	2024-04-23 17:42:21.876427	\N	0	d698df30-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	0	4	2024-04-23 17:42:21.876427	\N	0	d698e052-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	b8137946-bfb6-4b03-9a21-7d3a29cff530	4	4	2024-04-23 17:42:21.876427	\N	0	d698e174-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	931316c1-a124-43cb-836d-e7062c99557c	2	4	2024-04-23 17:42:21.876427	\N	0	d698e296-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	d75cab45-ec3e-4269-b964-b276f9e4badf	0	4	2024-04-23 17:42:21.876427	\N	0	d698e408-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	989cae66-b7a1-4599-a611-671b8673d6d7	4	1	2024-04-23 17:42:21.876427	\N	0	d698e52a-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	4fda6447-4daa-48da-abfb-944b7c5d37ac	3	0	2024-04-23 17:42:21.876427	\N	0	d698e64c-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	0	4	2024-04-23 17:42:21.876427	\N	0	d698e76e-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	36465753-8cc2-47cf-8018-96c409f097d6	4	1	2024-04-23 17:42:21.876427	\N	0	d698e886-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	1c0db01f-0d55-4ee6-978d-7eac43711009	2	2	2024-04-23 17:42:21.876427	\N	0	d698e9b2-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	b8a189d8-7c52-4a94-864c-39a9857416f1	1	2	2024-04-23 17:42:21.876427	\N	0	d698ead4-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	df3f176b-ac53-446e-893f-ed91bf54e9c0	0	4	2024-04-23 17:42:21.876427	\N	0	d698ebf6-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	1	3	2024-04-23 17:42:21.876427	\N	0	d698ed22-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	63cad7c3-1224-4a56-ad32-02be23a38101	0	3	2024-04-23 17:42:21.876427	\N	0	d698f146-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	c3154242-bca6-4c37-9bf0-a49be4a7d424	0	4	2024-04-23 17:42:21.876427	\N	0	d698f2cc-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	f8ca2700-562b-4705-a462-3f32019a054b	2	4	2024-04-23 17:42:21.876427	\N	0	d698f3ee-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	d4e59642-8134-4fd4-b007-f9dc748b8033	1	0	2024-04-23 17:42:21.876427	\N	0	d698f510-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	b6e42279-0b18-46a4-83e0-59a7e1741262	4	0	2024-04-23 17:42:21.876427	\N	0	d698f632-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	4	1	2024-04-23 17:42:21.876427	\N	0	d698f754-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	1	1	2024-04-23 17:42:21.876427	\N	0	d698f86c-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	aa05f762-0d4d-425b-982d-d994baafc6be	2	4	2024-04-23 17:42:21.876427	\N	0	d698f984-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	532917a6-fa6d-4628-a836-b884a3c26153	2	2	2024-04-23 17:42:21.876427	\N	0	d698fb82-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	3	2	2024-04-23 17:42:21.876427	\N	0	d698fe8e-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	4	2	2024-04-23 17:42:21.876427	\N	0	d698ffba-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	0	0	2024-04-23 17:42:21.876427	\N	0	d69900dc-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	1	0	2024-04-23 17:42:21.876427	\N	0	d699023a-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	2b1865c5-25ef-4754-b654-3e34877ef96e	3	0	2024-04-23 17:42:21.876427	\N	0	d6990352-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	bd0565db-03ab-47df-8792-f929f608d088	1	3	2024-04-23 17:42:21.876427	\N	0	d6990500-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	709b5a9a-b435-47c9-abfe-6ff96967686a	4	1	2024-04-23 17:42:21.876427	\N	0	d6990636-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	df2d11bf-3749-4eac-bc22-bad13cad4d85	2	0	2024-04-23 17:42:21.876427	\N	0	d6990758-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	096e0ae4-4b80-4f52-9495-9abb10454fcf	3	3	2024-04-23 17:42:21.876427	\N	0	d6990870-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	7e0da98b-4e38-41b2-adef-d7f8281700a4	2	3	2024-04-23 17:42:21.876427	\N	0	d6990988-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	62266b5d-6d3c-402c-b57b-14a5e74f6a22	4	1	2024-04-23 17:42:21.876427	\N	0	d6990aaa-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	fa6fb251-d015-40ab-98d8-0d775ef7f086	3	0	2024-04-23 17:42:21.876427	\N	0	d6990bc2-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	4	4	2024-04-23 17:42:21.876427	\N	0	d6990cda-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	2	0	2024-04-23 17:42:21.876427	\N	6	d6990f1e-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	3	0	2024-04-23 17:42:21.876427	\N	6	d6991040-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	ccda7052-59f8-4b04-b2f7-220438948978	1	3	2024-04-23 17:42:21.876427	\N	4	d6991162-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	1	2	2024-04-23 17:42:21.876427	\N	0	d69917d4-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	1	2	2024-04-23 17:42:21.876427	\N	4	d699198c-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	3d5d543e-8140-4e08-8be1-4817ea2cff78	3	2	2024-04-23 17:42:26.416517	\N	0	d94d8ad2-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	1	2	2024-04-23 17:42:26.416517	\N	0	d94d9400-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	ffafa9a0-070e-40a9-8209-91ad5f701923	2	0	2024-04-23 17:42:26.416517	\N	0	d94d94c8-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	3	3	2024-04-23 17:42:26.416517	\N	0	d94d955e-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	1a903f72-95b8-4ee3-b2af-09266b896ad5	0	3	2024-04-23 17:42:26.416517	\N	0	d94d95ea-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	1	3	2024-04-23 17:42:26.416517	\N	0	d94d968a-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	3	3	2024-04-23 17:42:26.416517	\N	0	d94d9720-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	0e03e3ac-af2c-4bef-9248-56af4ba71f61	4	2	2024-04-23 17:42:26.416517	\N	0	d94d97ac-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	7564c2f9-bc07-4508-9874-c8b109063be0	0	3	2024-04-23 17:42:26.416517	\N	0	d94d9838-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	90cd45cd-1d76-44bd-ba8f-788b33716968	4	3	2024-04-23 17:42:26.416517	\N	0	d94d9964-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	1	2	2024-04-23 17:42:26.416517	\N	0	d94d9a04-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	fcddb2df-ca24-4547-aea8-0e365e19df5c	2	4	2024-04-23 17:42:26.416517	\N	0	d94d9c34-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	1	4	2024-04-23 17:42:26.416517	\N	0	d94d9cde-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	b8137946-bfb6-4b03-9a21-7d3a29cff530	0	0	2024-04-23 17:42:26.416517	\N	0	d94d9d60-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	931316c1-a124-43cb-836d-e7062c99557c	2	0	2024-04-23 17:42:26.416517	\N	0	d94d9dec-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	d75cab45-ec3e-4269-b964-b276f9e4badf	0	0	2024-04-23 17:42:26.416517	\N	0	d94d9e78-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	989cae66-b7a1-4599-a611-671b8673d6d7	3	0	2024-04-23 17:42:26.416517	\N	0	d94db4f8-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	4fda6447-4daa-48da-abfb-944b7c5d37ac	1	0	2024-04-23 17:42:26.416517	\N	0	d94db598-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	0	2	2024-04-23 17:42:26.416517	\N	0	d94db624-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	36465753-8cc2-47cf-8018-96c409f097d6	2	3	2024-04-23 17:42:26.416517	\N	0	d94db6a6-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	1c0db01f-0d55-4ee6-978d-7eac43711009	1	2	2024-04-23 17:42:26.416517	\N	0	d94db73c-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	b8a189d8-7c52-4a94-864c-39a9857416f1	1	3	2024-04-23 17:42:26.416517	\N	0	d94db7c8-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	df3f176b-ac53-446e-893f-ed91bf54e9c0	3	1	2024-04-23 17:42:26.416517	\N	0	d94db84a-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	0	4	2024-04-23 17:42:26.416517	\N	0	d94db8d6-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	63cad7c3-1224-4a56-ad32-02be23a38101	1	3	2024-04-23 17:42:26.416517	\N	0	d94db962-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	c3154242-bca6-4c37-9bf0-a49be4a7d424	3	1	2024-04-23 17:42:26.416517	\N	0	d94db9e4-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	f8ca2700-562b-4705-a462-3f32019a054b	4	1	2024-04-23 17:42:26.416517	\N	0	d94dba84-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	d4e59642-8134-4fd4-b007-f9dc748b8033	2	0	2024-04-23 17:42:26.416517	\N	0	d94dbb1a-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	b6e42279-0b18-46a4-83e0-59a7e1741262	1	2	2024-04-23 17:42:26.416517	\N	0	d94dbba6-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	2	1	2024-04-23 17:42:26.416517	\N	0	d94dbc32-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	2	3	2024-04-23 17:42:26.416517	\N	0	d94dbcb4-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	aa05f762-0d4d-425b-982d-d994baafc6be	4	3	2024-04-23 17:42:26.416517	\N	0	d94dbd40-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	532917a6-fa6d-4628-a836-b884a3c26153	4	0	2024-04-23 17:42:26.416517	\N	0	d94dbdcc-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	1	2	2024-04-23 17:42:26.416517	\N	0	d94dbe4e-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	0	1	2024-04-23 17:42:26.416517	\N	0	d94dbeda-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	3	3	2024-04-23 17:42:26.416517	\N	0	d94dbf66-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	2	4	2024-04-23 17:42:26.416517	\N	0	d94dbff2-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	2b1865c5-25ef-4754-b654-3e34877ef96e	2	0	2024-04-23 17:42:26.416517	\N	0	d94dc07e-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	bd0565db-03ab-47df-8792-f929f608d088	4	2	2024-04-23 17:42:26.416517	\N	0	d94dc10a-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	709b5a9a-b435-47c9-abfe-6ff96967686a	1	2	2024-04-23 17:42:26.416517	\N	0	d94dc254-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	df2d11bf-3749-4eac-bc22-bad13cad4d85	0	2	2024-04-23 17:42:26.416517	\N	0	d94dc2f4-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	096e0ae4-4b80-4f52-9495-9abb10454fcf	4	0	2024-04-23 17:42:26.416517	\N	0	d94dc380-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	7e0da98b-4e38-41b2-adef-d7f8281700a4	1	3	2024-04-23 17:42:26.416517	\N	0	d94dc40c-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	62266b5d-6d3c-402c-b57b-14a5e74f6a22	4	2	2024-04-23 17:42:26.416517	\N	0	d94dc498-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	fa6fb251-d015-40ab-98d8-0d775ef7f086	3	2	2024-04-23 17:42:26.416517	\N	0	d94dc524-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	0	3	2024-04-23 17:42:26.416517	\N	0	d94dc5ba-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	3	4	2024-04-23 17:42:26.416517	\N	0	d94dc6e6-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	2	3	2024-04-23 17:42:26.416517	\N	0	d94dc772-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	ccda7052-59f8-4b04-b2f7-220438948978	4	4	2024-04-23 17:42:26.416517	\N	4	d94dc7fe-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	1	0	2024-04-23 17:42:26.416517	\N	4	d94dc88a-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	3	2	2024-04-23 17:42:26.416517	\N	4	d94dc90c-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	3d5d543e-8140-4e08-8be1-4817ea2cff78	3	1	2024-04-23 17:42:31.037686	\N	0	dc0eacec-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	1	1	2024-04-23 17:42:31.037686	\N	0	dc0eb124-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	ffafa9a0-070e-40a9-8209-91ad5f701923	3	0	2024-04-23 17:42:31.037686	\N	0	dc0eb1ce-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	3	1	2024-04-23 17:42:31.037686	\N	0	dc0eb264-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	1a903f72-95b8-4ee3-b2af-09266b896ad5	0	2	2024-04-23 17:42:31.037686	\N	0	dc0eb304-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	709b5a9a-b435-47c9-abfe-6ff96967686a	1	1	2024-04-23 17:42:31.037686	\N	0	dc0ecc68-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	df2d11bf-3749-4eac-bc22-bad13cad4d85	2	0	2024-04-23 17:42:31.037686	\N	0	dc0eccf4-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	096e0ae4-4b80-4f52-9495-9abb10454fcf	2	1	2024-04-23 17:42:31.037686	\N	0	dc0ecd80-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	7e0da98b-4e38-41b2-adef-d7f8281700a4	4	2	2024-04-23 17:42:31.037686	\N	0	dc0ece02-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	62266b5d-6d3c-402c-b57b-14a5e74f6a22	4	2	2024-04-23 17:42:31.037686	\N	0	dc0ece84-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	fa6fb251-d015-40ab-98d8-0d775ef7f086	1	1	2024-04-23 17:42:31.037686	\N	0	dc0ecf10-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	4	1	2024-04-23 17:42:31.037686	\N	0	dc0ecf92-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	3	4	2024-04-23 17:42:31.037686	\N	0	dc0ed0aa-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	3	4	2024-04-23 17:42:31.037686	\N	0	dc0edf82-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	ccda7052-59f8-4b04-b2f7-220438948978	1	3	2024-04-23 17:42:31.037686	\N	4	dc0ee086-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	1	3	2024-04-23 17:42:31.037686	\N	0	dc0ee11c-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	2	1	2024-04-23 17:42:31.037686	\N	4	dc0ee1bc-0198-11ef-b991-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	0e03e3ac-af2c-4bef-9248-56af4ba71f61	\N	\N	2024-05-14 21:15:17.633943	\N	0	10398e02-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	7564c2f9-bc07-4508-9874-c8b109063be0	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039983e-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	90cd45cd-1d76-44bd-ba8f-788b33716968	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399884-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	\N	\N	2024-05-14 21:15:17.633943	\N	0	103998b6-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	fcddb2df-ca24-4547-aea8-0e365e19df5c	\N	\N	2024-05-14 21:15:17.633943	\N	0	103998e8-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399924-1237-11ef-bcd3-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	709b5a9a-b435-47c9-abfe-6ff96967686a	3	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.335392	0	bb23744e-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	df2d11bf-3749-4eac-bc22-bad13cad4d85	1	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.338986	0	bb237566-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	096e0ae4-4b80-4f52-9495-9abb10454fcf	1	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.346053	0	bb2376ec-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	7e0da98b-4e38-41b2-adef-d7f8281700a4	0	4	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.349553	0	bb237908-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	62266b5d-6d3c-402c-b57b-14a5e74f6a22	4	2	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.352603	0	bb237a20-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	fa6fb251-d015-40ab-98d8-0d775ef7f086	0	3	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.359755	0	bb237b1a-fcbc-11ee-84e7-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	1	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.363478	0	bb237cfa-fcbc-11ee-84e7-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	3d5d543e-8140-4e08-8be1-4817ea2cff78	4	4	2024-04-22 15:55:55.501072	\N	0	cd9c7bc2-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	9557bcf0-e8ef-49a0-9ef3-57ace2541f84	4	3	2024-04-22 15:55:55.501072	\N	0	cd9c83ec-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	ffafa9a0-070e-40a9-8209-91ad5f701923	3	0	2024-04-22 15:55:55.501072	\N	0	cd9c8496-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	0	2	2024-04-22 15:55:55.501072	\N	0	cd9c852c-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	1a903f72-95b8-4ee3-b2af-09266b896ad5	3	0	2024-04-22 15:55:55.501072	\N	0	cd9c85c2-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	0	2	2024-04-22 15:55:55.501072	\N	0	cd9c8644-00c0-11ef-93ee-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	4	3	2024-04-22 15:55:55.501072	\N	0	cd9c86d0-00c0-11ef-93ee-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	b8137946-bfb6-4b03-9a21-7d3a29cff530	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399956-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	931316c1-a124-43cb-836d-e7062c99557c	\N	\N	2024-05-14 21:15:17.633943	\N	0	103999b0-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	d75cab45-ec3e-4269-b964-b276f9e4badf	\N	\N	2024-05-14 21:15:17.633943	\N	0	103999e2-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	989cae66-b7a1-4599-a611-671b8673d6d7	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399a14-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	4fda6447-4daa-48da-abfb-944b7c5d37ac	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399a46-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399ad2-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	36465753-8cc2-47cf-8018-96c409f097d6	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399b0e-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	1c0db01f-0d55-4ee6-978d-7eac43711009	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399b40-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	b8a189d8-7c52-4a94-864c-39a9857416f1	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399b72-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	df3f176b-ac53-446e-893f-ed91bf54e9c0	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399be0-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399c30-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	63cad7c3-1224-4a56-ad32-02be23a38101	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399cb2-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	c3154242-bca6-4c37-9bf0-a49be4a7d424	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399ce4-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	f8ca2700-562b-4705-a462-3f32019a054b	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399d16-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	d4e59642-8134-4fd4-b007-f9dc748b8033	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399d48-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	b6e42279-0b18-46a4-83e0-59a7e1741262	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399d7a-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399dac-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399dde-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	aa05f762-0d4d-425b-982d-d994baafc6be	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399e10-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	532917a6-fa6d-4628-a836-b884a3c26153	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399f0a-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	\N	\N	2024-05-14 21:15:17.633943	\N	0	10399f64-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a0a4-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a0f4-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a126-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	2b1865c5-25ef-4754-b654-3e34877ef96e	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a158-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	bd0565db-03ab-47df-8792-f929f608d088	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a18a-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	709b5a9a-b435-47c9-abfe-6ff96967686a	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a1b2-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	df2d11bf-3749-4eac-bc22-bad13cad4d85	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a1e4-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	096e0ae4-4b80-4f52-9495-9abb10454fcf	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a216-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	7e0da98b-4e38-41b2-adef-d7f8281700a4	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a248-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	62266b5d-6d3c-402c-b57b-14a5e74f6a22	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a27a-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	fa6fb251-d015-40ab-98d8-0d775ef7f086	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a2ac-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	12a8ad6a-5c12-4db9-a235-5d85c9234ac2	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a324-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a388-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a3ba-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	ccda7052-59f8-4b04-b2f7-220438948978	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a3ec-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a41e-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	04a5d3f2-0b13-4805-8faf-6a2a49c3f245	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a450-1237-11ef-bcd3-0242ac130002
ff58fd37-30dc-4f24-858b-142530cebc49	6aff221d-8741-40c9-b18a-7f87857d6827	\N	\N	2024-05-14 21:15:17.633943	\N	0	1039a356-1237-11ef-bcd3-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	6aff221d-8741-40c9-b18a-7f87857d6827	1	0	2024-04-17 13:16:41.869998	2024-04-21 19:14:02.119793	4	bb2385e2-fcbc-11ee-84e7-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	6aff221d-8741-40c9-b18a-7f87857d6827	0	0	2024-04-22 15:34:11.445734	\N	4	c4565eb4-00bd-11ef-9729-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	6aff221d-8741-40c9-b18a-7f87857d6827	0	0	2024-04-22 15:38:57.690591	\N	4	6ef1fcf2-00be-11ef-9729-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	6aff221d-8741-40c9-b18a-7f87857d6827	0	3	2024-04-22 15:55:55.501072	\N	0	cd9ca32c-00c0-11ef-93ee-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	6aff221d-8741-40c9-b18a-7f87857d6827	1	1	2024-04-22 15:56:00.604451	\N	4	d0a651d0-00c0-11ef-93ee-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	6aff221d-8741-40c9-b18a-7f87857d6827	2	0	2024-04-23 17:42:11.221197	\N	8	d042a86e-0198-11ef-b991-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	6aff221d-8741-40c9-b18a-7f87857d6827	4	2	2024-04-23 17:42:17.114389	\N	6	d3c24e5e-0198-11ef-b991-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	6aff221d-8741-40c9-b18a-7f87857d6827	1	3	2024-04-23 17:42:21.876427	\N	0	d6990dfc-0198-11ef-b991-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	6aff221d-8741-40c9-b18a-7f87857d6827	4	2	2024-04-23 17:42:26.416517	\N	6	d94dc650-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	6aff221d-8741-40c9-b18a-7f87857d6827	0	3	2024-04-23 17:42:31.037686	\N	0	dc0ed01e-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	716ef5b4-a553-4800-afe1-e3ca6a4a75b3	0	4	2024-04-23 17:42:31.037686	\N	0	dc0eb39a-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	0b2a8567-5e94-472f-8e0f-fa9fa13397d9	4	4	2024-04-23 17:42:31.037686	\N	0	dc0eb426-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	0e03e3ac-af2c-4bef-9248-56af4ba71f61	1	2	2024-04-23 17:42:31.037686	\N	0	dc0eb4a8-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	7564c2f9-bc07-4508-9874-c8b109063be0	1	1	2024-04-23 17:42:31.037686	\N	0	dc0eb53e-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	90cd45cd-1d76-44bd-ba8f-788b33716968	2	0	2024-04-23 17:42:31.037686	\N	0	dc0eb5c0-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	2	2	2024-04-23 17:42:31.037686	\N	0	dc0eb714-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	fcddb2df-ca24-4547-aea8-0e365e19df5c	4	4	2024-04-23 17:42:31.037686	\N	0	dc0eb7b4-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	4	1	2024-04-23 17:42:31.037686	\N	0	dc0eb840-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	b8137946-bfb6-4b03-9a21-7d3a29cff530	1	2	2024-04-23 17:42:31.037686	\N	0	dc0eb8c2-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	931316c1-a124-43cb-836d-e7062c99557c	3	1	2024-04-23 17:42:31.037686	\N	0	dc0eb94e-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	d75cab45-ec3e-4269-b964-b276f9e4badf	0	4	2024-04-23 17:42:31.037686	\N	0	dc0eb9da-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	989cae66-b7a1-4599-a611-671b8673d6d7	0	1	2024-04-23 17:42:31.037686	\N	0	dc0eba70-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	4fda6447-4daa-48da-abfb-944b7c5d37ac	3	1	2024-04-23 17:42:31.037686	\N	0	dc0ebafc-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	2	2	2024-04-23 17:42:31.037686	\N	0	dc0ebc50-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	36465753-8cc2-47cf-8018-96c409f097d6	0	0	2024-04-23 17:42:31.037686	\N	0	dc0ebcf0-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	1c0db01f-0d55-4ee6-978d-7eac43711009	1	0	2024-04-23 17:42:31.037686	\N	0	dc0ebd9a-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	b8a189d8-7c52-4a94-864c-39a9857416f1	2	4	2024-04-23 17:42:31.037686	\N	0	dc0ebe30-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	df3f176b-ac53-446e-893f-ed91bf54e9c0	1	0	2024-04-23 17:42:31.037686	\N	0	dc0ebebc-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	4	0	2024-04-23 17:42:31.037686	\N	0	dc0ebf48-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	63cad7c3-1224-4a56-ad32-02be23a38101	4	2	2024-04-23 17:42:31.037686	\N	0	dc0ebfd4-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	c3154242-bca6-4c37-9bf0-a49be4a7d424	1	3	2024-04-23 17:42:31.037686	\N	0	dc0ec06a-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	f8ca2700-562b-4705-a462-3f32019a054b	1	4	2024-04-23 17:42:31.037686	\N	0	dc0ec100-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	d4e59642-8134-4fd4-b007-f9dc748b8033	0	3	2024-04-23 17:42:31.037686	\N	0	dc0ec18c-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	b6e42279-0b18-46a4-83e0-59a7e1741262	2	3	2024-04-23 17:42:31.037686	\N	0	dc0ec20e-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	3	2	2024-04-23 17:42:31.037686	\N	0	dc0ec2a4-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	2	0	2024-04-23 17:42:31.037686	\N	0	dc0ec326-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	aa05f762-0d4d-425b-982d-d994baafc6be	1	1	2024-04-23 17:42:31.037686	\N	0	dc0ec3b2-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	532917a6-fa6d-4628-a836-b884a3c26153	3	1	2024-04-23 17:42:31.037686	\N	0	dc0ec43e-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	0b23ce45-dbd5-4745-8b39-2a85a10cabc1	2	0	2024-04-23 17:42:31.037686	\N	0	dc0ec4ca-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	3	2	2024-04-23 17:42:31.037686	\N	0	dc0ec556-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	bb8a6b95-7bdc-4eb0-8488-2b75697f5638	2	2	2024-04-23 17:42:31.037686	\N	0	dc0ec5d8-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	4	2	2024-04-23 17:42:31.037686	\N	0	dc0ec696-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	2b1865c5-25ef-4754-b654-3e34877ef96e	0	2	2024-04-23 17:42:31.037686	\N	0	dc0ecb32-0198-11ef-b991-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	bd0565db-03ab-47df-8792-f929f608d088	4	2	2024-04-23 17:42:31.037686	\N	0	dc0ecbc8-0198-11ef-b991-0242ac130002
\.


--
-- TOC entry 3439 (class 0 OID 24594)
-- Dependencies: 220
-- Data for Name: communities; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.communities (id, name, created_at) FROM stdin;
aacab946-e5ba-4fb4-8108-8857136f9b18	SE Elite	2024-04-22 18:01:18.935679
5336c0c8-5f82-40af-8a77-fd38706c33c9	FIM	2024-04-23 06:22:34.842254
87c9351e-87d1-4111-baac-7d1b1545217c	Check24	2024-04-23 16:58:04.384706
0103b9e6-43d2-4263-a1a9-e09819ef0f1b	Testcommunity	2024-05-13 15:06:56.096724
407ae8e6-12b8-11ef-9489-0242ac130002	Beste Tipper	2024-05-15 12:40:03.680688
407be502-12b8-11ef-9489-0242ac130002	Arbeitsgruppe	2024-05-15 12:40:03.680688
\.


--
-- TOC entry 3441 (class 0 OID 24634)
-- Dependencies: 222
-- Data for Name: friends; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.friends (id, user_id, friend_id) FROM stdin;
089e5c38-0084-424c-93d6-d5191706cd28	92ffea16-848c-45fc-887b-7a713203caf9	1904e204-0a11-4ebb-9e1e-2af3d0667a80
026b2887-2274-4aeb-8b99-53c15ae8c88a	92ffea16-848c-45fc-887b-7a713203caf9	2fa0908f-6b1f-4d27-aa90-cad32947ca43
\.


--
-- TOC entry 3437 (class 0 OID 16412)
-- Dependencies: 217
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.matches (id, team_home_name, team_away_name, game_starts_at, team_home_goals, team_away_goals) FROM stdin;
3d5d543e-8140-4e08-8be1-4817ea2cff78	1D	2	2024-07-02 19:00:00	\N	\N
9557bcf0-e8ef-49a0-9ef3-57ace2541f84	Serbien	England	2024-06-16 19:00:00	\N	\N
ffafa9a0-070e-40a9-8209-91ad5f701923	Rumänien	tbd	2024-06-17 13:00:00	\N	\N
61c1e32b-c501-43f3-a8b5-d9bc4b1390f8	Belgien	Slowakei	2024-06-17 16:00:00	\N	\N
1a903f72-95b8-4ee3-b2af-09266b896ad5	Österreich	Frankreich	2024-06-17 19:00:00	\N	\N
716ef5b4-a553-4800-afe1-e3ca6a4a75b3	Türkei	tbd	2024-06-18 16:00:00	\N	\N
0b2a8567-5e94-472f-8e0f-fa9fa13397d9	Portugal	Tschechische Republik	2024-06-18 19:00:00	\N	\N
0e03e3ac-af2c-4bef-9248-56af4ba71f61	Kroatien	Albanien	2024-06-19 13:00:00	\N	\N
7564c2f9-bc07-4508-9874-c8b109063be0	Deutschland	Ungarn	2024-06-19 16:00:00	\N	\N
90cd45cd-1d76-44bd-ba8f-788b33716968	Schottland	Schweiz	2024-06-19 19:00:00	\N	\N
74acd2f4-ec6f-4dd6-976f-f5c2d39d8f67	Slowenien	Serbien	2024-06-20 13:00:00	\N	\N
fcddb2df-ca24-4547-aea8-0e365e19df5c	Dänemark	England	2024-06-20 16:00:00	\N	\N
cb0c2af4-d4b4-426a-bdfb-dc84d22f4694	Spanien	Italien	2024-06-20 19:00:00	\N	\N
b8137946-bfb6-4b03-9a21-7d3a29cff530	Slowakei	tbd	2024-06-21 13:00:00	\N	\N
931316c1-a124-43cb-836d-e7062c99557c	tbd	Österreich	2024-06-21 16:00:00	\N	\N
d75cab45-ec3e-4269-b964-b276f9e4badf	Niederlande	Frankreich	2024-06-21 19:00:00	\N	\N
989cae66-b7a1-4599-a611-671b8673d6d7	tbd	Tschechische Republik	2024-06-22 13:00:00	\N	\N
4fda6447-4daa-48da-abfb-944b7c5d37ac	Türkei	Portugal	2024-06-22 16:00:00	\N	\N
78a463b9-3913-47b4-9dc5-e1b1ced2aaaf	Belgien	Rumänien	2024-06-22 19:00:00	\N	\N
36465753-8cc2-47cf-8018-96c409f097d6	Schottland	Ungarn	2024-06-23 19:00:00	\N	\N
1c0db01f-0d55-4ee6-978d-7eac43711009	Schweiz	Deutschland	2024-06-23 19:00:00	\N	\N
b8a189d8-7c52-4a94-864c-39a9857416f1	Albanien	Spanien	2024-06-24 19:00:00	\N	\N
df3f176b-ac53-446e-893f-ed91bf54e9c0	Kroatien	Italien	2024-06-24 19:00:00	\N	\N
d52db5d8-79fb-4bdc-af1e-bf98a269cb6a	Niederlande	Österreich	2024-06-25 16:00:00	\N	\N
63cad7c3-1224-4a56-ad32-02be23a38101	Frankreich	tbd	2024-06-25 16:00:00	\N	\N
c3154242-bca6-4c37-9bf0-a49be4a7d424	England	Slowenien	2024-06-25 19:00:00	\N	\N
f8ca2700-562b-4705-a462-3f32019a054b	Dänemark	Serbien	2024-06-25 19:00:00	\N	\N
d4e59642-8134-4fd4-b007-f9dc748b8033	Slowakei	Rumänien	2024-06-26 16:00:00	\N	\N
b6e42279-0b18-46a4-83e0-59a7e1741262	tbd	Belgien	2024-06-26 16:00:00	\N	\N
f87e59b6-44de-4db8-b86d-9f7cdd2a5d03	tbd	Portugal	2024-06-26 19:00:00	\N	\N
0db36318-ebe2-4a99-a6ad-c6bbdf37d77a	Tschechische Republik	Türkei	2024-06-26 19:00:00	\N	\N
aa05f762-0d4d-425b-982d-d994baafc6be	2A	2B	2024-06-29 16:00:00	\N	\N
532917a6-fa6d-4628-a836-b884a3c26153	1A	2C	2024-06-29 19:00:00	\N	\N
0b23ce45-dbd5-4745-8b39-2a85a10cabc1	1C	3EDF	2024-06-30 16:00:00	\N	\N
4e52a91f-09b1-4b71-8ac9-d70eaa2f3564	1B	ADEF	2024-06-30 19:00:00	\N	\N
bb8a6b95-7bdc-4eb0-8488-2b75697f5638	2D	2E	2024-07-01 16:00:00	\N	\N
8cc8b0e5-72d3-453e-b4de-79fa4485bb9d	1F	3ABC	2024-07-01 19:00:00	\N	\N
2b1865c5-25ef-4754-b654-3e34877ef96e	1E	ABCD	2024-07-02 16:00:00	\N	\N
bd0565db-03ab-47df-8792-f929f608d088	1D	2F	2024-07-02 19:00:00	\N	\N
709b5a9a-b435-47c9-abfe-6ff96967686a	W39	W37	2024-07-05 16:00:00	\N	\N
df2d11bf-3749-4eac-bc22-bad13cad4d85	W41	W42	2024-07-05 19:00:00	\N	\N
096e0ae4-4b80-4f52-9495-9abb10454fcf	W40	W38	2024-07-06 16:00:00	\N	\N
7e0da98b-4e38-41b2-adef-d7f8281700a4	W43	W44	2024-07-06 19:00:00	\N	\N
62266b5d-6d3c-402c-b57b-14a5e74f6a22	W45	W46	2024-07-09 19:00:00	\N	\N
fa6fb251-d015-40ab-98d8-0d775ef7f086	W47	W48	2024-07-10 19:00:00	\N	\N
12a8ad6a-5c12-4db9-a235-5d85c9234ac2	W49	W50	2024-07-14 19:00:00	\N	\N
3a5f6766-86a6-4d2e-8fc7-f78a96ab51c5	Ungarn	Schweiz	2024-06-15 13:00:00	3	1
04e75a6f-e2d8-438a-bfb4-d5d7e0edeb36	Spanien	Kroatien	2024-06-15 16:00:00	4	1
ccda7052-59f8-4b04-b2f7-220438948978	Italien	Albanien	2024-06-15 19:00:00	2	2
c1ea2786-1d7e-4ab6-829f-5bcf8ed122c7	tbd	Niederlande	2024-06-16 13:00:00	5	1
04a5d3f2-0b13-4805-8faf-6a2a49c3f245	Slowenien	Dänemark	2024-06-16 16:00:00	0	0
6aff221d-8741-40c9-b18a-7f87857d6827	Deutschland	Schottland	2024-06-14 19:00:00	2	0
\.


--
-- TOC entry 3440 (class 0 OID 24603)
-- Dependencies: 221
-- Data for Name: user_community; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.user_community (user_id, community_id, id) FROM stdin;
92ffea16-848c-45fc-887b-7a713203caf9	87c9351e-87d1-4111-baac-7d1b1545217c	50e77ad6-1214-11ef-a825-0242ac130002
45ec5e7e-93e7-4c7a-8b44-25591ef66840	87c9351e-87d1-4111-baac-7d1b1545217c	50e7987c-1214-11ef-a825-0242ac130002
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	87c9351e-87d1-4111-baac-7d1b1545217c	50e79944-1214-11ef-a825-0242ac130002
2fa0908f-6b1f-4d27-aa90-cad32947ca43	87c9351e-87d1-4111-baac-7d1b1545217c	50e799d0-1214-11ef-a825-0242ac130002
b1f957bb-4924-46a2-90d8-25d29c0618a9	87c9351e-87d1-4111-baac-7d1b1545217c	50e79a66-1214-11ef-a825-0242ac130002
9dff5a86-4eb9-47d2-95e6-079b80a9f844	87c9351e-87d1-4111-baac-7d1b1545217c	50e79af2-1214-11ef-a825-0242ac130002
006bff5b-283e-4d5d-827e-daf27c652b76	87c9351e-87d1-4111-baac-7d1b1545217c	50e79b92-1214-11ef-a825-0242ac130002
74468584-81fc-4c0e-9c3c-4da37f6da36b	87c9351e-87d1-4111-baac-7d1b1545217c	50e79e08-1214-11ef-a825-0242ac130002
4fbf56eb-330a-4fe4-afd8-293ed13907d7	87c9351e-87d1-4111-baac-7d1b1545217c	50e79eb2-1214-11ef-a825-0242ac130002
1904e204-0a11-4ebb-9e1e-2af3d0667a80	87c9351e-87d1-4111-baac-7d1b1545217c	50e79f3e-1214-11ef-a825-0242ac130002
92ffea16-848c-45fc-887b-7a713203caf9	407be502-12b8-11ef-9489-0242ac130002	6b5e297e-744d-480e-b52b-ff0683ffe6d7
92ffea16-848c-45fc-887b-7a713203caf9	aacab946-e5ba-4fb4-8108-8857136f9b18	4804d974-f562-49ff-9eec-bdab0a923099
\.


--
-- TOC entry 3436 (class 0 OID 16389)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.users (id, name, created_at) FROM stdin;
92ffea16-848c-45fc-887b-7a713203caf9	testbets	2024-04-17 13:16:41.770827
45ec5e7e-93e7-4c7a-8b44-25591ef66840	simon	2024-04-22 15:34:11.426904
8b69ea1e-47bf-448b-b2e5-a8ef44b0fdc0	suppertipper	2024-04-22 15:38:57.685045
2fa0908f-6b1f-4d27-aa90-cad32947ca43	user1	2024-04-22 15:55:55.489267
b1f957bb-4924-46a2-90d8-25d29c0618a9	user2	2024-04-22 15:56:00.602482
9dff5a86-4eb9-47d2-95e6-079b80a9f844	user3	2024-04-23 17:42:11.189707
006bff5b-283e-4d5d-827e-daf27c652b76	user4	2024-04-23 17:42:17.110787
74468584-81fc-4c0e-9c3c-4da37f6da36b	user5	2024-04-23 17:42:21.867621
4fbf56eb-330a-4fe4-afd8-293ed13907d7	user6	2024-04-23 17:42:26.409396
1904e204-0a11-4ebb-9e1e-2af3d0667a80	user7	2024-04-23 17:42:31.030697
ff58fd37-30dc-4f24-858b-142530cebc49	newUSER	2024-05-14 21:15:17.51338
\.


--
-- TOC entry 3266 (class 2606 OID 16394)
-- Name: users User_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- TOC entry 3268 (class 2606 OID 24583)
-- Name: users benutzer_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT benutzer_name_key UNIQUE (name);


--
-- TOC entry 3272 (class 2606 OID 16445)
-- Name: bets bets_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT bets_pk PRIMARY KEY (id);


--
-- TOC entry 3274 (class 2606 OID 24601)
-- Name: communities communities_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.communities
    ADD CONSTRAINT communities_pk PRIMARY KEY (id);


--
-- TOC entry 3280 (class 2606 OID 24639)
-- Name: friends friends_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_pk PRIMARY KEY (id);


--
-- TOC entry 3270 (class 2606 OID 16419)
-- Name: matches matches_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pk PRIMARY KEY (id);


--
-- TOC entry 3276 (class 2606 OID 24683)
-- Name: user_community only_once_in_community; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_community
    ADD CONSTRAINT only_once_in_community UNIQUE (user_id, community_id);


--
-- TOC entry 3282 (class 2606 OID 24651)
-- Name: friends unique_user_friend_combination; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT unique_user_friend_combination UNIQUE (user_id, friend_id);


--
-- TOC entry 3278 (class 2606 OID 24621)
-- Name: user_community user_community_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_community
    ADD CONSTRAINT user_community_pk PRIMARY KEY (id);


--
-- TOC entry 3433 (class 2618 OID 24592)
-- Name: points_per_user _RETURN; Type: RULE; Schema: public; Owner: admin
--

CREATE OR REPLACE VIEW public.points_per_user AS
 SELECT u.id,
    u.name,
    COALESCE(sum(b.points), (0)::bigint) AS total_points,
    u.created_at
   FROM (public.users u
     LEFT JOIN public.bets b ON ((u.id = b.user_id)))
  GROUP BY u.id, u.name;


--
-- TOC entry 3289 (class 2620 OID 24695)
-- Name: user_community check_max_communities; Type: TRIGGER; Schema: public; Owner: admin
--

CREATE TRIGGER check_max_communities BEFORE INSERT OR UPDATE ON public.user_community FOR EACH ROW EXECUTE FUNCTION public.enforce_max_communities();


--
-- TOC entry 3283 (class 2606 OID 16429)
-- Name: bets Bets_Matches_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT "Bets_Matches_id_fk" FOREIGN KEY (match_id) REFERENCES public.matches(id);


--
-- TOC entry 3284 (class 2606 OID 24577)
-- Name: bets bets_benutzer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.bets
    ADD CONSTRAINT bets_benutzer_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3287 (class 2606 OID 24640)
-- Name: friends friends_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3288 (class 2606 OID 24645)
-- Name: friends friends_users_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_users_id_fk_2 FOREIGN KEY (friend_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3285 (class 2606 OID 24611)
-- Name: user_community user_community_communities_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_community
    ADD CONSTRAINT user_community_communities_id_fk FOREIGN KEY (community_id) REFERENCES public.communities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3286 (class 2606 OID 24606)
-- Name: user_community user_community_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_community
    ADD CONSTRAINT user_community_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3443 (class 0 OID 24710)
-- Dependencies: 224 3445
-- Name: community_view; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: admin
--

REFRESH MATERIALIZED VIEW public.community_view;


--
-- TOC entry 3442 (class 0 OID 24706)
-- Dependencies: 223 3445
-- Name: leaderboard; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: admin
--

REFRESH MATERIALIZED VIEW public.leaderboard;


-- Completed on 2024-05-26 19:29:44 CEST

--
-- PostgreSQL database dump complete
--

