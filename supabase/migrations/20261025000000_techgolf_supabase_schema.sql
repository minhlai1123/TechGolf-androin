-- ============================================================================
-- TECHGOLF SUPABASE DATABASE SCHEMA
-- Compatible with Supabase PostgreSQL 15+, PostGIS, Supabase Auth & Realtime
-- Source of Truth: App Chơi Golf Hole19 - 28-sep-2026.pdf
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. ENUMS & DOMAINS
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('USER', 'ADMIN');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE course_status AS ENUM ('ACTIVE', 'INACTIVE', 'MAINTENANCE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE polygon_type AS ENUM ('FAIRWAY', 'ROUGH', 'GREEN', 'BUNKER', 'WATER_HAZARD', 'TEE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE game_mode AS ENUM ('STROKE_PLAY', 'STABLEFORD', 'MATCH_PLAY', 'SCRAMBLE', 'FOUR_BALL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE round_status AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE fairway_hit AS ENUM ('LEFT', 'STRAIGHT', 'RIGHT');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE shot_status AS ENUM ('READY', 'STARTED', 'SAVED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE distance_unit AS ENUM ('YARDS', 'METERS');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. PROFILES TABLE (Linked with Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    handicap_index NUMERIC(4, 1) DEFAULT 54.0,
    role user_role NOT NULL DEFAULT 'USER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- 4. GOLF BAG CLUBS TABLE
CREATE TABLE IF NOT EXISTS public.golf_bag_clubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    club_type TEXT NOT NULL,
    custom_name TEXT,
    average_distance_meters NUMERIC(5, 1) NOT NULL DEFAULT 0.0,
    total_shots_recorded INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_golf_bag_clubs_user_id ON public.golf_bag_clubs(user_id);

-- 5. COURSES TABLE
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    country TEXT NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    location GEOMETRY(Point, 4326),
    timezone TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    total_holes INT NOT NULL DEFAULT 18,
    description TEXT,
    status course_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_courses_name ON public.courses(name);
CREATE INDEX IF NOT EXISTS idx_courses_city ON public.courses(city);
CREATE INDEX IF NOT EXISTS idx_courses_location ON public.courses USING GIST (location);

-- 6. COURSE TEES TABLE
CREATE TABLE IF NOT EXISTS public.course_tees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    rating NUMERIC(4, 1) NOT NULL,
    slope_rating INT NOT NULL,
    total_yardage INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_course_tees_course_id ON public.course_tees(course_id);

-- 7. HOLES TABLE
CREATE TABLE IF NOT EXISTS public.holes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    hole_number INT NOT NULL,
    par INT NOT NULL,
    handicap_index INT NOT NULL,
    green_center GEOMETRY(Point, 4326),
    green_front GEOMETRY(Point, 4326),
    green_back GEOMETRY(Point, 4326),
    green_center_lat DOUBLE PRECISION,
    green_center_lng DOUBLE PRECISION,
    green_front_lat DOUBLE PRECISION,
    green_front_lng DOUBLE PRECISION,
    green_back_lat DOUBLE PRECISION,
    green_back_lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_holes_course_hole_number UNIQUE (course_id, hole_number)
);

CREATE INDEX IF NOT EXISTS idx_holes_course_id ON public.holes(course_id);
CREATE INDEX IF NOT EXISTS idx_holes_green_center ON public.holes USING GIST (green_center);

-- 8. HOLE TEES TABLE
CREATE TABLE IF NOT EXISTS public.hole_tees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hole_id UUID NOT NULL REFERENCES public.holes(id) ON DELETE CASCADE,
    course_tee_id UUID NOT NULL REFERENCES public.course_tees(id) ON DELETE CASCADE,
    tee_position GEOMETRY(Point, 4326),
    tee_lat DOUBLE PRECISION,
    tee_lng DOUBLE PRECISION,
    distance_meters INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_hole_tees_hole_course_tee UNIQUE (hole_id, course_tee_id)
);

CREATE INDEX IF NOT EXISTS idx_hole_tees_hole_id ON public.hole_tees(hole_id);
CREATE INDEX IF NOT EXISTS idx_hole_tees_course_tee_id ON public.hole_tees(course_tee_id);

-- 9. HOLE POLYGONS TABLE
CREATE TABLE IF NOT EXISTS public.hole_polygons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hole_id UUID NOT NULL REFERENCES public.holes(id) ON DELETE CASCADE,
    polygon_type polygon_type NOT NULL,
    geometry GEOMETRY(Polygon, 4326) NOT NULL,
    geojson JSONB,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hole_polygons_hole_id ON public.hole_polygons(hole_id);
CREATE INDEX IF NOT EXISTS idx_hole_polygons_geometry ON public.hole_polygons USING GIST (geometry);

-- 10. ROUNDS TABLE
CREATE TABLE IF NOT EXISTS public.rounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    game_mode game_mode NOT NULL DEFAULT 'STROKE_PLAY',
    status round_status NOT NULL DEFAULT 'NOT_STARTED',
    current_hole INT NOT NULL DEFAULT 1,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rounds_course_id ON public.rounds(course_id);
CREATE INDEX IF NOT EXISTS idx_rounds_created_by ON public.rounds(created_by);
CREATE INDEX IF NOT EXISTS idx_rounds_status ON public.rounds(status);

-- 11. ROUND PLAYERS TABLE
CREATE TABLE IF NOT EXISTS public.round_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id UUID NOT NULL REFERENCES public.rounds(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    tee_id UUID REFERENCES public.course_tees(id) ON DELETE SET NULL,
    player_name TEXT NOT NULL,
    player_order INT NOT NULL CHECK (player_order >= 1 AND player_order <= 4),
    team_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_round_players_round_order UNIQUE (round_id, player_order)
);

CREATE INDEX IF NOT EXISTS idx_round_players_round_id ON public.round_players(round_id);
CREATE INDEX IF NOT EXISTS idx_round_players_user_id ON public.round_players(user_id);

-- 12. ROUND SCORES TABLE
CREATE TABLE IF NOT EXISTS public.round_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id UUID NOT NULL REFERENCES public.rounds(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES public.round_players(id) ON DELETE CASCADE,
    hole_id UUID NOT NULL REFERENCES public.holes(id) ON DELETE CASCADE,
    gross_score INT NOT NULL CHECK (gross_score > 0),
    putts INT NOT NULL DEFAULT 0 CHECK (putts >= 0 AND putts <= gross_score),
    penalties INT NOT NULL DEFAULT 0 CHECK (penalties >= 0),
    fairway_hit fairway_hit,
    gir BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_round_scores_round_player_hole UNIQUE (round_id, player_id, hole_id)
);

CREATE INDEX IF NOT EXISTS idx_round_scores_round_id ON public.round_scores(round_id);
CREATE INDEX IF NOT EXISTS idx_round_scores_player_id ON public.round_scores(player_id);
CREATE INDEX IF NOT EXISTS idx_round_scores_hole_id ON public.round_scores(hole_id);

-- 13. SHOTS TABLE
CREATE TABLE IF NOT EXISTS public.shots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id UUID NOT NULL REFERENCES public.rounds(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES public.round_players(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    hole_id UUID NOT NULL REFERENCES public.holes(id) ON DELETE CASCADE,
    club_id UUID REFERENCES public.golf_bag_clubs(id) ON DELETE SET NULL,
    status shot_status NOT NULL DEFAULT 'STARTED',
    start_latitude DOUBLE PRECISION NOT NULL,
    start_longitude DOUBLE PRECISION NOT NULL,
    start_elevation DOUBLE PRECISION,
    end_latitude DOUBLE PRECISION,
    end_longitude DOUBLE PRECISION,
    end_elevation DOUBLE PRECISION,
    elevation_delta DOUBLE PRECISION,
    distance DOUBLE PRECISION,
    distance_unit distance_unit NOT NULL DEFAULT 'YARDS',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shots_round_id ON public.shots(round_id);
CREATE INDEX IF NOT EXISTS idx_shots_player_id ON public.shots(player_id);
CREATE INDEX IF NOT EXISTS idx_shots_hole_id ON public.shots(hole_id);
CREATE INDEX IF NOT EXISTS idx_shots_user_id ON public.shots(user_id);

-- 14. HANDICAP HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.handicap_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    round_id UUID REFERENCES public.rounds(id) ON DELETE SET NULL,
    score_differential NUMERIC(4, 1) NOT NULL,
    resulting_handicap_index NUMERIC(4, 1) NOT NULL,
    rounds_count INT NOT NULL DEFAULT 0,
    differentials_used_count INT NOT NULL DEFAULT 0,
    differentials_used_json TEXT,
    status TEXT NOT NULL DEFAULT 'VALID',
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_handicap_history_user_id ON public.handicap_history(user_id);

-- 15. SCORE DIFFERENTIALS TABLE
CREATE TABLE IF NOT EXISTS public.score_differentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    round_id UUID NOT NULL REFERENCES public.rounds(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    course_tee_id UUID REFERENCES public.course_tees(id) ON DELETE SET NULL,
    gross_score INT NOT NULL,
    adjusted_gross_score INT NOT NULL,
    course_rating NUMERIC(4, 1) NOT NULL,
    slope_rating INT NOT NULL,
    pcc NUMERIC(3, 1) NOT NULL DEFAULT 0.0,
    pcc_status TEXT NOT NULL DEFAULT 'UNAVAILABLE',
    score_differential NUMERIC(4, 1) NOT NULL,
    is_used_in_handicap BOOLEAN NOT NULL DEFAULT false,
    played_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_score_diff_round_user UNIQUE (round_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_score_diff_user_id ON public.score_differentials(user_id);
CREATE INDEX IF NOT EXISTS idx_score_diff_round_id ON public.score_differentials(round_id);
CREATE INDEX IF NOT EXISTS idx_score_diff_played_at ON public.score_differentials(played_at);

-- ============================================================================
-- 16. AUTOMATIC PROFILE & GOLF BAG CREATION TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Create Profile
    INSERT INTO public.profiles (id, email, full_name, avatar_url, handicap_index)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        54.0
    );

    -- 2. Populate Standard 14 Golf Clubs in Virtual Bag
    INSERT INTO public.golf_bag_clubs (user_id, club_type, custom_name, average_distance_meters) VALUES
    (NEW.id, 'DRIVER', 'Driver 10.5°', 215.0),
    (NEW.id, 'WOOD_3', '3-Wood 15°', 195.0),
    (NEW.id, 'WOOD_5', '5-Wood 18°', 180.0),
    (NEW.id, 'HYBRID_4', '4-Hybrid 22°', 170.0),
    (NEW.id, 'IRON_5', '5 Iron', 160.0),
    (NEW.id, 'IRON_6', '6 Iron', 150.0),
    (NEW.id, 'IRON_7', '7 Iron', 140.0),
    (NEW.id, 'IRON_8', '8 Iron', 130.0),
    (NEW.id, 'IRON_9', '9 Iron', 120.0),
    (NEW.id, 'PITCHING_WEDGE', 'PW 46°', 110.0),
    (NEW.id, 'GAP_WEDGE', 'GW 50°', 95.0),
    (NEW.id, 'SAND_WEDGE', 'SW 54°', 80.0),
    (NEW.id, 'LOB_WEDGE', 'LW 58°', 65.0),
    (NEW.id, 'PUTTER', 'Blade Putter', 0.0);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 17. AUTOMATIC UPDATED_AT TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND column_name = 'updated_at'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON public.%I;', t);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();', t);
    END LOOP;
END $$;

-- ============================================================================
-- 18. POSTGIS GEOMETRY SYNC TRIGGER (Lat/Lng to Geometry and vice versa)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.sync_hole_geometries()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.green_center_lat IS NOT NULL AND NEW.green_center_lng IS NOT NULL THEN
        NEW.green_center := ST_SetSRID(ST_MakePoint(NEW.green_center_lng, NEW.green_center_lat), 4326);
    END IF;
    IF NEW.green_front_lat IS NOT NULL AND NEW.green_front_lng IS NOT NULL THEN
        NEW.green_front := ST_SetSRID(ST_MakePoint(NEW.green_front_lng, NEW.green_front_lat), 4326);
    END IF;
    IF NEW.green_back_lat IS NOT NULL AND NEW.green_back_lng IS NOT NULL THEN
        NEW.green_back := ST_SetSRID(ST_MakePoint(NEW.green_back_lng, NEW.green_back_lat), 4326);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_hole_geometries ON public.holes;
CREATE TRIGGER trg_sync_hole_geometries
    BEFORE INSERT OR UPDATE ON public.holes
    FOR EACH ROW EXECUTE FUNCTION public.sync_hole_geometries();

-- ============================================================================
-- 19. SUPABASE REALTIME REPLICATION (For LivePlay Leaderboard & Sync)
-- ============================================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rounds;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.round_players;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.round_scores;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.shots;
EXCEPTION
    WHEN others THEN null;
END $$;

-- ============================================================================
-- 20. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.golf_bag_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_tees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.holes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hole_tees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hole_polygons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.round_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.round_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.handicap_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.score_differentials ENABLE ROW LEVEL SECURITY;

-- Courses & Course Structure: Public Read for all authenticated users
CREATE POLICY "Public Read Courses" ON public.courses FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public Read Tees" ON public.course_tees FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public Read Holes" ON public.holes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public Read Hole Tees" ON public.hole_tees FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public Read Polygons" ON public.hole_polygons FOR SELECT TO authenticated USING (true);

-- User Profiles: Users can view all golfers, update own profile
CREATE POLICY "View Profiles" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Update Own Profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Golf Bags: Users manage their own golf bag
CREATE POLICY "Manage Own Clubs" ON public.golf_bag_clubs FOR ALL TO authenticated USING (auth.uid() = user_id);

-- Rounds: Read rounds user is participating in or created; Create own rounds
CREATE POLICY "View Rounds" ON public.rounds FOR SELECT TO authenticated USING (
    created_by = auth.uid() OR 
    EXISTS (SELECT 1 FROM public.round_players rp WHERE rp.round_id = rounds.id AND rp.user_id = auth.uid())
);
CREATE POLICY "Insert Own Rounds" ON public.rounds FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());
CREATE POLICY "Update Own Rounds" ON public.rounds FOR UPDATE TO authenticated USING (created_by = auth.uid());

-- Round Players & Scores: Round participants can read/write
CREATE POLICY "View Round Players" ON public.round_players FOR SELECT TO authenticated USING (true);
CREATE POLICY "Manage Round Players" ON public.round_players FOR ALL TO authenticated USING (true);

CREATE POLICY "View Round Scores" ON public.round_scores FOR SELECT TO authenticated USING (true);
CREATE POLICY "Manage Round Scores" ON public.round_scores FOR ALL TO authenticated USING (true);

-- Shots: Users manage shots in their active rounds
CREATE POLICY "View Shots" ON public.shots FOR SELECT TO authenticated USING (true);
CREATE POLICY "Manage Shots" ON public.shots FOR ALL TO authenticated USING (true);

-- Handicap & Differentials: Users view and manage own handicap records
CREATE POLICY "View Own Handicap" ON public.handicap_history FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Manage Own Handicap" ON public.handicap_history FOR ALL TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "View Own Differentials" ON public.score_differentials FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Manage Own Differentials" ON public.score_differentials FOR ALL TO authenticated USING (auth.uid() = user_id);
