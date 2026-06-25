import 'package:aonw/game/presentation/widgets/theme/game_icon_path_parser.dart';
import 'package:flutter/material.dart';

part 'game_icon_data.dart';
part 'game_icon_renderer.dart';

abstract final class GameIcons {
  static const city = GameIconData(
    paths: ['M4 21V10l8-6 8 6v11', 'M4 21h16', 'M10 21v-6h4v6'],
  );

  static const cityFilled = GameIconData(
    paths: ['M12 3l9 7h-2v10H5V10H3l9-7z'],
    filled: true,
  );

  static const army = GameIconData(
    paths: ['M12 2.5l8 3V12c0 4-3 7.2-8 9.5-5-2.3-8-5.5-8-9.5V5.5l8-3z'],
    filled: true,
  );

  static const warrior = GameIconData(
    paths: ['M5 19L19 5', 'M14 5l5 5', 'M7 17l-2 4 4-2'],
  );

  static const archer = GameIconData(
    paths: ['M6 4C14 7 14 17 6 20', 'M6 4v16', 'M4 12h14', 'M15 9l3 3-3 3'],
  );

  static const settler = GameIconData(
    paths: ['M5 20V9l7-5 7 5v11', 'M9 20v-6h6v6'],
  );

  static const move = GameIconData(paths: ['M4 20L20 4', 'M12 4h8v8']);

  static const attack = GameIconData(
    paths: ['M5 19L19 5', 'M14 5l5 5', 'M7 17l-2 4 4-2'],
  );

  static const activityLog = GameIconData(
    paths: ['M8 6h12', 'M8 12h12', 'M8 18h12', 'M4 6h1', 'M4 12h1', 'M4 18h1'],
  );

  static const diplomacy = GameIconData(
    paths: [
      'M7 12l3-3 3 3',
      'M11 10l2-2 4 4',
      'M3 12l4-4 4 4-4 4-4-4z',
      'M21 12l-4-4-4 4 4 4 4-4z',
      'M8 16l2 2c1 1 3 1 4 0l2-2',
    ],
  );

  static const food = GameIconData(
    paths: [
      'M8 3v6a2 2 0 0 0 2 2h0',
      'M6 3v4',
      'M10 3v4',
      'M9 11v10',
      'M17 3c-2 3-2 6 0 10v8',
    ],
  );

  static const production = GameIconData(
    paths: [
      'M3 17l7-7',
      'M11 4l-3 3 4 4 3-3a2.8 2.8 0 0 0-4-4z',
      'M21 7l-4 4 2 2 4-4',
      'M13 11l8 8-2 2-8-8',
    ],
  );

  static const improvement = GameIconData(
    paths: [
      'M4 18l6-6',
      'M11 6l-3 3 4 4 3-3a2.6 2.6 0 0 0-4-4z',
      'M15 12l5 5',
      'M18 14l2 2-3 3-2-2',
    ],
  );

  static const shovel = GameIconData(
    paths: ['M4 20l7-7', 'M9 15l5 5', 'M13 4l7 7-3 3-7-7 3-3z', 'M10 7l7 7'],
  );

  static const storeArtifact = GameIconData(
    paths: [
      'M4 20V10l8-6 8 6v10',
      'M8 20v-5h8v5',
      'M4 20h16',
      'M6 7h7',
      'M10 4l3 3-3 3',
    ],
  );

  static const gold = GameIconData(
    paths: [
      'M 20 12 A 8 8 0 1 1 4 12 A 8 8 0 1 1 20 12 Z',
      'M 16 12 A 4 4 0 1 1 8 12 A 4 4 0 1 1 16 12 Z',
    ],
  );

  static const commerce = GameIconData(
    paths: [
      'M 20 12 A 8 8 0 1 1 4 12 A 8 8 0 1 1 20 12 Z',
      'M9 9h5a2 2 0 0 1 0 4h-4',
      'M10 13h5',
      'M12 6v12',
    ],
  );

  static const resources = GameIconData(
    paths: ['M12 3l7 5v8l-7 5-7-5V8l7-5z', 'M12 3v18', 'M5 8l7 5 7-5'],
  );

