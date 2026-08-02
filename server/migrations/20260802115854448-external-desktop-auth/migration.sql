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
CREATE TABLE "aonw_external_auth_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requestId" text NOT NULL,
    "state" text NOT NULL,
    "provider" text NOT NULL,
    "status" text NOT NULL,
    "codeVerifier" text,
    "error" text,
    "authStrategy" text,
    "token" text,
    "tokenExpiresAt" timestamp without time zone,
    "refreshToken" text,
    "authUserId" uuid,
    "scopeNames" json,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "consumedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "aonw_external_auth_request_request_id_idx" ON "aonw_external_auth_request" USING btree ("requestId");
CREATE UNIQUE INDEX "aonw_external_auth_request_state_idx" ON "aonw_external_auth_request" USING btree ("state");
CREATE INDEX "aonw_external_auth_request_status_idx" ON "aonw_external_auth_request" USING btree ("status");
CREATE INDEX "aonw_external_auth_request_expires_at_idx" ON "aonw_external_auth_request" USING btree ("expiresAt");


--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260802115854448-external-desktop-auth', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260802115854448-external-desktop-auth', "timestamp" = now();

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
