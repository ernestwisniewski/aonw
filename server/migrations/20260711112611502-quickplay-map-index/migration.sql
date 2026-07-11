BEGIN;

--
-- ACTION ALTER TABLE
--
-- Replacing this index takes a table lock; apply during a maintenance window.
DROP INDEX "aonw_match_quickplay_candidate_idx";
CREATE INDEX "aonw_match_quickplay_candidate_idx" ON "aonw_match" USING btree ("state", "private", "quickplay", "inviteCode", "mapName", "createdAt", "publicId");

--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260711112611502-quickplay-map-index', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260711112611502-quickplay-map-index', "timestamp" = now();

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