  static const artifact = GameIconData(
    paths: [
      'M12 3l7 4v6c0 4-2.8 7-7 8-4.2-1-7-4-7-8V7l7-4z',
      'M12 7l2 4 4 1-3 3 1 4-4-2-4 2 1-4-3-3 4-1 2-4z',
    ],
  );

  static const victory = GameIconData(
    paths: [
      'M8 21h8',
      'M10 17h4v4',
      'M7 4h10v5a5 5 0 0 1-10 0V4z',
      'M17 6h3c0 3-1.5 5-4 5',
      'M7 6H4c0 3 1.5 5 4 5',
    ],
  );

  static const terrain = GameIconData(
    paths: ['M3 20h18', 'M5 18l5-9 4 5 2-3 3 7', 'M10 9l2 9'],
  );

  static const layers = GameIconData(
    paths: ['M12 3l9 5-9 5-9-5 9-5z', 'M4 12l8 4 8-4', 'M4 16l8 4 8-4'],
  );

  static const population = GameIconData(
    paths: [
      'M9 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6',
      'M17 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5',
      'M3 20c1-4 4-6 6-6s5 2 6 6',
      'M13 20c.7-2.6 2.5-4 4-4s3.3 1.4 4 4',
    ],
  );

  static const growth = GameIconData(
    paths: ['M5 18c6 0 11-5 11-11', 'M16 7h-5', 'M16 7v5', 'M5 18h14'],
  );

  static const workedHexes = GameIconData(
    paths: [
      'M8 2.75L12 5v4.5l-4 2.25-4-2.25V5l4-2.25z',
      'M16 2.75L20 5v4.5l-4 2.25-4-2.25V5l4-2.25z',
      'M12 10.25l4 2.25V17l-4 2.25L8 17v-4.5l4-2.25z',
    ],
  );

  static const defense = GameIconData(
    paths: ['M12 3l8 3v6c0 4-3 7-8 9-5-2-8-5-8-9V6l8-3z'],
  );

  static const heartPlus = GameIconData(
    paths: [
      'M12 20C8 16 4 13.5 4 9.5C4 7 6 5 8.5 5C10 5 11.2 5.8 12 7C12.8 5.8 14 5 15.5 5C18 5 20 7 20 9.5C20 13.5 16 16 12 20Z',
      'M17 8v6',
      'M14 11h6',
    ],
  );

  static const science = GameIconData(
    paths: [
      'M12 3v6',
      'M9 21h6',
      'M10 9h4l4 9a2 2 0 0 1-1.8 3H7.8A2 2 0 0 1 6 18l4-9',
      'M8.5 16h7',
    ],
  );

  static const stats = GameIconData(
    paths: [
      'M4 19h16',
      'M6 19V6',
      'M9 19v-4',
      'M13 19v-7',
      'M17 19v-10',
      'M7.5 13.5l3.5-3 3 2 4-6',
      'M7.5 13.5h.01',
      'M11 10.5h.01',
      'M14 12.5h.01',
      'M18 6.5h.01',
    ],
  );

  static const info = GameIconData(
    paths: [
      'M 21 12 A 9 9 0 1 1 3 12 A 9 9 0 1 1 21 12 Z',
      'M12 11v6',
      'M12 7v.2',
    ],
  );

  static const help = GameIconData(
    paths: [
      'M 21 12 A 9 9 0 1 1 3 12 A 9 9 0 1 1 21 12 Z',
      'M9.5 9a2.8 2.8 0 0 1 5 1.7c0 2-2.5 2.2-2.5 4',
      'M12 18v.2',
    ],
  );

  static const warning = GameIconData(
    paths: ['M12 3l9 17H3L12 3z', 'M12 9v5', 'M12 17v.2'],
  );

  static const error = GameIconData(
    paths: [
      'M 21 12 A 9 9 0 1 1 3 12 A 9 9 0 1 1 21 12 Z',
      'M8 8l8 8',
      'M16 8l-8 8',
    ],
  );

  static const checkCircle = GameIconData(
    paths: ['M 21 12 A 9 9 0 1 1 3 12 A 9 9 0 1 1 21 12 Z', 'M8 12l3 3 5-6'],
  );

  static const close = GameIconData(paths: ['M6 6l12 12', 'M18 6L6 18']);

  static const minus = GameIconData(paths: ['M5 12h14']);

