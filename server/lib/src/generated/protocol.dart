/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i3;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i4;
import 'auth/models/account.dart' as _i5;
import 'auth/models/account_auth_exception.dart' as _i6;
import 'auth/models/external_auth_poll_result.dart' as _i7;
import 'auth/models/external_auth_request.dart' as _i8;
import 'auth/models/external_auth_start.dart' as _i9;
import 'auth/models/steam_account.dart' as _i10;
import 'auth/models/steam_auth_poll_result.dart' as _i11;
import 'auth/models/steam_auth_request.dart' as _i12;
import 'auth/models/steam_auth_start.dart' as _i13;
import 'multiplayer/models/create_match_request.dart' as _i14;
import 'multiplayer/models/game_event.dart' as _i15;
import 'multiplayer/models/game_match.dart' as _i16;
import 'multiplayer/models/game_player.dart' as _i17;
import 'multiplayer/models/game_snapshot.dart' as _i18;
import 'multiplayer/models/multiplayer_client_message.dart' as _i19;
import 'multiplayer/models/multiplayer_exception.dart' as _i20;
import 'multiplayer/models/multiplayer_server_message.dart' as _i21;
import 'package:aonw_core/protocol.dart' as _i22;
import 'package:aonw_core/protocol/wire_match.dart' as _i23;
import 'package:aonw_core/protocol/wire_event.dart' as _i24;
export 'auth/models/account.dart';
export 'auth/models/account_auth_exception.dart';
export 'auth/models/external_auth_poll_result.dart';
export 'auth/models/external_auth_request.dart';
export 'auth/models/external_auth_start.dart';
export 'auth/models/steam_account.dart';
export 'auth/models/steam_auth_poll_result.dart';
export 'auth/models/steam_auth_request.dart';
export 'auth/models/steam_auth_start.dart';
export 'multiplayer/models/create_match_request.dart';
export 'multiplayer/models/game_event.dart';
export 'multiplayer/models/game_match.dart';
export 'multiplayer/models/game_player.dart';
export 'multiplayer/models/game_snapshot.dart';
export 'multiplayer/models/multiplayer_client_message.dart';
export 'multiplayer/models/multiplayer_exception.dart';
export 'multiplayer/models/multiplayer_server_message.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'aonw_account',
      dartName: 'AonwAccount',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayNameKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'passwordHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_account_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_account_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_account_email_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_account_display_name_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'displayNameKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_account_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_event',
      dartName: 'GameEvent',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_event_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'offset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'actorPlayerId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'clientMessageId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'event',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'package:aonw_core/protocol.dart:WireEvent',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_event_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_event_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_event_match_offset_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'offset',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_event_match_actor_client_message_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'actorPlayerId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientMessageId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_external_auth_request',
      dartName: 'ExternalAuthRequest',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'state',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'provider',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'codeVerifier',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'error',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'authStrategy',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'token',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'tokenExpiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'refreshToken',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'scopeNames',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'consumedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_request_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_state_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'state',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_expires_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_match',
      dartName: 'GameMatch',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_match_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'publicId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'ownerUserIdentifier',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mapName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'state',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'turn',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'maxPlayers',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'minPlayers',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'private',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'quickplay',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'startedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'endedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'outcomeCondition',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'winnerPlayerId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'autoStartAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'inviteCode',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_match_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_public_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_invite_code_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inviteCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_state_created_public_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'state',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_public_discovery_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'state',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'private',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inviteCode',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_quickplay_candidate_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'state',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'private',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'quickplay',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inviteCode',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'mapName',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_started_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'startedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_match_ended_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'endedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_player',
      dartName: 'GamePlayer',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_player_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'publicPlayerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userIdentifier',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'colorValue',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'countryId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'kind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'connectionState',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'ready',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'seatOrder',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_player_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_player_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_player_user_match_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userIdentifier',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_player_match_public_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicPlayerId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_snapshot',
      dartName: 'GameSnapshot',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_snapshot_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'offset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'snapshot',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'package:aonw_core/protocol.dart:WireSnapshot',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_snapshot_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_snapshot_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_snapshot_match_offset_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'offset',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_steam_account',
      dartName: 'SteamAccount',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'steamId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_steam_account_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_steam_account_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_account_steam_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'steamId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_account_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_steam_auth_request',
      dartName: 'SteamAuthRequest',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'steamId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'error',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'consumedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_request_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_expires_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.AonwAccount) {
      return _i5.AonwAccount.fromJson(data) as T;
    }
    if (t == _i6.AccountAuthException) {
      return _i6.AccountAuthException.fromJson(data) as T;
    }
    if (t == _i7.ExternalAuthPollResult) {
      return _i7.ExternalAuthPollResult.fromJson(data) as T;
    }
    if (t == _i8.ExternalAuthRequest) {
      return _i8.ExternalAuthRequest.fromJson(data) as T;
    }
    if (t == _i9.ExternalAuthStart) {
      return _i9.ExternalAuthStart.fromJson(data) as T;
    }
    if (t == _i10.SteamAccount) {
      return _i10.SteamAccount.fromJson(data) as T;
    }
    if (t == _i11.SteamAuthPollResult) {
      return _i11.SteamAuthPollResult.fromJson(data) as T;
    }
    if (t == _i12.SteamAuthRequest) {
      return _i12.SteamAuthRequest.fromJson(data) as T;
    }
    if (t == _i13.SteamAuthStart) {
      return _i13.SteamAuthStart.fromJson(data) as T;
    }
    if (t == _i14.CreateMatchRequest) {
      return _i14.CreateMatchRequest.fromJson(data) as T;
    }
    if (t == _i15.GameEvent) {
      return _i15.GameEvent.fromJson(data) as T;
    }
    if (t == _i16.GameMatch) {
      return _i16.GameMatch.fromJson(data) as T;
    }
    if (t == _i17.GamePlayer) {
      return _i17.GamePlayer.fromJson(data) as T;
    }
    if (t == _i18.GameSnapshot) {
      return _i18.GameSnapshot.fromJson(data) as T;
    }
    if (t == _i19.MultiplayerClientMessage) {
      return _i19.MultiplayerClientMessage.fromJson(data) as T;
    }
    if (t == _i20.MultiplayerException) {
      return _i20.MultiplayerException.fromJson(data) as T;
    }
    if (t == _i21.MultiplayerServerMessage) {
      return _i21.MultiplayerServerMessage.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AonwAccount?>()) {
      return (data != null ? _i5.AonwAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AccountAuthException?>()) {
      return (data != null ? _i6.AccountAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ExternalAuthPollResult?>()) {
      return (data != null ? _i7.ExternalAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ExternalAuthRequest?>()) {
      return (data != null ? _i8.ExternalAuthRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.ExternalAuthStart?>()) {
      return (data != null ? _i9.ExternalAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SteamAccount?>()) {
      return (data != null ? _i10.SteamAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SteamAuthPollResult?>()) {
      return (data != null ? _i11.SteamAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.SteamAuthRequest?>()) {
      return (data != null ? _i12.SteamAuthRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.SteamAuthStart?>()) {
      return (data != null ? _i13.SteamAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CreateMatchRequest?>()) {
      return (data != null ? _i14.CreateMatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.GameEvent?>()) {
      return (data != null ? _i15.GameEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.GameMatch?>()) {
      return (data != null ? _i16.GameMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.GamePlayer?>()) {
      return (data != null ? _i17.GamePlayer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.GameSnapshot?>()) {
      return (data != null ? _i18.GameSnapshot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.MultiplayerClientMessage?>()) {
      return (data != null
              ? _i19.MultiplayerClientMessage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.MultiplayerException?>()) {
      return (data != null ? _i20.MultiplayerException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.MultiplayerServerMessage?>()) {
      return (data != null
              ? _i21.MultiplayerServerMessage.fromJson(data)
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == _i22.WireEvent) {
      return _i22.WireEvent.fromJson(data) as T;
    }
    if (t == List<_i17.GamePlayer>) {
      return (data as List).map((e) => deserialize<_i17.GamePlayer>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i17.GamePlayer>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.GamePlayer>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i18.GameSnapshot>) {
      return (data as List)
              .map((e) => deserialize<_i18.GameSnapshot>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i18.GameSnapshot>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i18.GameSnapshot>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i15.GameEvent>) {
      return (data as List).map((e) => deserialize<_i15.GameEvent>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i15.GameEvent>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i15.GameEvent>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i22.WireSnapshot) {
      return _i22.WireSnapshot.fromJson(data) as T;
    }
    if (t == _i1.getType<_i22.WireCommand?>()) {
      return (data != null ? _i22.WireCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireMatch?>()) {
      return (data != null ? _i22.WireMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireSnapshot?>()) {
      return (data != null ? _i22.WireSnapshot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireEvent?>()) {
      return (data != null ? _i22.WireEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireCommandAck?>()) {
      return (data != null ? _i22.WireCommandAck.fromJson(data) : null) as T;
    }
    if (t == List<_i23.WireMatch>) {
      return (data as List).map((e) => deserialize<_i23.WireMatch>(e)).toList()
          as T;
    }
    if (t == List<_i24.WireEvent>) {
      return (data as List).map((e) => deserialize<_i24.WireEvent>(e)).toList()
          as T;
    }
    if (t == _i22.WireAiPlayer) {
      return _i22.WireAiPlayer.fromJson(data) as T;
    }
    if (t == _i22.WireCommand) {
      return _i22.WireCommand.fromJson(data) as T;
    }
    if (t == _i22.WireCommandAck) {
      return _i22.WireCommandAck.fromJson(data) as T;
    }
    if (t == _i22.WireMatch) {
      return _i22.WireMatch.fromJson(data) as T;
    }
    if (t == _i22.WirePlayer) {
      return _i22.WirePlayer.fromJson(data) as T;
    }
    if (t == _i1.getType<_i22.WireAiPlayer?>()) {
      return (data != null ? _i22.WireAiPlayer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireCommand?>()) {
      return (data != null ? _i22.WireCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireCommandAck?>()) {
      return (data != null ? _i22.WireCommandAck.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireEvent?>()) {
      return (data != null ? _i22.WireEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireMatch?>()) {
      return (data != null ? _i22.WireMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WirePlayer?>()) {
      return (data != null ? _i22.WirePlayer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WireSnapshot?>()) {
      return (data != null ? _i22.WireSnapshot.fromJson(data) : null) as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i22.WireAiPlayer => 'WireAiPlayer',
      _i22.WireCommand => 'WireCommand',
      _i22.WireCommandAck => 'WireCommandAck',
      _i22.WireEvent => 'WireEvent',
      _i22.WireMatch => 'WireMatch',
      _i22.WirePlayer => 'WirePlayer',
      _i22.WireSnapshot => 'WireSnapshot',
      _i5.AonwAccount => 'AonwAccount',
      _i6.AccountAuthException => 'AccountAuthException',
      _i7.ExternalAuthPollResult => 'ExternalAuthPollResult',
      _i8.ExternalAuthRequest => 'ExternalAuthRequest',
      _i9.ExternalAuthStart => 'ExternalAuthStart',
      _i10.SteamAccount => 'SteamAccount',
      _i11.SteamAuthPollResult => 'SteamAuthPollResult',
      _i12.SteamAuthRequest => 'SteamAuthRequest',
      _i13.SteamAuthStart => 'SteamAuthStart',
      _i14.CreateMatchRequest => 'CreateMatchRequest',
      _i15.GameEvent => 'GameEvent',
      _i16.GameMatch => 'GameMatch',
      _i17.GamePlayer => 'GamePlayer',
      _i18.GameSnapshot => 'GameSnapshot',
      _i19.MultiplayerClientMessage => 'MultiplayerClientMessage',
      _i20.MultiplayerException => 'MultiplayerException',
      _i21.MultiplayerServerMessage => 'MultiplayerServerMessage',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('aonw.', '');
    }

    switch (data) {
      case _i22.WireAiPlayer():
        return 'WireAiPlayer';
      case _i22.WireCommand():
        return 'WireCommand';
      case _i22.WireCommandAck():
        return 'WireCommandAck';
      case _i22.WireEvent():
        return 'WireEvent';
      case _i22.WireMatch():
        return 'WireMatch';
      case _i22.WirePlayer():
        return 'WirePlayer';
      case _i22.WireSnapshot():
        return 'WireSnapshot';
      case _i5.AonwAccount():
        return 'AonwAccount';
      case _i6.AccountAuthException():
        return 'AccountAuthException';
      case _i7.ExternalAuthPollResult():
        return 'ExternalAuthPollResult';
      case _i8.ExternalAuthRequest():
        return 'ExternalAuthRequest';
      case _i9.ExternalAuthStart():
        return 'ExternalAuthStart';
      case _i10.SteamAccount():
        return 'SteamAccount';
      case _i11.SteamAuthPollResult():
        return 'SteamAuthPollResult';
      case _i12.SteamAuthRequest():
        return 'SteamAuthRequest';
      case _i13.SteamAuthStart():
        return 'SteamAuthStart';
      case _i14.CreateMatchRequest():
        return 'CreateMatchRequest';
      case _i15.GameEvent():
        return 'GameEvent';
      case _i16.GameMatch():
        return 'GameMatch';
      case _i17.GamePlayer():
        return 'GamePlayer';
      case _i18.GameSnapshot():
        return 'GameSnapshot';
      case _i19.MultiplayerClientMessage():
        return 'MultiplayerClientMessage';
      case _i20.MultiplayerException():
        return 'MultiplayerException';
      case _i21.MultiplayerServerMessage():
        return 'MultiplayerServerMessage';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'WireAiPlayer') {
      return deserialize<_i22.WireAiPlayer>(data['data']);
    }
    if (dataClassName == 'WireCommand') {
      return deserialize<_i22.WireCommand>(data['data']);
    }
    if (dataClassName == 'WireCommandAck') {
      return deserialize<_i22.WireCommandAck>(data['data']);
    }
    if (dataClassName == 'WireEvent') {
      return deserialize<_i22.WireEvent>(data['data']);
    }
    if (dataClassName == 'WireMatch') {
      return deserialize<_i22.WireMatch>(data['data']);
    }
    if (dataClassName == 'WirePlayer') {
      return deserialize<_i22.WirePlayer>(data['data']);
    }
    if (dataClassName == 'WireSnapshot') {
      return deserialize<_i22.WireSnapshot>(data['data']);
    }
    if (dataClassName == 'AonwAccount') {
      return deserialize<_i5.AonwAccount>(data['data']);
    }
    if (dataClassName == 'AccountAuthException') {
      return deserialize<_i6.AccountAuthException>(data['data']);
    }
    if (dataClassName == 'ExternalAuthPollResult') {
      return deserialize<_i7.ExternalAuthPollResult>(data['data']);
    }
    if (dataClassName == 'ExternalAuthRequest') {
      return deserialize<_i8.ExternalAuthRequest>(data['data']);
    }
    if (dataClassName == 'ExternalAuthStart') {
      return deserialize<_i9.ExternalAuthStart>(data['data']);
    }
    if (dataClassName == 'SteamAccount') {
      return deserialize<_i10.SteamAccount>(data['data']);
    }
    if (dataClassName == 'SteamAuthPollResult') {
      return deserialize<_i11.SteamAuthPollResult>(data['data']);
    }
    if (dataClassName == 'SteamAuthRequest') {
      return deserialize<_i12.SteamAuthRequest>(data['data']);
    }
    if (dataClassName == 'SteamAuthStart') {
      return deserialize<_i13.SteamAuthStart>(data['data']);
    }
    if (dataClassName == 'CreateMatchRequest') {
      return deserialize<_i14.CreateMatchRequest>(data['data']);
    }
    if (dataClassName == 'GameEvent') {
      return deserialize<_i15.GameEvent>(data['data']);
    }
    if (dataClassName == 'GameMatch') {
      return deserialize<_i16.GameMatch>(data['data']);
    }
    if (dataClassName == 'GamePlayer') {
      return deserialize<_i17.GamePlayer>(data['data']);
    }
    if (dataClassName == 'GameSnapshot') {
      return deserialize<_i18.GameSnapshot>(data['data']);
    }
    if (dataClassName == 'MultiplayerClientMessage') {
      return deserialize<_i19.MultiplayerClientMessage>(data['data']);
    }
    if (dataClassName == 'MultiplayerException') {
      return deserialize<_i20.MultiplayerException>(data['data']);
    }
    if (dataClassName == 'MultiplayerServerMessage') {
      return deserialize<_i21.MultiplayerServerMessage>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.AonwAccount:
        return _i5.AonwAccount.t;
      case _i8.ExternalAuthRequest:
        return _i8.ExternalAuthRequest.t;
      case _i10.SteamAccount:
        return _i10.SteamAccount.t;
      case _i12.SteamAuthRequest:
        return _i12.SteamAuthRequest.t;
      case _i15.GameEvent:
        return _i15.GameEvent.t;
      case _i16.GameMatch:
        return _i16.GameMatch.t;
      case _i17.GamePlayer:
        return _i17.GamePlayer.t;
      case _i18.GameSnapshot:
        return _i18.GameSnapshot.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'aonw';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
