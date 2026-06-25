import 'package:aonw_core/ai/civilization/persona_weights.dart';

enum AiPersona { balanced, aggressive, expansive, economic, scientific }

extension AiPersonaWeights on AiPersona {
  double get aggression => switch (this) {
    AiPersona.aggressive => 1.35,
    AiPersona.expansive => 0.9,
    AiPersona.economic => 0.8,
    AiPersona.scientific => 0.85,
    AiPersona.balanced => 1.0,
  };

  double get expansion => switch (this) {
    AiPersona.expansive => 1.35,
    AiPersona.aggressive => 0.95,
    AiPersona.economic => 1.05,
    AiPersona.scientific => 0.95,
    AiPersona.balanced => 1.0,
  };

  double get economy => switch (this) {
    AiPersona.economic => 1.35,
    AiPersona.aggressive => 0.85,
    AiPersona.expansive => 1.05,
    AiPersona.scientific => 1.05,
    AiPersona.balanced => 1.0,
  };

  double get science => switch (this) {
    AiPersona.scientific => 1.35,
    AiPersona.aggressive => 0.85,
    AiPersona.expansive => 0.95,
    AiPersona.economic => 1.05,
    AiPersona.balanced => 1.0,
  };

  PersonaWeights get weights {
    return PersonaWeights(
      aggression: aggression,
      expansion: expansion,
      economy: economy,
      science: science,
    );
  }
}
