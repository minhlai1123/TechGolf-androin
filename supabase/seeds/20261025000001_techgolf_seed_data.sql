-- ============================================================================
-- TECHGOLF SUPABASE SEED DATA
-- Inserts Pine Valley Championship Golf Club with 9 holes, tees, and polygons
-- ============================================================================

DO $$
DECLARE
    v_course_id UUID;
    v_tee_black_id UUID;
    v_tee_blue_id UUID;
    v_tee_white_id UUID;
    v_tee_red_id UUID;
    v_hole_id UUID;
    v_base_lat DOUBLE PRECISION;
    v_base_lng DOUBLE PRECISION;
    v_gc_lat DOUBLE PRECISION;
    v_gc_lng DOUBLE PRECISION;
    v_gf_lat DOUBLE PRECISION;
    v_gf_lng DOUBLE PRECISION;
    v_gb_lat DOUBLE PRECISION;
    v_gb_lng DOUBLE PRECISION;
    v_hole_num INT;
    v_par INT;
    v_hcp INT;
BEGIN
    -- 1. Create or Find Course
    SELECT id INTO v_course_id FROM public.courses WHERE name = 'Pine Valley Championship Golf Club';
    
    IF v_course_id IS NULL THEN
        INSERT INTO public.courses (
            name, address, city, country, latitude, longitude, location, timezone, total_holes, description, status
        ) VALUES (
            'Pine Valley Championship Golf Club',
            '100 Fairway Boulevard, Golf Valley',
            'Hanoi',
            'Vietnam',
            21.0285000,
            105.8542000,
            ST_SetSRID(ST_MakePoint(105.8542000, 21.0285000), 4326),
            'Asia/Ho_Chi_Minh',
            18,
            'Championship 18-hole golf facility with GPS rangefinder and vector polygons.',
            'ACTIVE'
        ) RETURNING id INTO v_course_id;
    END IF;

    -- 2. Insert Course Tees
    SELECT id INTO v_tee_black_id FROM public.course_tees WHERE course_id = v_course_id AND name = 'Black';
    IF v_tee_black_id IS NULL THEN
        INSERT INTO public.course_tees (course_id, name, color, rating, slope_rating, total_yardage)
        VALUES (v_course_id, 'Black', '#0F172A', 75.2, 142, 7250) RETURNING id INTO v_tee_black_id;
    END IF;

    SELECT id INTO v_tee_blue_id FROM public.course_tees WHERE course_id = v_course_id AND name = 'Blue';
    IF v_tee_blue_id IS NULL THEN
        INSERT INTO public.course_tees (course_id, name, color, rating, slope_rating, total_yardage)
        VALUES (v_course_id, 'Blue', '#2563EB', 73.1, 135, 6820) RETURNING id INTO v_tee_blue_id;
    END IF;

    SELECT id INTO v_tee_white_id FROM public.course_tees WHERE course_id = v_course_id AND name = 'White';
    IF v_tee_white_id IS NULL THEN
        INSERT INTO public.course_tees (course_id, name, color, rating, slope_rating, total_yardage)
        VALUES (v_course_id, 'White', '#F8FAFC', 71.0, 128, 6410) RETURNING id INTO v_tee_white_id;
    END IF;

    SELECT id INTO v_tee_red_id FROM public.course_tees WHERE course_id = v_course_id AND name = 'Red';
    IF v_tee_red_id IS NULL THEN
        INSERT INTO public.course_tees (course_id, name, color, rating, slope_rating, total_yardage)
        VALUES (v_course_id, 'Red', '#EF4444', 69.5, 120, 5890) RETURNING id INTO v_tee_red_id;
    END IF;

    -- 3. Loop and Create 9 Holes with Green Pins and Polygons
    FOR v_hole_num IN 1..9 LOOP
        IF v_hole_num = 1 THEN v_par := 4; v_hcp := 7; v_base_lat := 21.0285; v_base_lng := 105.8542;
        ELSIF v_hole_num = 2 THEN v_par := 3; v_hcp := 17; v_base_lat := 21.0310; v_base_lng := 105.8560;
        ELSIF v_hole_num = 3 THEN v_par := 5; v_hcp := 1; v_base_lat := 21.0335; v_base_lng := 105.8575;
        ELSIF v_hole_num = 4 THEN v_par := 4; v_hcp := 9; v_base_lat := 21.0350; v_base_lng := 105.8550;
        ELSIF v_hole_num = 5 THEN v_par := 4; v_hcp := 5; v_base_lat := 21.0330; v_base_lng := 105.8525;
        ELSIF v_hole_num = 6 THEN v_par := 3; v_hcp := 15; v_base_lat := 21.0315; v_base_lng := 105.8510;
        ELSIF v_hole_num = 7 THEN v_par := 5; v_hcp := 3; v_base_lat := 21.0290; v_base_lng := 105.8490;
        ELSIF v_hole_num = 8 THEN v_par := 4; v_hcp := 11; v_base_lat := 21.0270; v_base_lng := 105.8515;
        ELSE v_par := 4; v_hcp := 13; v_base_lat := 21.0275; v_base_lng := 105.8535;
        END IF;

        v_gc_lng := v_base_lng + 0.0030;
        v_gc_lat := v_base_lat + 0.0025;
        v_gf_lng := v_gc_lng - 0.00015;
        v_gf_lat := v_gc_lat - 0.00015;
        v_gb_lng := v_gc_lng + 0.00015;
        v_gb_lat := v_gc_lat + 0.00015;

        -- Check if Hole exists
        SELECT id INTO v_hole_id FROM public.holes WHERE course_id = v_course_id AND hole_number = v_hole_num;
        IF v_hole_id IS NULL THEN
            INSERT INTO public.holes (
                course_id, hole_number, par, handicap_index,
                green_center, green_front, green_back,
                green_center_lat, green_center_lng,
                green_front_lat, green_front_lng,
                green_back_lat, green_back_lng
            ) VALUES (
                v_course_id, v_hole_num, v_par, v_hcp,
                ST_SetSRID(ST_MakePoint(v_gc_lng, v_gc_lat), 4326),
                ST_SetSRID(ST_MakePoint(v_gf_lng, v_gf_lat), 4326),
                ST_SetSRID(ST_MakePoint(v_gb_lng, v_gb_lat), 4326),
                v_gc_lat, v_gc_lng,
                v_gf_lat, v_gf_lng,
                v_gb_lat, v_gb_lng
            ) RETURNING id INTO v_hole_id;

            -- Hole Tees
            INSERT INTO public.hole_tees (hole_id, course_tee_id, tee_position, tee_lat, tee_lng, distance_meters) VALUES
            (v_hole_id, v_tee_black_id, ST_SetSRID(ST_MakePoint(v_base_lng, v_base_lat), 4326), v_base_lat, v_base_lng, CASE WHEN v_par = 3 THEN 175 WHEN v_par = 4 THEN 410 ELSE 540 END),
            (v_hole_id, v_tee_blue_id, ST_SetSRID(ST_MakePoint(v_base_lng - 0.0001, v_base_lat - 0.0001), 4326), v_base_lat - 0.0001, v_base_lng - 0.0001, CASE WHEN v_par = 3 THEN 160 WHEN v_par = 4 THEN 385 ELSE 515 END),
            (v_hole_id, v_tee_white_id, ST_SetSRID(ST_MakePoint(v_base_lng - 0.0002, v_base_lat - 0.0002), 4326), v_base_lat - 0.0002, v_base_lng - 0.0002, CASE WHEN v_par = 3 THEN 145 WHEN v_par = 4 THEN 360 ELSE 490 END),
            (v_hole_id, v_tee_red_id, ST_SetSRID(ST_MakePoint(v_base_lng - 0.0003, v_base_lat - 0.0003), 4326), v_base_lat - 0.0003, v_base_lng - 0.0003, CASE WHEN v_par = 3 THEN 130 WHEN v_par = 4 THEN 330 ELSE 460 END);

            -- Green Polygon
            INSERT INTO public.hole_polygons (hole_id, polygon_type, geometry) VALUES (
                v_hole_id,
                'GREEN',
                ST_SetSRID(ST_MakePolygon(ST_MakeLine(ARRAY[
                    ST_MakePoint(v_gc_lng - 0.00025, v_gc_lat - 0.00025),
                    ST_MakePoint(v_gc_lng + 0.00025, v_gc_lat - 0.00025),
                    ST_MakePoint(v_gc_lng + 0.00025, v_gc_lat + 0.00025),
                    ST_MakePoint(v_gc_lng - 0.00025, v_gc_lat + 0.00025),
                    ST_MakePoint(v_gc_lng - 0.00025, v_gc_lat - 0.00025)
                ])), 4326)
            );

            -- Fairway Polygon
            INSERT INTO public.hole_polygons (hole_id, polygon_type, geometry) VALUES (
                v_hole_id,
                'FAIRWAY',
                ST_SetSRID(ST_MakePolygon(ST_MakeLine(ARRAY[
                    ST_MakePoint(v_base_lng + 0.0005, v_base_lat + 0.0004),
                    ST_MakePoint(v_gc_lng - 0.0004, v_gc_lat - 0.0003),
                    ST_MakePoint(v_gc_lng - 0.0002, v_gc_lat - 0.0005),
                    ST_MakePoint(v_base_lng + 0.0007, v_base_lat + 0.0002),
                    ST_MakePoint(v_base_lng + 0.0005, v_base_lat + 0.0004)
                ])), 4326)
            );

            -- Bunker Polygon
            INSERT INTO public.hole_polygons (hole_id, polygon_type, geometry, metadata) VALUES (
                v_hole_id,
                'BUNKER',
                ST_SetSRID(ST_MakePolygon(ST_MakeLine(ARRAY[
                    ST_MakePoint(v_gc_lng + 0.0003, v_gc_lat + 0.0001),
                    ST_MakePoint(v_gc_lng + 0.00045, v_gc_lat + 0.0001),
                    ST_MakePoint(v_gc_lng + 0.00045, v_gc_lat + 0.00025),
                    ST_MakePoint(v_gc_lng + 0.0003, v_gc_lat + 0.00025),
                    ST_MakePoint(v_gc_lng + 0.0003, v_gc_lat + 0.0001)
                ])), 4326),
                '{"trap_type": "greenside_right"}'::jsonb
            );

            -- Water Hazard Polygon
            INSERT INTO public.hole_polygons (hole_id, polygon_type, geometry, metadata) VALUES (
                v_hole_id,
                'WATER_HAZARD',
                ST_SetSRID(ST_MakePolygon(ST_MakeLine(ARRAY[
                    ST_MakePoint(v_base_lng + 0.0015, v_base_lat + 0.0008),
                    ST_MakePoint(v_base_lng + 0.0022, v_base_lat + 0.0008),
                    ST_MakePoint(v_base_lng + 0.0022, v_base_lat + 0.0013),
                    ST_MakePoint(v_base_lng + 0.0015, v_base_lat + 0.0013),
                    ST_MakePoint(v_base_lng + 0.0015, v_base_lat + 0.0008)
                ])), 4326),
                '{"hazard_type": "lateral_pond"}'::jsonb
            );
        END IF;
    END LOOP;
END $$;
