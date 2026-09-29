import { MigrationInterface, QueryRunner } from 'typeorm';

export class CourseDatabase1710000001000 implements MigrationInterface {
  name = 'CourseDatabase1710000001000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Add role column to users table
    await queryRunner.query(`
      ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "role" VARCHAR(20) NOT NULL DEFAULT 'USER';
    `);

    // 2. Create courses table
    await queryRunner.query(`
      CREATE TABLE "courses" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "name" VARCHAR(255) NOT NULL,
        "address" VARCHAR(255) NOT NULL,
        "city" VARCHAR(100) NOT NULL,
        "country" VARCHAR(100) NOT NULL,
        "latitude" NUMERIC(10, 7) NOT NULL,
        "longitude" NUMERIC(10, 7) NOT NULL,
        "location" GEOMETRY(Point, 4326),
        "timezone" VARCHAR(50) NOT NULL DEFAULT 'UTC',
        "total_holes" INT NOT NULL DEFAULT 18,
        "description" TEXT,
        "status" VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_courses_name" ON "courses" ("name");`);
    await queryRunner.query(`CREATE INDEX "idx_courses_city" ON "courses" ("city");`);
    await queryRunner.query(`CREATE INDEX "idx_courses_location" ON "courses" USING GIST ("location");`);

    // 3. Create course_tees table
    await queryRunner.query(`
      CREATE TABLE "course_tees" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "course_id" UUID NOT NULL,
        "name" VARCHAR(50) NOT NULL,
        "color" VARCHAR(30) NOT NULL,
        "rating" NUMERIC(4, 1) NOT NULL,
        "slope_rating" INT NOT NULL,
        "total_yardage" INT,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_course_tees_course" FOREIGN KEY ("course_id") REFERENCES "courses" ("id") ON DELETE CASCADE
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_course_tees_course_id" ON "course_tees" ("course_id");`);

    // 4. Create holes table
    await queryRunner.query(`
      CREATE TABLE "holes" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "course_id" UUID NOT NULL,
        "hole_number" INT NOT NULL,
        "par" INT NOT NULL,
        "handicap_index" INT NOT NULL,
        "green_center" GEOMETRY(Point, 4326),
        "green_front" GEOMETRY(Point, 4326),
        "green_back" GEOMETRY(Point, 4326),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_holes_course" FOREIGN KEY ("course_id") REFERENCES "courses" ("id") ON DELETE CASCADE,
        CONSTRAINT "uq_holes_course_hole_number" UNIQUE ("course_id", "hole_number")
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_holes_course_id" ON "holes" ("course_id");`);
    await queryRunner.query(`CREATE INDEX "idx_holes_green_center" ON "holes" USING GIST ("green_center");`);

    // 5. Create hole_tees table
    await queryRunner.query(`
      CREATE TABLE "hole_tees" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "hole_id" UUID NOT NULL,
        "course_tee_id" UUID NOT NULL,
        "tee_position" GEOMETRY(Point, 4326) NOT NULL,
        "distance_meters" INT,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_hole_tees_hole" FOREIGN KEY ("hole_id") REFERENCES "holes" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_hole_tees_course_tee" FOREIGN KEY ("course_tee_id") REFERENCES "course_tees" ("id") ON DELETE CASCADE,
        CONSTRAINT "uq_hole_tees_hole_course_tee" UNIQUE ("hole_id", "course_tee_id")
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_hole_tees_hole_id" ON "hole_tees" ("hole_id");`);
    await queryRunner.query(`CREATE INDEX "idx_hole_tees_course_tee_id" ON "hole_tees" ("course_tee_id");`);
    await queryRunner.query(`CREATE INDEX "idx_hole_tees_tee_position" ON "hole_tees" USING GIST ("tee_position");`);

    // 6. Create hole_polygons table
    await queryRunner.query(`
      CREATE TABLE "hole_polygons" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "hole_id" UUID NOT NULL,
        "polygon_type" VARCHAR(50) NOT NULL,
        "geometry" GEOMETRY(Polygon, 4326) NOT NULL,
        "metadata" JSONB,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_hole_polygons_hole" FOREIGN KEY ("hole_id") REFERENCES "holes" ("id") ON DELETE CASCADE,
        CONSTRAINT "chk_polygon_type" CHECK ("polygon_type" IN ('FAIRWAY', 'ROUGH', 'GREEN', 'BUNKER', 'WATER_HAZARD', 'TEE'))
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_hole_polygons_hole_id" ON "hole_polygons" ("hole_id");`);
    await queryRunner.query(`CREATE INDEX "idx_hole_polygons_geometry" ON "hole_polygons" USING GIST ("geometry");`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "hole_polygons";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "hole_tees";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "holes";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "course_tees";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "courses";`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN IF EXISTS "role";`);
  }
}
