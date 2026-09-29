import { MigrationInterface, QueryRunner } from 'typeorm';

export class RoundScorecard1710000002000 implements MigrationInterface {
  name = 'RoundScorecard1710000002000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Create rounds table
    await queryRunner.query(`
      CREATE TABLE "rounds" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "course_id" UUID NOT NULL,
        "game_mode" VARCHAR(50) NOT NULL,
        "status" VARCHAR(50) NOT NULL DEFAULT 'NOT_STARTED',
        "current_hole" INT NOT NULL DEFAULT 1,
        "started_at" TIMESTAMP WITH TIME ZONE,
        "finished_at" TIMESTAMP WITH TIME ZONE,
        "created_by" UUID NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_rounds_course" FOREIGN KEY ("course_id") REFERENCES "courses" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_rounds_creator" FOREIGN KEY ("created_by") REFERENCES "users" ("id") ON DELETE CASCADE,
        CONSTRAINT "chk_game_mode" CHECK ("game_mode" IN ('STROKE_PLAY', 'STABLEFORD', 'MATCH_PLAY', 'SCRAMBLE', 'FOUR_BALL')),
        CONSTRAINT "chk_round_status" CHECK ("status" IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_rounds_course_id" ON "rounds" ("course_id");`);
    await queryRunner.query(`CREATE INDEX "idx_rounds_created_by" ON "rounds" ("created_by");`);
    await queryRunner.query(`CREATE INDEX "idx_rounds_status" ON "rounds" ("status");`);

    // 2. Create round_players table
    await queryRunner.query(`
      CREATE TABLE "round_players" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "round_id" UUID NOT NULL,
        "user_id" UUID,
        "player_name" VARCHAR(100) NOT NULL,
        "player_order" INT NOT NULL,
        "team_id" VARCHAR(50),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_round_players_round" FOREIGN KEY ("round_id") REFERENCES "rounds" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_round_players_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
        CONSTRAINT "uq_round_players_round_order" UNIQUE ("round_id", "player_order"),
        CONSTRAINT "chk_player_order" CHECK ("player_order" >= 1 AND "player_order" <= 4)
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_round_players_round_id" ON "round_players" ("round_id");`);
    await queryRunner.query(`CREATE INDEX "idx_round_players_user_id" ON "round_players" ("user_id");`);

    // 3. Create round_scores table
    await queryRunner.query(`
      CREATE TABLE "round_scores" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "round_id" UUID NOT NULL,
        "player_id" UUID NOT NULL,
        "hole_id" UUID NOT NULL,
        "gross_score" INT NOT NULL,
        "putts" INT NOT NULL DEFAULT 0,
        "penalties" INT NOT NULL DEFAULT 0,
        "fairway_hit" VARCHAR(20),
        "gir" BOOLEAN,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_round_scores_round" FOREIGN KEY ("round_id") REFERENCES "rounds" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_round_scores_player" FOREIGN KEY ("player_id") REFERENCES "round_players" ("id") ON DELETE CASCADE,
        CONSTRAINT "fk_round_scores_hole" FOREIGN KEY ("hole_id") REFERENCES "holes" ("id") ON DELETE CASCADE,
        CONSTRAINT "uq_round_scores_round_player_hole" UNIQUE ("round_id", "player_id", "hole_id"),
        CONSTRAINT "chk_round_scores_gross" CHECK ("gross_score" > 0),
        CONSTRAINT "chk_round_scores_putts" CHECK ("putts" >= 0),
        CONSTRAINT "chk_round_scores_penalties" CHECK ("penalties" >= 0),
        CONSTRAINT "chk_putts_lte_gross" CHECK ("putts" <= "gross_score"),
        CONSTRAINT "chk_fairway_hit" CHECK ("fairway_hit" IS NULL OR "fairway_hit" IN ('LEFT', 'STRAIGHT', 'RIGHT'))
      );
    `);
    await queryRunner.query(`CREATE INDEX "idx_round_scores_round_id" ON "round_scores" ("round_id");`);
    await queryRunner.query(`CREATE INDEX "idx_round_scores_player_id" ON "round_scores" ("player_id");`);
    await queryRunner.query(`CREATE INDEX "idx_round_scores_hole_id" ON "round_scores" ("hole_id");`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "round_scores";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "round_players";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "rounds";`);
  }
}
