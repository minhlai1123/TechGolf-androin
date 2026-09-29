import { MigrationInterface, QueryRunner } from 'typeorm';

export class ShotsAndClubDistance1710000003000 implements MigrationInterface {
  name = 'ShotsAndClubDistance1710000003000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Add is_active column to golf_bag_clubs if not exists
    await queryRunner.query(`
      ALTER TABLE "golf_bag_clubs" 
      ADD COLUMN IF NOT EXISTS "is_active" BOOLEAN NOT NULL DEFAULT true;
    `);

    // 2. Create shots table
    await queryRunner.query(`
      CREATE TABLE "shots" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "round_id" UUID NOT NULL,
        "player_id" UUID NOT NULL,
        "user_id" UUID,
        "hole_id" UUID NOT NULL,
        "club_id" UUID,
        "status" VARCHAR(20) NOT NULL DEFAULT 'STARTED',
        "start_latitude" DOUBLE PRECISION NOT NULL,
        "start_longitude" DOUBLE PRECISION NOT NULL,
        "start_elevation" DOUBLE PRECISION,
        "end_latitude" DOUBLE PRECISION,
        "end_longitude" DOUBLE PRECISION,
        "end_elevation" DOUBLE PRECISION,
        "elevation_delta" DOUBLE PRECISION,
        "distance" DOUBLE PRECISION,
        "distance_unit" VARCHAR(10) NOT NULL DEFAULT 'YARDS',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_shots_round" FOREIGN KEY ("round_id") REFERENCES "rounds" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_shots_player" FOREIGN KEY ("player_id") REFERENCES "round_players" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_shots_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
        CONSTRAINT "fk_shots_hole" FOREIGN KEY ("hole_id") REFERENCES "holes" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_shots_club" FOREIGN KEY ("club_id") REFERENCES "golf_bag_clubs" ("id") ON DELETE SET NULL,
        CONSTRAINT "chk_shot_status" CHECK ("status" IN ('READY', 'STARTED', 'SAVED')),
        CONSTRAINT "chk_shot_distance_unit" CHECK ("distance_unit" IN ('YARDS', 'METERS'))
      );
    `);

    await queryRunner.query(`CREATE INDEX "idx_shots_round_id" ON "shots" ("round_id");`);
    await queryRunner.query(`CREATE INDEX "idx_shots_player_id" ON "shots" ("player_id");`);
    await queryRunner.query(`CREATE INDEX "idx_shots_hole_id" ON "shots" ("hole_id");`);
    await queryRunner.query(`CREATE INDEX "idx_shots_club_id" ON "shots" ("club_id");`);
    await queryRunner.query(`CREATE INDEX "idx_shots_user_id" ON "shots" ("user_id");`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "shots";`);
    await queryRunner.query(`
      ALTER TABLE "golf_bag_clubs" 
      DROP COLUMN IF EXISTS "is_active";
    `);
  }
}
