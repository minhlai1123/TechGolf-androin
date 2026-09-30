import { MigrationInterface, QueryRunner } from 'typeorm';

export class WhsHandicapAndStatistics1710000004000 implements MigrationInterface {
  name = 'WhsHandicapAndStatistics1710000004000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Add tee_id to round_players table if not exists
    await queryRunner.query(`
      ALTER TABLE "round_players"
      ADD COLUMN IF NOT EXISTS "tee_id" UUID,
      ADD CONSTRAINT "fk_round_players_tee" FOREIGN KEY ("tee_id") REFERENCES "course_tees" ("id") ON DELETE SET NULL;
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "idx_round_players_tee_id" ON "round_players" ("tee_id");`);

    // 2. Expand handicap_history table
    await queryRunner.query(`
      ALTER TABLE "handicap_history"
      ADD COLUMN IF NOT EXISTS "rounds_count" INT NOT NULL DEFAULT 0,
      ADD COLUMN IF NOT EXISTS "differentials_used_count" INT NOT NULL DEFAULT 0,
      ADD COLUMN IF NOT EXISTS "differentials_used_json" TEXT,
      ADD COLUMN IF NOT EXISTS "status" VARCHAR(30) NOT NULL DEFAULT 'VALID';
    `);

    // 3. Create score_differentials table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "score_differentials" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "user_id" UUID NOT NULL,
        "round_id" UUID NOT NULL,
        "course_id" UUID NOT NULL,
        "course_tee_id" UUID,
        "gross_score" INT NOT NULL,
        "adjusted_gross_score" INT NOT NULL,
        "course_rating" NUMERIC(4, 1) NOT NULL,
        "slope_rating" INT NOT NULL,
        "pcc" NUMERIC(3, 1) NOT NULL DEFAULT 0.0,
        "pcc_status" VARCHAR(20) NOT NULL DEFAULT 'UNAVAILABLE',
        "score_differential" NUMERIC(4, 1) NOT NULL,
        "is_used_in_handicap" BOOLEAN NOT NULL DEFAULT false,
        "played_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_score_diff_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_score_diff_round" FOREIGN KEY ("round_id") REFERENCES "rounds" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_score_diff_course" FOREIGN KEY ("course_id") REFERENCES "courses" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_score_diff_tee" FOREIGN KEY ("course_tee_id") REFERENCES "course_tees" ("id") ON DELETE SET NULL,
        CONSTRAINT "uq_score_diff_round_user" UNIQUE ("round_id", "user_id")
      );
    `);

    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "idx_score_diff_user_id" ON "score_differentials" ("user_id");`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "idx_score_diff_round_id" ON "score_differentials" ("round_id");`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "idx_score_diff_played_at" ON "score_differentials" ("played_at");`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "score_differentials";`);

    await queryRunner.query(`
      ALTER TABLE "handicap_history"
      DROP COLUMN IF EXISTS "status",
      DROP COLUMN IF EXISTS "differentials_used_json",
      DROP COLUMN IF EXISTS "differentials_used_count",
      DROP COLUMN IF EXISTS "rounds_count";
    `);

    await queryRunner.query(`
      ALTER TABLE "round_players"
      DROP CONSTRAINT IF EXISTS "fk_round_players_tee",
      DROP COLUMN IF EXISTS "tee_id";
    `);
  }
}
