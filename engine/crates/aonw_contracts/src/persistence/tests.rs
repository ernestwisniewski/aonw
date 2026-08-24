use super::{MAX_SAVE_GAME_JSON_BYTES, ReplayCommandDto, ReplayLogDto, SaveGameDto};

#[test]
fn strict_save_codec_rejects_unknown_duplicate_and_oversized_input() {
    let base = r#"{"mapId":"m","mapHash":"h","rulesetId":"r","rulesetHash":"h","actorPlayerId":"p","eventOffset":0,"stateDigest":"d","state":{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"transportNetwork":[]}}"#;
    assert!(SaveGameDto::from_json(base).is_ok());
    let unknown = base.replacen("\"state\":", "\"extra\":true,\"state\":", 1);
    assert!(SaveGameDto::from_json(&unknown).is_err());
    let duplicate = base.replacen("\"mapId\":\"m\",", "\"mapId\":\"m\",\"mapId\":\"m\",", 1);
    assert!(SaveGameDto::from_json(&duplicate).is_err());
    assert!(SaveGameDto::from_json(&"x".repeat(MAX_SAVE_GAME_JSON_BYTES + 1)).is_err());
}

#[test]
fn strict_replay_codec_rejects_unknown_and_duplicate_fields() {
    let base = r#"{"mapId":"m","mapHash":"h","rulesetId":"r","rulesetHash":"h","actorPlayerId":"p","initialEventOffset":0,"initialStateDigest":"d","initialState":{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"transportNetwork":[]},"entries":[]}"#;
    assert!(ReplayLogDto::from_json(base).is_ok());
    let unknown = base.replacen("\"entries\":", "\"extra\":true,\"entries\":", 1);
    assert!(ReplayLogDto::from_json(&unknown).is_err());
    let duplicate = base.replacen("\"mapId\":\"m\",", "\"mapId\":\"m\",\"mapId\":\"m\",", 1);
    assert!(ReplayLogDto::from_json(&duplicate).is_err());
}

#[test]
fn every_current_unit_action_command_has_a_strict_wire_shape() {
    for kind in ["cancelUnitAction", "skipUnitTurn", "fortifyUnit"] {
        let json = format!(r#"{{"type":"{kind}","expectedRevision":7,"unitId":"unit-1"}}"#);
        assert!(serde_json::from_str::<ReplayCommandDto>(&json).is_ok());
        let unknown = json.replacen('}', ",\"unknown\":true}", 1);
        assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
    }
}

#[test]
fn every_current_logistics_command_has_a_strict_wire_shape() {
    let commands = [
        r#"{"type":"autoExploreUnit","expectedRevision":7,"unitId":"scout-1"}"#,
        r#"{"type":"assignMerchantTradeRoute","expectedRevision":7,"unitId":"merchant-1","destinationCityId":"city-2"}"#,
        r#"{"type":"moveMerchantToCity","expectedRevision":7,"unitId":"merchant-1","destinationCityId":"city-2"}"#,
        r#"{"type":"detachTroop","expectedRevision":7,"unitId":"army-1","troopKind":"archer"}"#,
    ];
    for json in commands {
        assert!(serde_json::from_str::<ReplayCommandDto>(json).is_ok());
        let unknown = json.replacen('}', ",\"legacyVersion\":1}", 1);
        assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
    }
}
