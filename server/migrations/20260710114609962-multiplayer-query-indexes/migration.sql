-- Serverpod executes a migration artifact as one multi-statement query, so
-- PostgreSQL does not permit CREATE INDEX CONCURRENTLY here. Apply this
-- multiplayer-index migration in a maintenance window; DROP/CREATE takes table
-- locks, while the transaction keeps a failed deployment atomic and retry safe.
BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "aonw_match_state_idx";
CREATE INDEX "aonw_match_state_created_public_idx" ON "aonw_match" USING btree ("state", "createdAt", "publicId");
CREATE INDEX "aonw_match_public_discovery_idx" ON "aonw_match" USING btree ("state", "private", "inviteCode", "createdAt", "publicId");
CREATE INDEX "aonw_match_quickplay_candidate_idx" ON "aonw_match" USING btree ("state", "private", "quickplay", "inviteCode", "createdAt", "publicId");
--
-- ACTION ALTER TABLE
--
DROP INDEX "aonw_player_match_user_idx";
CREATE UNIQUE INDEX "aonw_player_user_match_idx" ON "aonw_player" USING btree ("userIdentifier", "matchId");

--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260710114609962-multiplayer-query-indexes', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260710114609962-multiplayer-query-indexes', "timestamp" = now();

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
