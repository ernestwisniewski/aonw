BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "aonw_match" ADD COLUMN "endedAt" timestamp without time zone;
ALTER TABLE "aonw_match" ADD COLUMN "outcomeCondition" text;
ALTER TABLE "aonw_match" ADD COLUMN "winnerPlayerId" text;

-- Existing terminal rows predate explicit lifecycle timestamps. The latest
-- authoritative snapshot is the closest durable record of when they ended.
UPDATE "aonw_match" AS "match"
SET "endedAt" = "latest_snapshot"."createdAt"
FROM (
    SELECT DISTINCT ON ("matchId") "matchId", "createdAt"
    FROM "aonw_snapshot"
    ORDER BY "matchId", "offset" DESC
) AS "latest_snapshot"
WHERE "match"."id" = "latest_snapshot"."matchId"
  AND "match"."state" IN ('finished', 'abandoned')
  AND "match"."endedAt" IS NULL;

CREATE INDEX "aonw_match_started_at_idx" ON "aonw_match" USING btree ("startedAt");
CREATE INDEX "aonw_match_ended_at_idx" ON "aonw_match" USING btree ("endedAt");

--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260711223706381-public-multiplayer-stats', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260711223706381-public-multiplayer-stats', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();


COMMIT;
