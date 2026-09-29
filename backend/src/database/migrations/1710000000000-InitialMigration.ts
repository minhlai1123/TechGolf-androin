import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialMigration1710000000000 implements MigrationInterface {
  name = 'InitialMigration1710000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Enable extensions
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`);
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "postgis";`);

    // 2. Create users table
    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "email" VARCHAR(255) NOT NULL,
        "password_hash" VARCHAR(255) NOT NULL,
        "full_name" VARCHAR(255) NOT NULL,
        "avatar_url" VARCHAR(500),
        "handicap_index" NUMERIC(4, 1) DEFAULT 54.0,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "uq_users_email" UNIQUE ("email")
      );
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "idx_users_email" ON "users" ("email");
    `);

    // 3. Create golf_bag_clubs table
    await queryRunner.query(`
      CREATE TABLE "golf_bag_clubs" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "user_id" UUID NOT NULL,
        "club_type" VARCHAR(50) NOT NULL,
        "custom_name" VARCHAR(100),
        "average_distance_meters" NUMERIC(5, 1) NOT NULL DEFAULT 0.0,
        "total_shots_recorded" INT NOT NULL DEFAULT 0,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_golf_bag_clubs_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE
      );
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_golf_bag_clubs_user_id" ON "golf_bag_clubs" ("user_id");
    `);

    // 4. Create handicap_history table
    await queryRunner.query(`
      CREATE TABLE "handicap_history" (
        "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "user_id" UUID NOT NULL,
        "round_id" UUID,
        "score_differential" NUMERIC(4, 1) NOT NULL,
        "resulting_handicap_index" NUMERIC(4, 1) NOT NULL,
        "calculated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "fk_handicap_history_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE
      );
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_handicap_history_user_id" ON "handicap_history" ("user_id");
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "handicap_history";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "golf_bag_clubs";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "users";`);
  }
}