  static const back = GameIconData(paths: ['M19 12H5', 'M12 5l-7 7 7 7']);

  static const split = GameIconData(
    paths: ['M5 6h4c4 0 6 2 6 6v6', 'M15 12l4-4', 'M15 12l4 4', 'M5 18h4'],
  );

  static const focus = GameIconData(
    paths: ['M4 9V4h5', 'M15 4h5v5', 'M20 15v5h-5', 'M9 20H4v-5', 'M9 12h6'],
  );

  static const lightning = GameIconData(
    paths: ['M13 2L5 14h6l-1 8 9-13h-6l0-7z'],
    filled: true,
  );

  static const foundCity = GameIconData(
    paths: ['M5 3v18h2v-8h10l-2-4 2-4H7V3H5z'],
    filled: true,
  );

  static const flag = foundCity;

  static const hourglass = GameIconData(
    paths: [
      'M7 3h10',
      'M7 21h10',
      'M8 3C8 8 16 8 16 12C16 16 8 16 8 21',
      'M16 3C16 8 8 8 8 12C8 16 16 16 16 21',
    ],
  );

  static const skipTurn = GameIconData(
    paths: ['M5 5l7 7-7 7', 'M12 5l7 7-7 7', 'M20 5v14'],
  );

  static const arrowRight = GameIconData(paths: ['M5 12h14', 'M12 5l7 7-7 7']);

  static const chevronDown = GameIconData(paths: ['M6 9l6 6 6-6']);

  static const chevronUp = GameIconData(paths: ['M6 15l6-6 6 6']);

  static const settings = GameIconData(
    paths: [
      'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8',
      'M4 12h2',
      'M18 12h2',
      'M12 4v2',
      'M12 18v2',
      'M6.3 6.3l1.4 1.4',
      'M16.3 16.3l1.4 1.4',
      'M17.7 6.3l-1.4 1.4',
      'M7.7 16.3l-1.4 1.4',
    ],
  );

  static const visibility = GameIconData(
    paths: [
      'M3 12C5 8 8 6 12 6C16 6 19 8 21 12C19 16 16 18 12 18C8 18 5 16 3 12',
      'M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6',
    ],
  );

  static const visibilityOff = GameIconData(
    paths: [
      'M4 4l16 16',
      'M3 12C5 8 8 6 12 6c1.2 0 2.3.3 3.3.8',
      'M20.7 12.6C19.6 14.2 16.5 18 12 18c-1.3 0-2.5-.3-3.6-.8',
    ],
  );

  static const water = GameIconData(
    paths: [
      'M3 14c2-2 4-2 6 0s4 2 6 0 4-2 6 0',
      'M3 19c2-2 4-2 6 0s4 2 6 0 4-2 6 0',
    ],
  );

  static const route = GameIconData(
    paths: ['M5 18c4-8 10-4 14-12', 'M6 18h-3v3', 'M18 6h3V3'],
  );

  static const leaf = GameIconData(
    paths: ['M5 19C5 10 11 4 20 4c0 9-6 15-15 15z', 'M5 19c4-4 8-7 13-10'],
  );

  static const forest = GameIconData(
    paths: ['M8 4l-4 7h3l-3 6h4v3', 'M16 4l4 7h-3l3 6h-4v3'],
  );

  static const snow = GameIconData(
    paths: [
      'M12 3v18',
      'M5 7l14 10',
      'M19 7L5 17',
      'M8 5l4 4 4-4',
      'M8 19l4-4 4 4',
    ],
  );

  static const fish = GameIconData(
    paths: ['M4 12c3-4 8-5 13-1l4-3v8l-4-3c-5 4-10 3-13-1z', 'M8 12h.2'],
  );

  static const ship = GameIconData(
    paths: ['M4 16l2 4h12l2-4H4z', 'M8 16V5l8 4v7', 'M8 9h8'],
  );

  static const touch = GameIconData(
    paths: [
      'M9 11V5a2 2 0 0 1 4 0v7',
      'M13 9h1a2 2 0 0 1 2 2v1',
      'M16 11h1a2 2 0 0 1 2 2v4c0 3-2 5-5 5h-2c-2 0-4-1-5-3l-2-4a1.7 1.7 0 0 1 3-1l1 2',
    ],
  );
}
