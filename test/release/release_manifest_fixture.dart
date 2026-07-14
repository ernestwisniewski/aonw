const artifactPlanFixture = <String, Object?>{
  'artifactSources': <String, Object?>{
    'linux': <String, Object?>{'requested': 'auto', 'resolved': 'github'},
    'windows': <String, Object?>{'requested': 'auto', 'resolved': 'github'},
  },
  'channels': <String, Object?>{
    'downloads': <String, Object?>{'enabled': true, 'linux': true},
    'googlePlay': <String, Object?>{
      'action': 'validate-only',
      'enabled': true,
      'track': 'internal',
    },
    'homepage': <String, Object?>{'enabled': true},
    'ios': <String, Object?>{'mode': 'required'},
    'itch': <String, Object?>{
      'enabled': true,
      'linux': true,
      'target': 'studio/game',
    },
    'server': <String, Object?>{'enabled': true},
    'steam': <String, Object?>{'enabled': true, 'linux': true},
    'web': <String, Object?>{'enabled': true},
  },
  'release': <String, Object?>{'build': 77, 'version': '1.2.3'},
  'schemaVersion': 1,
};
