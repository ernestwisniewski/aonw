BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "aonw_match" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "aonw_match" (
    "id" bigserial PRIMARY KEY,
    "publicId" text NOT NULL,
    "ownerUserIdentifier" text NOT NULL,
    "name" text NOT NULL,
    "mapName" text NOT NULL,
    "state" text NOT NULL,
    "turn" bigint NOT NULL,
    "maxPlayers" bigint NOT NULL,
    "minPlayers" bigint NOT NULL,
    "private" boolean NOT NULL,
    "quickplay" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "startedAt" timestamp without time zone,
    "autoStartAt" timestamp without time zone,
    "inviteCode" text
);

-- Indexes
CREATE UNIQUE INDEX "aonw_match_public_id_idx" ON "aonw_match" USING btree ("publicId");
CREATE UNIQUE INDEX "aonw_match_invite_code_idx" ON "aonw_match" USING btree ("inviteCode");
CREATE INDEX "aonw_match_state_idx" ON "aonw_match" USING btree ("state");


--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260611224644318-clean-serverpod-auth', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260611224644318-clean-serverpod-auth', "timestamp" = now();

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


COMMIT;
