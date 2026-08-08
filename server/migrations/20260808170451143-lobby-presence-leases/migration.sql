BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "aonw_match_presence_lease" (
    "id" bigserial PRIMARY KEY,
    "matchId" bigint NOT NULL,
    "userIdentifier" text NOT NULL,
    "connectionGeneration" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "aonw_match_presence_user_idx" ON "aonw_match_presence_lease" USING btree ("matchId", "userIdentifier");
CREATE INDEX "aonw_match_presence_expiry_idx" ON "aonw_match_presence_lease" USING btree ("expiresAt");

-- Functional multiplayer revision 4 introduces durable presence. Existing
-- open lobbies have no lease that can prove their host or participants are
-- still online, so retire them atomically instead of carrying dead rooms into
-- discovery after deployment.
UPDATE "aonw_snapshot" AS "snapshot"
SET "snapshot" = jsonb_set(
        jsonb_set(
          "snapshot"."snapshot"::jsonb,
          '{state,phase}',
          to_jsonb('abandoned'::text),
          true
        ),
        '{state,reason}',
        to_jsonb('protocol_upgrade'::text),
        true
      )::json
FROM "aonw_match" AS "match"
WHERE "snapshot"."matchId" = "match"."id"
  AND "match"."state" = 'open';

UPDATE "aonw_match"
SET "state" = 'abandoned',
    "endedAt" = now(),
    "autoStartAt" = NULL
WHERE "state" = 'open';

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "aonw_match_presence_lease"
    ADD CONSTRAINT "aonw_match_presence_lease_fk_0"
    FOREIGN KEY("matchId")
    REFERENCES "aonw_match"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260808170451143-lobby-presence-leases', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260808170451143-lobby-presence-leases', "timestamp" = now();

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
