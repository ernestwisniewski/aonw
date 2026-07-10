--
-- ACTION ALTER TABLE
--
-- Serverpod executes a migration artifact as one multi-statement query, so
-- PostgreSQL does not permit CREATE INDEX CONCURRENTLY here. Apply this small
-- auth-table migration in a maintenance window; the transaction keeps a failed
-- deployment atomic and retry safe.
BEGIN;
CREATE INDEX "aonw_steam_auth_request_expires_at_idx" ON "aonw_steam_auth_request" USING btree ("expiresAt");

--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260710111535872-auth-maintenance-indexes', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260710111535872-auth-maintenance-indexes', "timestamp" = now();

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
