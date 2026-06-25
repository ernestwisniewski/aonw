BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "aonw_steam_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "steamId" text NOT NULL,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "lastSeenAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "aonw_steam_account_steam_id_idx" ON "aonw_steam_account" USING btree ("steamId");
CREATE UNIQUE INDEX "aonw_steam_account_auth_user_idx" ON "aonw_steam_account" USING btree ("authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "aonw_steam_auth_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requestId" text NOT NULL,
    "status" text NOT NULL,
    "authUserId" uuid,
    "steamId" text,
    "error" text,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "consumedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "aonw_steam_auth_request_request_id_idx" ON "aonw_steam_auth_request" USING btree ("requestId");
CREATE INDEX "aonw_steam_auth_request_status_idx" ON "aonw_steam_auth_request" USING btree ("status");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "aonw_steam_account"
    ADD CONSTRAINT "aonw_steam_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260618143215539', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260618143215539', "timestamp" = now();

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
