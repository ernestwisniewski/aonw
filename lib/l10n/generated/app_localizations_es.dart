// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String defaultPlayerName(int index) {
    return 'Jugador $index';
  }

  @override
  String defaultCityName(int index) {
    return 'Ciudad $index';
  }

  @override
  String get newGameTitle => 'NUEVA PARTIDA';

  @override
  String get gameModeSinglePlayerMenuLabel => 'Un jugador';

  @override
  String get gameModeMultiplayerMenuLabel => 'Multijugador';

  @override
  String get gameModeHotSeatMenuLabel => 'Turnos locales';

  @override
  String get gameModeSinglePlayerSummaryLabel => 'Un jugador';

  @override
  String get gameModeMultiplayerSummaryLabel => 'Multijugador';

  @override
  String get gameModeHotSeatSummaryLabel => 'Turnos locales';

  @override
  String get gameModeSinglePlayerMapTitle =>
      'Elige un mapa para jugar en solitario';

  @override
  String get gameModeMultiplayerMapTitle => 'Elige un mapa para jugar en línea';

  @override
  String get gameModeHotSeatMapTitle =>
      'Elige un mapa para jugar por turnos locales';

  @override
  String get gameModeSinglePlayerMapSubtitle =>
      'Una partida local contra la IA.';

  @override
  String get gameModeMultiplayerMapSubtitle =>
      'Escenario inicial y mapa mundial para una partida en línea.';

  @override
  String get gameModeHotSeatMapSubtitle =>
      'Escenario inicial y mapa mundial para jugar por turnos locales en un solo dispositivo.';

  @override
  String get newGameIntroTitle => 'Prepara la expedición';

  @override
  String get newGameIntroSubtitle =>
      'Elige primero el estilo de juego, luego el mapa y después ajusta los jugadores y el ritmo de la partida.';

  @override
  String get newGameStepPlan => 'Plan de juego';

  @override
  String get newGameStepMap => 'Mapa';

  @override
  String get newGameStepReview => 'Revisión';

  @override
  String get newGamePlanTitle => '¿Qué historia quieres comenzar?';

  @override
  String get newGamePremiseTitle => 'Del asentamiento al imperio';

  @override
  String get newGamePremiseBody =>
      'Cada partida empieza con unas pocas decisiones decisivas: dónde fundar la primera ciudad, cómo orientar la investigación, cuándo arriesgarse a expandirse y cómo mantener el control del mapa.';

  @override
  String get newGameCountryTitle => 'Elige civilización';

  @override
  String get newGameCountrySubtitle =>
      'El nombre de tu gobernante sigue a la civilización que elijas.';

  @override
  String get newGameSinglePlayerSettingsTitle => 'Ajustes de la partida';

  @override
  String get newGameGameLengthLabel => 'Duración de la partida';

  @override
  String get newGameLeaderLabel => 'LÍDER';

  @override
  String get newGamePillarCities => 'Ciudades';

  @override
  String get newGamePillarUnits => 'Unidades';

  @override
  String get newGamePillarResearch => 'Investigación';

  @override
  String get newGameVictoryTypesTitle => 'Rutas de victoria';

  @override
  String get newGameVictoryDominationTitle => 'Dominación';

  @override
  String newGameVictoryDominationBody(String controlPercent, int holdTurns) {
    return 'Controla el $controlPercent% del mapa y mantenlo durante $holdTurns turnos. La conquista aún puede terminar la partida eliminando a los rivales.';
  }

  @override
  String get newGameVictoryArtifactsTitle => 'Artefactos';

  @override
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns) {
    return 'Coloca $artifactCount artefactos mundiales únicos en tus ciudades y conserva la colección completa durante $holdTurns turnos.';
  }

  @override
  String get newGameModeSinglePlayerDescription =>
      'Una partida tranquila contra la IA. Ideal para aprender sistemas, probar inicios y experimentar con el crecimiento.';

  @override
  String get newGameModeMultiplayerDescription =>
      'Una partida en línea con sala de red, preparación de jugadores y una entrada compartida al mapa.';

  @override
  String get newGameModeMultiplayerAlphaDisabled =>
      'No disponible en la versión alfa.';

  @override
  String get newGameModeHotSeatDescription =>
      'Juego por turnos locales en un solo dispositivo. Los jugadores se pasan el turno mientras la pantalla guía cada entrega.';

  @override
  String get newGameMapTitle => 'Elige el mundo';

  @override
  String get newGameMapSubtitle =>
      'El mapa define el ritmo del primer contacto, los recursos disponibles, el espacio para ciudades y la forma del conflicto.';

  @override
  String get newGameReviewTitle => 'Confirma la expedición';

  @override
  String get newGameReviewSubtitle =>
      'Tras confirmar, entrarás en la sala para definir el nombre de la partida, su duración y los jugadores.';

  @override
  String newGameReviewSinglePlayerSubtitle(int aiCount) {
    return 'El modo de un jugador empieza inmediatamente contigo y $aiCount jugadores de IA.';
  }

  @override
  String get newGameReviewMissingMap =>
      'Elige un mapa antes de configurar los jugadores.';

  @override
  String get newGameExpeditionReady => 'Expedición lista';

  @override
  String get newGameSelectedMapLabel => 'Mapa';

  @override
  String get newGameMapPickLabel => 'Selección de mapa';

  @override
  String get newGameMapPickRandom => 'Aleatorio predeterminado';

  @override
  String get newGameMapPickManual => 'Elegido manualmente';

  @override
  String get newGameWorldSourceLabel => 'Fuente';

  @override
  String newGameSinglePlayerAiSummary(int aiCount) {
    return 'Tú + $aiCount IA';
  }

  @override
  String get newGameChangeMapAction => 'Cambiar mapa';

  @override
  String get newGameStartSetupAction => 'Ir a la sala';

  @override
  String get mainMenuLoadGame => 'Cargar partida';

  @override
  String get mainMenuDeveloper => 'Herramientas';

  @override
  String get mainMenuSettings => 'Ajustes';

  @override
  String get mainMenuSettingsSublabel => 'Texto y audio';

  @override
  String get mainMenuExit => 'Salir';

  @override
  String get mainMenuAiSublabel => 'IA';

  @override
  String get mainMenuOnlineSublabel => 'Red';

  @override
  String get mainMenuLocalSublabel => 'Local';

  @override
  String get mainMenuToolsSublabel => 'Editores';

  @override
  String get mainMenuToolsTitle => 'Herramientas';

  @override
  String get mainMenuMapEditor => 'Editor de mapas';

  @override
  String get mainMenuAssetsEditor => 'Editor de recursos';

  @override
  String get mainMenuTextSize => 'Tamaño del texto';

  @override
  String get mainMenuTextSample => 'Texto de juego de ejemplo';

  @override
  String get mainMenuManual => 'Manual';

  @override
  String get mainMenuCredits => 'Créditos';

  @override
  String get mainMenuFeedback => 'Comentarios';

  @override
  String get manualTitle => 'Manual de controles';

  @override
  String get manualSubtitle =>
      'Una referencia rápida para movimiento del mapa, selección, órdenes, paneles y flujo de turnos en escritorio y móvil.';

  @override
  String get manualMetaDesktop => 'Escritorio';

  @override
  String get manualMetaMobile => 'Móvil';

  @override
  String get manualMetaAlpha => 'Alfa para un jugador';

  @override
  String get manualCommandLoopTitle => 'Bucle de mando principal';

  @override
  String get manualCommandLoopSelectTitle => 'Seleccionar';

  @override
  String get manualCommandLoopSelectBody =>
      'Elige una unidad, ciudad, artefacto o casilla del mapa para revelar las acciones importantes ahora.';

  @override
  String get manualCommandLoopPreviewTitle => 'Vista previa';

  @override
  String get manualCommandLoopPreviewBody =>
      'Pasa el cursor o toca una vez para inspeccionar objetivos, colores de intención, rutas y acciones bloqueadas.';

  @override
  String get manualCommandLoopConfirmTitle => 'Confirmar';

  @override
  String get manualCommandLoopConfirmBody =>
      'Usa una ficha de acción o vuelve a elegir el objetivo resaltado para ejecutar la orden.';

  @override
  String get manualCommandLoopAdvanceTitle => 'Avanzar';

  @override
  String get manualCommandLoopAdvanceBody =>
      'Usa el botón de acción inferior para saltar a la siguiente decisión o terminar el turno.';

  @override
  String get manualDesktopTitle => 'Controles de escritorio';

  @override
  String get manualDesktopSubtitle =>
      'Juego centrado en el ratón con inspección rápida del mapa, selección precisa de objetivos y paneles persistentes.';

  @override
  String get manualMobileTitle => 'Controles móviles';

  @override
  String get manualMobileSubtitle =>
      'Juego táctil ajustado para paneles legibles, órdenes deliberadas y flujo de turnos rápido.';

  @override
  String get manualMapCameraGroup => 'Mapa y cámara';

  @override
  String get manualOrdersGroup => 'Selección y órdenes';

  @override
  String get manualPanelsGroup => 'Paneles y ayuda';

  @override
  String get manualTurnFlowGroup => 'Flujo de turnos';

  @override
  String get manualDesktopLeftClickAction => 'Clic izquierdo';

  @override
  String get manualDesktopLeftClickBody =>
      'Selecciona unidades, ciudades, artefactos y casillas; con una orden activa, elige el objetivo.';

  @override
  String get manualDesktopDragAction => 'Arrastrar el mapa';

  @override
  String get manualDesktopDragBody =>
      'Desplaza la cámara sin cambiar la selección actual ni el modo de mando.';

  @override
  String get manualDesktopZoomAction => 'Rueda del ratón / trackpad';

  @override
  String get manualDesktopZoomBody =>
      'Acerca o aleja entre la vista estratégica general y el detalle táctico del mapa.';

  @override
  String get manualDesktopHoverAction => 'Pasar el cursor';

  @override
  String get manualDesktopHoverBody =>
      'Previsualiza ayudas emergentes, pistas de objetivo y motivos de órdenes bloqueadas antes de confirmar.';

  @override
  String get manualDesktopActionChipsAction => 'Fichas de acción';

  @override
  String get manualDesktopActionChipsBody =>
      'Mover, atacar, mejorar, fundar una ciudad, omitir, fortificar o cancelar el modo actual.';

  @override
  String get manualDesktopSecondClickAction => 'Mismo objetivo dos veces';

  @override
  String get manualDesktopSecondClickBody =>
      'Para moverte, el primer clic muestra la ruta; el segundo la ejecuta o la pone en cola.';

  @override
  String get manualDesktopHoldAction => 'Clic mantenido';

  @override
  String get manualDesktopHoldBody =>
      'Abre explicaciones detalladas de órdenes, opciones desactivadas y fichas contextuales.';

  @override
  String get manualDesktopRailAction => 'Barra izquierda';

  @override
  String get manualDesktopRailBody =>
      'Abre opciones del mapa, ayuda, objetivos, registro de actividad, investigación y paneles del imperio.';

  @override
  String get manualDesktopTopPillsAction => 'Recursos superiores';

  @override
  String get manualDesktopTopPillsBody =>
      'Inspecciona los desgloses de economía, ciencia, recursos y presión de victoria.';

  @override
  String get manualDesktopCloseAction => 'Clic fuera';

  @override
  String get manualDesktopCloseBody =>
      'Cierra ventanas emergentes, paneles de opciones y tarjetas de ayuda, y devuelve el foco al mapa.';

  @override
  String get manualDesktopHelpAction => '?';

  @override
  String get manualDesktopHelpBody =>
      'Abre en cualquier momento todas las pistas minimizadas y tarjetas de tutorial, sin importar la selección.';

  @override
  String get manualDesktopTurnAction => 'Siguiente decisión';

  @override
  String get manualDesktopTurnBody =>
      'Enfoca la siguiente unidad, investigación o elección de ciudad; termina el turno cuando nada bloquee el progreso.';

  @override
  String get manualMobileTapAction => 'Tocar';

  @override
  String get manualMobileTapBody =>
      'Selecciona unidades, ciudades, artefactos y casillas; con una orden activa, elige el objetivo.';

  @override
  String get manualMobileDragAction => 'Arrastrar con un dedo';

  @override
  String get manualMobileDragBody =>
      'Desplaza la cámara manteniendo intactos la unidad seleccionada o el estado del panel.';

  @override
  String get manualMobilePinchAction => 'Pellizcar';

  @override
  String get manualMobilePinchBody =>
      'Acerca o aleja el mapa para explorar, gestionar ciudades, planificar movimientos o apuntar en combate.';

  @override
  String get manualMobileSecondTapAction => 'Mismo objetivo dos veces';

  @override
  String get manualMobileSecondTapBody =>
      'Previsualiza primero una ruta de movimiento y toca de nuevo el mismo hexágono para ejecutarla o ponerla en cola.';

  @override
  String get manualMobileActionChipsAction => 'Fichas de acción';

  @override
  String get manualMobileActionChipsBody =>
      'Usa la fila inferior de órdenes para unidades, decisiones de ciudad, trabajadores y acciones de cancelación.';

  @override
  String get manualMobileHoldAction => 'Mantener pulsado';

  @override
  String get manualMobileHoldBody =>
      'Abre explicaciones de órdenes, opciones desactivadas, recursos e interfaz contextual.';

  @override
  String get manualMobileScrollAction => 'Desplazar paneles';

  @override
  String get manualMobileScrollBody =>
      'Navega por listas largas de ciudad, investigación, registro, diplomacia y ayuda sin perder el estado del mapa.';

  @override
  String get manualMobileRailAction => 'Barra izquierda';

  @override
  String get manualMobileRailBody =>
      'Toca para abrir opciones del mapa, ayuda, objetivos, registro de actividad, investigación y paneles del imperio.';

  @override
  String get manualMobileHelpAction => '?';

  @override
  String get manualMobileHelpBody =>
      'Consulta cualquier tarjeta minimizada de pista o tutorial cuando necesites un recordatorio.';

  @override
  String get manualMobileTurnAction => 'Acción inferior';

  @override
  String get manualMobileTurnBody =>
      'Salta a la siguiente decisión requerida o termina el turno cuando se hayan gastado todos los puntos de acción.';

  @override
  String get mainMenuWhatsNew => 'Novedades';

  @override
  String get mainMenuWhatsNewBody =>
      'Bienvenido a Age of New Worlds. Construye ciudades, dirige comandantes, descubre nuevas tierras y escribe la historia de tu civilización.';

  @override
  String get gameModeLabel => 'MODO';

  @override
  String get gameNameLabel => 'NOMBRE DE LA PARTIDA';

  @override
  String get playersLabel => 'JUGADORES';

  @override
  String get countryLabel => 'PAÍS';

  @override
  String get countryPoland => 'Polonia';

  @override
  String get countryUkraine => 'Ucrania';

  @override
  String get countryGermany => 'Alemania';

  @override
  String get countryFrance => 'Francia';

  @override
  String get countryUnitedKingdom => 'Reino Unido';

  @override
  String get countryItaly => 'Italia';

  @override
  String get countrySpain => 'España';

  @override
  String get countryNetherlands => 'Países Bajos';

  @override
  String get countrySweden => 'Suecia';

  @override
  String get countryRussia => 'Rusia';

  @override
  String get countryUnitedStates => 'Estados Unidos';

  @override
  String get countryCanada => 'Canadá';

  @override
  String get countryChina => 'China';

  @override
  String get countryKorea => 'Corea';

  @override
  String get countryJapan => 'Japón';

  @override
  String get countryPortugal => 'Portugal';

  @override
  String get countryLeaderPoland => 'Casimiro III el Grande';

  @override
  String get countryLeaderUkraine => 'Yaroslav el Sabio';

  @override
  String get countryLeaderGermany => 'Otto von Bismarck';

  @override
  String get countryLeaderFrance => 'Napoleón Bonaparte';

  @override
  String get countryLeaderUnitedKingdom => 'Reina Victoria';

  @override
  String get countryLeaderItaly => 'Julio César';

  @override
  String get countryLeaderSpain => 'Isabel I';

  @override
  String get countryLeaderNetherlands => 'Guillermo de Orange';

  @override
  String get countryLeaderSweden => 'Gustavo Adolfo';

  @override
  String get countryLeaderRussia => 'Catalina la Grande';

  @override
  String get countryLeaderUnitedStates => 'Abraham Lincoln';

  @override
  String get countryLeaderCanada => 'Wilfrid Laurier';

  @override
  String get countryLeaderChina => 'Qin Shi Huang';

  @override
  String get countryLeaderKorea => 'Sejong el Grande';

  @override
  String get countryLeaderJapan => 'Tokugawa Ieyasu';

  @override
  String get countryLeaderPortugal => 'Enrique el Navegante';

  @override
  String get addPlayerAction => '+ AÑADIR JUGADOR';

  @override
  String get startGameAction => 'EMPEZAR';

  @override
  String get removePlayerTooltip => 'Eliminar jugador';

  @override
  String get multiplayerSearchTitle => 'BÚSQUEDA DE SERVIDOR';

  @override
  String get multiplayerSearchBody =>
      'La lista de partidas en línea aparecerá aquí.';

  @override
  String get multiplayerPlayersTitle => 'Jugadores';

  @override
  String get multiplayerStatusTooltip => 'Estado del jugador';

  @override
  String multiplayerAvatarTooltip(String playerName, String status) {
    return '$playerName - $status';
  }

  @override
  String multiplayerAvatarTooltipWithRelation(
    String playerName,
    String status,
    String relation,
  ) {
    return '$playerName - $status\nRelaciones: $relation';
  }

  @override
  String multiplayerPlayerTooltip(String playerName, String defaultName) {
    return '$playerName\n$defaultName';
  }

  @override
  String multiplayerPlayerTooltipWithRelation(
    String playerName,
    String defaultName,
    String relation,
  ) {
    return '$playerName\n$defaultName\nRelaciones: $relation';
  }

  @override
  String get multiplayerStatusActive => 'jugando ahora';

  @override
  String get multiplayerStatusSubmitted => 'turno enviado';

  @override
  String get multiplayerStatusThinking => 'pensando';

  @override
  String get multiplayerStatusWaiting => 'esperando';

  @override
  String get multiplayerStatusTimeout => 'tiempo agotado';

  @override
  String get diplomacyRelationFriendly => 'amistosa';

  @override
  String get diplomacyRelationNeutral => 'neutral';

  @override
  String get diplomacyRelationHostile => 'hostil';

  @override
  String get diplomacyRelationTruce => 'tregua';

  @override
  String get diplomacyRelationWar => 'guerra';

  @override
  String get diplomacyRelationFriendlyShort => 'amist.';

  @override
  String get diplomacyRelationNeutralShort => 'neut.';

  @override
  String get diplomacyRelationHostileShort => 'host.';

  @override
  String get diplomacyRelationTruceShort => 'tregua';

  @override
  String get diplomacyRelationWarShort => 'guerra';

  @override
  String get commonDiplomacy => 'Diplomacia';

  @override
  String get diplomacyScoreLabel => 'Relaciones';

  @override
  String get diplomacyScoreDriversTitle => 'Qué cambia las relaciones';

  @override
  String get diplomacyScoreReasonManual => 'Cambio manual';

  @override
  String get diplomacyScoreReasonUnitAttack => 'Ataque a unidad';

  @override
  String get diplomacyScoreReasonCityAttack => 'Ataque a ciudad';

  @override
  String get diplomacyScoreReasonDeclarationOfWar => 'Declaración de guerra';

  @override
  String get diplomacyScoreReasonProposalAccepted => 'Propuesta aceptada';

  @override
  String get diplomacyScoreReasonProposalRejected => 'Propuesta rechazada';

  @override
  String get diplomacyScoreReasonMessageResponse => 'Respuesta a despacho';

  @override
  String get diplomacyScoreReasonPromiseBroken => 'Promesa rota';

  @override
  String get diplomacyStatsTitle => 'Estadísticas';

  @override
  String get diplomacyHistoryTitle => 'Historial';

  @override
  String get diplomacyMessagesTitle => 'Despachos';

  @override
  String get diplomacyIncomingMessageTitle => 'Nuevo despacho';

  @override
  String diplomacyIncomingMessageFrom(String playerName) {
    return 'De: $playerName';
  }

  @override
  String get diplomacyIncomingProposalTitle => 'Nueva propuesta';

  @override
  String diplomacyIncomingProposalFrom(String playerName) {
    return 'De: $playerName';
  }

  @override
  String get diplomacyIncomingMessageLater => 'Más tarde';

  @override
  String get diplomacyActionsTitle => 'Acciones';

  @override
  String get diplomacyProposalsTitle => 'Propuestas';

  @override
  String get diplomacyNoHistory => 'No hay incidentes registrados.';

  @override
  String get diplomacyNoMessages => 'No hay despachos.';

  @override
  String get diplomacyMilitaryStat => 'Militar';

  @override
  String get diplomacyCitiesStat => 'Ciudades';

  @override
  String get diplomacyExpansionStat => 'Expansión';

  @override
  String get diplomacyArtifactsStat => 'Artefactos';

  @override
  String get diplomacyLastAggressionStat => 'Última agresión';

  @override
  String get diplomacyOwnArtifactsLabel => 'Tus artefactos';

  @override
  String get diplomacyTargetArtifactsLabel => 'Artefactos rivales';

  @override
  String diplomacyTurnsRemaining(int turns) {
    return 'Turnos restantes: $turns';
  }

  @override
  String get diplomacyProposalFriendship => 'Propuesta de amistad';

  @override
  String get diplomacyProposalTruce => 'Propuesta de tregua';

  @override
  String get diplomacySendFriendship => 'Proponer amistad';

  @override
  String get diplomacySendTruce => 'Proponer tregua';

  @override
  String get diplomacyDeclareWar => 'Declarar la guerra';

  @override
  String get diplomacyAccept => 'Aceptar';

  @override
  String get diplomacyDecline => 'Rechazar';

  @override
  String get diplomacyMessageTroopsNearCities =>
      'Hay demasiadas tropas posicionadas cerca de mis ciudades.';

  @override
  String get diplomacyMessageCitiesTooClose =>
      'Estás fundando ciudades demasiado cerca de mis fronteras.';

  @override
  String get diplomacyMessageBlockedRoutes =>
      'Tus unidades están bloqueando mis rutas.';

  @override
  String get diplomacyMessageWithdrawScouts =>
      'Retira a tus exploradores de mi territorio, por favor.';

  @override
  String get diplomacyMessageAvoidEscalation =>
      'Nuestras civilizaciones deberían evitar una mayor escalada.';

  @override
  String get diplomacyMessageCommonEnemy =>
      'Un enemigo común nos amenaza a ambos.';

  @override
  String get diplomacyMessageExpansionProvocation =>
      'Tu expansión se considera una provocación.';

  @override
  String get diplomacyMessagePeacefulPraise =>
      'Valoramos las relaciones pacíficas entre nuestros pueblos.';

  @override
  String get diplomacyResponseConciliatory => 'Conciliadora';

  @override
  String get diplomacyResponseNeutral => 'Neutral';

  @override
  String get diplomacyResponseEvasive => 'Evasiva';

  @override
  String get diplomacyResponseAggressive => 'Agresiva';

  @override
  String get diplomacyStrategicResourcesTitle => 'Recursos estratégicos';

  @override
  String get diplomacyResourceTradeBlockedByWar =>
      'El comercio de recursos está bloqueado por la guerra.';

  @override
  String get diplomacyResourceTradeNoAvailableResources =>
      'No hay recursos estratégicos libres para comerciar.';

  @override
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns) {
    return 'Oferta de importación: $goldPerTurn de oro/turno durante $durationTurns turnos.';
  }

  @override
  String diplomacyResourceTradeImportAction(String resourceName) {
    return 'Importar $resourceName';
  }

  @override
  String diplomacyResourceTradeExchangeOffer(int durationTurns) {
    return 'Trueque: recurso por recurso durante $durationTurns turnos.';
  }

  @override
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  ) {
    return 'Cambiar $offeredResource por $requestedResource';
  }

  @override
  String get diplomacyResourceTradeNoActiveAgreements =>
      'No hay acuerdos de recursos activos.';

  @override
  String get diplomacyResourceTradeImportDirection => 'Importas';

  @override
  String get diplomacyResourceTradeExportDirection => 'Exportas';

  @override
  String get diplomacyResourceTradeBarterPrice => 'trueque';

  @override
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn) {
    return '$goldPerTurn de oro/turno';
  }

  @override
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    return '$direction $resourceName · $price · $remainingTurns turnos';
  }

  @override
  String get notFoundScreenTitle => 'Pantalla no encontrada';

  @override
  String get notFoundBackToMenuAction => 'MENÚ';

  @override
  String get loadGameTitle => 'CARGAR PARTIDA';

  @override
  String get loadGameHeaderTitle => 'Partidas guardadas';

  @override
  String get loadGameHeaderEmptySubtitle =>
      'Aún no se ha iniciado ninguna partida.';

  @override
  String get loadGameHeaderSavesSubtitle =>
      'Vuelve a partidas recientes y continúa desde el turno guardado.';

  @override
  String loadGameSavesCount(int count) {
    return 'Guardados: $count';
  }

  @override
  String get loadGameCorruptedStatus => 'Guardado dañado';

  @override
  String get loadGameCorruptedAction => 'No disponible';

  @override
  String get loadGameCorruptedBody =>
      'Este guardado no se puede leer. Puedes eliminarlo de la lista.';

  @override
  String get replayTitle => 'REPETICIÓN';

  @override
  String get replayAction => 'REPETICIÓN';

  @override
  String get replayUnavailableAction => 'SIN REPETICIÓN';

  @override
  String get replayErrorTitle => 'Repetición no disponible';

  @override
  String replayErrorBody(String error) {
    return 'No se puede abrir la repetición: $error';
  }

  @override
  String get replayMissingInitialSnapshotBody =>
      'Este guardado no contiene una instantánea semilla de repetición. Inicia una nueva partida para registrar datos de repetición de toda la partida.';

  @override
  String get replayCorruptLogBody =>
      'El registro de comandos de la repetición está incompleto o no se puede leer.';

  @override
  String replayStepCounter(int step, int total) {
    return 'Paso $step/$total';
  }

  @override
  String endTurnButtonTurnLabel(int turn) {
    return 'TURNO $turn';
  }

  @override
  String replayTurnLabel(int turn) {
    return 'Turno $turn';
  }

  @override
  String replayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
      zero: '0 eventos',
    );
    return '$_temp0';
  }

  @override
  String get replayInitialStateLabel => 'Estado inicial';

  @override
  String get replayPreviousAction => 'Paso anterior';

  @override
  String get replayNextAction => 'Paso siguiente';

  @override
  String get replayPlayAction => 'Reproducir repetición';

  @override
  String get replayPauseAction => 'Pausar repetición';

  @override
  String get replaySpeedLabel => 'Velocidad';

  @override
  String get replayPerspectiveLabel => 'Perspectiva';

  @override
  String get replayAllPlayers => 'Todos los jugadores';

  @override
  String get replayShowTurnsLabel => 'Mostrar turnos';

  @override
  String get replayFreeCameraLabel => 'Cámara libre';

  @override
  String mapsLoadError(String error) {
    return 'No se pudieron cargar los mapas: $error';
  }

  @override
  String get editorMapPickerTitle => 'Mapas del editor';

  @override
  String get editorMapPickerSubtitle =>
      'Crea mundos nuevos o refina mapas existentes.';

  @override
  String get editorMapPickerEmptyTitle => 'No hay mapas guardados';

  @override
  String get editorMapPickerEmptyMessage =>
      'Crea un nuevo mapa desde el encabezado de la pantalla.';

  @override
  String get editorNewMapAction => 'Nuevo mapa';

  @override
  String get editorDeleteMapTooltip => 'Eliminar mapa';

  @override
  String get editorDeleteMapTitle => '¿Eliminar mapa?';

  @override
  String editorDeleteMapMessage(String name) {
    return 'Esto eliminará permanentemente “$name” y todos los archivos del mapa.';
  }

  @override
  String get editorOpenMapErrorTitle => 'No se pudo abrir el mapa';

  @override
  String get editorCollapseToolbarTooltip => 'Contraer panel del editor';

  @override
  String get editorExpandToolbarTooltip => 'Expandir panel del editor';

  @override
  String officialMapsCount(int count) {
    return 'Oficiales: $count';
  }

  @override
  String yourMapsCount(int count) {
    return 'Tuyos: $count';
  }

  @override
  String get officialMapsSection => 'Oficiales';

  @override
  String get yourMapsSection => 'Tus mapas';

  @override
  String get playAction => 'Jugar';

  @override
  String get editAction => 'Editar';

  @override
  String get noMapsTitle => 'No hay mapas';

  @override
  String get noMapsMessage =>
      'No se encontraron mapas para iniciar una partida.';

  @override
  String get gameLengthLabel => 'Duración de la partida';

  @override
  String get gameLengthPresetHint => 'Preajuste de partida';

  @override
  String get gameLengthPresetUnlimited => 'Ilimitada';

  @override
  String get gameLengthPresetShort60 => 'Corta';

  @override
  String get gameLengthPresetNormal90 => 'Normal';

  @override
  String get gameLengthPresetStandard60 => 'Estándar 60 min';

  @override
  String get gameLengthPresetLong120 => 'Larga';

  @override
  String get gameLengthPresetVeryLong => 'Muy larga';

  @override
  String get gameLengthUnlimitedSummary =>
      'Sin límite de turnos - ritmo actual de la partida';

  @override
  String gameLengthTimedSummary(int minutes, int turns) {
    return 'Objetivo de $minutes min - límite de $turns turnos';
  }

  @override
  String get gameLengthScoreFallbackOn => 'con desempate por puntuación';

  @override
  String get gameLengthScoreFallbackOff => 'sin desempate por puntuación';

  @override
  String get aiDifficultyLabel => 'Dificultad de la IA';

  @override
  String get aiDifficultyEasy => 'Fácil';

  @override
  String get aiDifficultyNormal => 'Normal';

  @override
  String get aiDifficultyHard => 'Difícil';

  @override
  String get aiDifficultyVeryHard => 'Muy difícil';

  @override
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  ) {
    return 'Conquista + dominación $controlPercent%/$holdTurns turnos - $fallback';
  }

  @override
  String get mapValidationErrorTitle => 'El mapa necesita correcciones';

  @override
  String get mapValidationLoadingTitle => 'Comprobando mapa';

  @override
  String get mapValidationWarningTitle =>
      'El mapa puede ser demasiado lento para este preajuste';

  @override
  String mapValidationLoadError(String error) {
    return 'No se pudo comprobar el mapa: $error';
  }

  @override
  String get mapValidationLoadingMessage =>
      'Validando inicios, recursos y ritmo del primer contacto.';

  @override
  String get mapValidationIssueSlowFirstContact =>
      'Las posiciones iniciales están muy separadas; 60 min puede retrasar demasiado el primer contacto.';

  @override
  String get mapValidationIssueLargeMap =>
      'El mapa tiene muchas casillas por jugador; añade jugadores o elige una partida más larga.';

  @override
  String get mapValidationIssueInvalidPlayerCount =>
      'El número de jugadores no coincide con el rango admitido por este mapa.';

  @override
  String get mapValidationIssueNoTiles => 'El mapa no tiene casillas.';

  @override
  String get mapValidationIssueLowPassableTileRatio =>
      'El mapa tiene muy pocas casillas transitables por unidades terrestres.';

  @override
  String get mapValidationIssueLowFoodResourceDensity =>
      'El mapa tiene muy pocos recursos de alimento para este número de jugadores.';

  @override
  String get mapValidationIssueLowStrategicResourceDensity =>
      'El mapa tiene muy pocos recursos estratégicos.';

  @override
  String get mapValidationIssueLowLuxuryResourceDensity =>
      'El mapa tiene muy pocos recursos de lujo.';

  @override
  String get mapValidationIssueStartSiteNotFoundable =>
      'El colono inicial no puede fundar una ciudad en su casilla.';

  @override
  String get mapValidationIssueStartSiteLowLandRing =>
      'El inicio tiene muy pocas casillas transitables en el primer anillo.';

  @override
  String get mapValidationIssueStartSiteLowFood =>
      'El inicio no tiene ningún recurso de alimento visible cerca.';

  @override
  String get mapValidationIssueStartSiteLowCityControl =>
      'El inicio tiene muy pocas casillas legales para el control inicial de ciudad.';

  @override
  String get mapValidationIssueStartSitesTooClose =>
      'Los inicios de los jugadores están demasiado cerca entre sí.';

  @override
  String lobbyMapPlayersSummary(String mapName, int playerCount) {
    return '$mapName - $playerCount jugadores';
  }

  @override
  String get lobbyHeaderTitle => 'Prepara la mesa';

  @override
  String get lobbyHeaderSubtitle =>
      'Confirma primero la civilización y luego ajusta la partida y los asientos antes del primer turno.';

  @override
  String get lobbyCivilizationTitle => 'Elige civilización';

  @override
  String get lobbyCivilizationSubtitle =>
      'Esta es la identidad del jugador uno para el turno inicial.';

  @override
  String get lobbyStepCivilization => 'Civilización';

  @override
  String get lobbyStepSetup => 'Configuración';

  @override
  String get lobbyStepOnline => 'En línea';

  @override
  String get lobbyStepPlayers => 'Jugadores';

  @override
  String get lobbySetupTitle => 'Configuración de partida';

  @override
  String get lobbySetupSubtitle =>
      'Pon nombre a la partida, elige el ritmo y comprueba si el mapa encaja con el número de jugadores seleccionado.';

  @override
  String get lobbyPlayersSetupTitle => 'Jugadores en la mesa';

  @override
  String get lobbyPlayersSetupSubtitle =>
      'El primer jugador toma el turno inicial. Los asientos adicionales pueden ser personas en este dispositivo o IA.';

  @override
  String get lobbyPlayerYou => 'Tú';

  @override
  String get lobbyPlayerHost => 'Anfitrión';

  @override
  String get lobbyPlayerReady => 'listo';

  @override
  String get lobbyPlayerConnected => 'conectado';

  @override
  String get lobbyPlayerConnecting => 'conectando';

  @override
  String get lobbyPlayerReconnecting => 'reconectando';

  @override
  String get lobbyPlayerOffline => 'sin conexión';

  @override
  String lobbyPlayerOpenSlot(int slotNumber) {
    return 'Asiento abierto $slotNumber';
  }

  @override
  String get lobbyPlayerRequiredSlot => 'Necesario para empezar';

  @override
  String get lobbyPlayerOptionalSlot => 'Puede unirse antes de empezar';

  @override
  String get playerKindHuman => 'Humano';

  @override
  String get playerKindAi => 'IA';

  @override
  String get multiplayerServerTitle => 'Servidor de partida en línea';

  @override
  String get connectAction => 'Conectar';

  @override
  String get refreshAction => 'Actualizar';

  @override
  String get createMatchAction => 'Crear partida';

  @override
  String get noOpenMatches => 'No hay partidas abiertas';

  @override
  String get matchStatusRunning => 'Lista';

  @override
  String get matchStatusFinished => 'Terminada';

  @override
  String get matchStatusAbandoned => 'Abandonada';

  @override
  String matchPlayersCount(int players, int maxPlayers) {
    return '$players/$maxPlayers jugadores';
  }

  @override
  String matchReadyCount(int readyPlayers, int players) {
    return '$readyPlayers/$players listos';
  }

  @override
  String matchTurnInfo(String mapName, String status, int turn) {
    return '$mapName - $status - turno $turn';
  }

  @override
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn) {
    return '$mapName - $players/$maxPlayers - turno $turn';
  }

  @override
  String get enterMatchAction => 'Entrar';

  @override
  String get hideMatchAction => 'Ocultar';

  @override
  String get joinMatchAction => 'Unirse';

  @override
  String get cancelAction => 'CANCELAR';

  @override
  String get copyAction => 'Copiar';

  @override
  String get shareAction => 'Compartir';

  @override
  String get multiplayerHomeSubtitle =>
      'Elige una cola rápida o una partida privada con código para amigos.';

  @override
  String get multiplayerProfileTitle => 'Tu perfil';

  @override
  String get multiplayerProfileSubtitle =>
      'Define el nombre y la civilización que usarás en partidas en línea.';

  @override
  String get multiplayerProfileOptionsSubtitle =>
      'Tu apodo se usa en partidas multijugador y debe ser único.';

  @override
  String get multiplayerProfileSaveAction => 'Guardar apodo';

  @override
  String get multiplayerProfileSaved => 'Apodo guardado.';

  @override
  String get multiplayerLobbyHeaderTitle => 'Sala en línea';

  @override
  String get multiplayerLobbyHeaderSubtitle =>
      'Elige civilización primero y luego entra en partida rápida o crea una mesa privada. El mapa se selecciona automáticamente.';

  @override
  String get multiplayerCountryPickTitle => 'Elige civilización';

  @override
  String get multiplayerCountryPickSubtitle =>
      'Esta es la elección clave antes de entrar en la cola. Los mapas multijugador se seleccionan al azar.';

  @override
  String get multiplayerRandomMapLabel => 'Mapa aleatorio';

  @override
  String get multiplayerNicknameLabel => 'Apodo';

  @override
  String get multiplayerQuickplayTitle => 'Partida rápida';

  @override
  String get multiplayerQuickplaySubtitle =>
      'Encuentra jugadores automáticamente y empieza desde 2 jugadores.';

  @override
  String get multiplayerCreatePrivateTitle => 'Crear código';

  @override
  String get multiplayerCreatePrivateSubtitle =>
      'Partida privada sin límite de tiempo, solo para amigos.';

  @override
  String get multiplayerJoinPrivateTitle => 'Unirse con código';

  @override
  String get multiplayerJoinPrivateSubtitle =>
      'Introduce el código de un amigo y espera al anfitrión.';

  @override
  String get multiplayerQueueReadyTitle => 'Partida lista';

  @override
  String get multiplayerQueueSearchingTitle => 'Buscando jugadores';

  @override
  String get multiplayerQueueCountdownTitle => 'Empezando pronto';

  @override
  String get multiplayerQueueConnectingSubtitle =>
      'Conectando al servidor y buscando una cola.';

  @override
  String multiplayerQueueWaitingForPlayers(int minPlayers) {
    return 'Esperando al menos $minPlayers jugadores.';
  }

  @override
  String get multiplayerQueuePreparingStart =>
      'Jugadores encontrados. Preparando el inicio de la partida.';

  @override
  String get multiplayerQueueStartingNow => 'Iniciando partida...';

  @override
  String multiplayerQueueStartingIn(int seconds) {
    return 'Empieza en ${seconds}s. Aún pueden unirse más jugadores.';
  }

  @override
  String get multiplayerPrivateTitle => 'Partida entre amigos';

  @override
  String get multiplayerPrivateHostReady => 'Ya puedes iniciar la partida.';

  @override
  String get multiplayerPrivateWaitingForHost =>
      'Esperando a que el anfitrión inicie la partida.';

  @override
  String get multiplayerJoinCodeHelp =>
      'Introduce el código que recibiste de un amigo.';

  @override
  String get multiplayerInviteCodeHint => 'Código de partida';

  @override
  String get multiplayerInviteCodeLabel => 'Código de partida';

  @override
  String get multiplayerInviteCopied => 'Código de partida copiado.';

  @override
  String multiplayerInviteShareText(String inviteCode) {
    return 'Únete a mi partida de AONW. Código: $inviteCode';
  }

  @override
  String get multiplayerInviteCodeRequired => 'Introduce un código de partida.';

  @override
  String get multiplayerMapNotReady =>
      'Este mapa no está listo para multijugador.';

  @override
  String multiplayerRequestRejected(int statusCode) {
    return 'El servidor rechazó la solicitud ($statusCode).';
  }

  @override
  String multiplayerRequestRejectedWithReason(int statusCode, String reason) {
    return 'El servidor rechazó la solicitud ($statusCode: $reason).';
  }

  @override
  String multiplayerConnectionError(String host) {
    return 'No se pudo conectar con $host. Comprueba tu conexión a internet e inténtalo de nuevo.';
  }

  @override
  String get multiplayerSignInRequired =>
      'Inicia sesión o crea una cuenta para jugar en multijugador.';

  @override
  String get multiplayerSessionExpired =>
      'Tu sesión multijugador ha caducado. Inicia sesión de nuevo y vuelve a intentarlo.';

  @override
  String get multiplayerAccountTitle => 'Cuenta multijugador';

  @override
  String get multiplayerAccountSubtitle =>
      'Inicia sesión o crea una cuenta para continuar.';

  @override
  String get multiplayerAccountEmailLabel => 'Email';

  @override
  String get multiplayerAccountPasswordLabel => 'Contraseña';

  @override
  String get multiplayerAccountSignInTab => 'Iniciar sesión';

  @override
  String get multiplayerAccountCreateTab => 'Crear cuenta';

  @override
  String get multiplayerAccountSignInAction => 'Iniciar sesión';

  @override
  String get multiplayerAccountCreateAction => 'Crear cuenta';

  @override
  String get multiplayerAccountSignOutAction => 'Cerrar sesión';

  @override
  String get multiplayerAccountSignedOut => 'Sesión multijugador cerrada.';

  @override
  String get multiplayerAccountInvalidEmail => 'Introduce un email válido.';

  @override
  String get multiplayerAccountInvalidCredentials =>
      'Email o contraseña no válidos.';

  @override
  String get multiplayerAccountExists => 'Ya existe una cuenta con este email.';

  @override
  String get multiplayerAccountWeakPassword =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get multiplayerAccountInvalidNickname =>
      'Usa 3-24 letras, números, espacios, _ o -.';

  @override
  String get multiplayerAccountNicknameTaken => 'Este apodo ya está en uso.';

  @override
  String get multiplayerAccountGenericError =>
      'No se pudo autenticar. Inténtalo de nuevo.';

  @override
  String get multiplayerMatchUnavailable =>
      'Esta partida ya no está disponible.';

  @override
  String get multiplayerMatchFull => 'Esta partida está llena.';

  @override
  String get multiplayerCountryUnavailable =>
      'Varios jugadores eligieron tu civilización. Prueba otra.';

  @override
  String get multiplayerMatchNotReady =>
      'La partida aún no está lista para empezar.';

  @override
  String get multiplayerMatchAccessDenied => 'No eres jugador en esta partida.';

  @override
  String get multiplayerQueueGenericError =>
      'No se pudo entrar en la cola multijugador. Inténtalo de nuevo.';

  @override
  String get multiplayerResumeAction => 'Reanudar partida';

  @override
  String get multiplayerResumeSublabel =>
      'Volver a la última sesión multijugador';

  @override
  String get multiplayerResumeLoading => 'Conectando a la partida...';

  @override
  String get multiplayerResumeFailed =>
      'No se pudo reanudar la última sesión multijugador.';

  @override
  String get optionsTooltip => 'Opciones';

  @override
  String get optionsOpenMenuTooltip => 'Abrir menú';

  @override
  String optionsTooltipWithCollapseHint(String tooltip) {
    return '$tooltip. Mantén pulsado para contraer el menú.';
  }

  @override
  String get optionsTitle => 'Opciones';

  @override
  String get optionsSubtitle => 'Texto, idioma, audio y rendimiento';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languagePolish => 'Polaco';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageDutch => 'Neerlandés';

  @override
  String get textScaleStandard => 'Estándar';

  @override
  String get textScaleLarge => 'Grande';

  @override
  String get textScaleExtraLarge => 'Muy grande';

  @override
  String textScaleSemanticLabel(String label) {
    return 'Tamaño del texto $label';
  }

  @override
  String textScaleTooltip(String label) {
    return 'Tamaño del texto: $label';
  }

  @override
  String languageSemanticLabel(String label) {
    return 'Idioma $label';
  }

  @override
  String languageTooltip(String label) {
    return 'Idioma: $label';
  }

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get gameSoundsLabel => 'Sonidos del juego';

  @override
  String get soundVolumeLabel => 'Volumen de sonido';

  @override
  String get gameMusicLabel => 'Música del juego';

  @override
  String get musicVolumeLabel => 'Volumen de música';

  @override
  String get natureSoundsLabel => 'Sonidos de la naturaleza';

  @override
  String get natureVolumeLabel => 'Volumen de naturaleza';

  @override
  String get aiSectionTitle => 'IA';

  @override
  String get aiBatterySaverLabel => 'Ahorro de batería de IA';

  @override
  String get gameplaySectionTitle => 'Jugabilidad';

  @override
  String get followUnitMovementCameraLabel =>
      'Seguir movimiento de unidad con la cámara';

  @override
  String get followEnemyUnitCameraLabel =>
      'Seguir unidades enemigas con la cámara';

  @override
  String get cinematicCameraLabel => 'Cámara cinematográfica';

  @override
  String get performanceSectionTitle => 'Rendimiento';

  @override
  String get showFpsLabel => 'Mostrar FPS';

  @override
  String get showMapZoomLabel => 'Mostrar zoom del mapa';

  @override
  String get mapViewModeTooltip => 'Cambiar modo de vista del mapa';

  @override
  String get mapViewGraphicUnavailableTooltip =>
      'El modo gráfico no está disponible para este mapa';

  @override
  String get mapViewModeGraphic => 'Gráfico';

  @override
  String get mapViewModeTiles => 'Casillas';

  @override
  String get gameOptionTerrain => 'Terreno';

  @override
  String get gameOptionResources => 'Recursos';

  @override
  String get gameOptionHeight => 'Altura';

  @override
  String get gameOptionCitySites => 'Sitios de ciudad';

  @override
  String get gameOptionCityGrowth => 'Crecimiento de ciudad';

  @override
  String get gameOptionShowHexes => 'Mostrar hexágonos';

  @override
  String get gameOptionShowHeight => 'Mostrar altura';

  @override
  String get gameOptionDiceTest => 'Prueba de dados';

  @override
  String get gameOptionAutoActionFlow => 'Completar acciones automáticamente';

  @override
  String get gameOptionAutoTurnFlow => 'Terminar turnos automáticamente';

  @override
  String get helpPopupsTitle => 'Consejos';

  @override
  String get autoTurnHintTitle => 'Terminar turnos automáticamente';

  @override
  String get autoTurnHintBody =>
      'La finalización automática de turnos envía el turno cuando no quedan acciones importantes. Puedes controlar la finalización automática de acciones por separado en las opciones del mapa.';

  @override
  String get autoTurnHintEnableAction => 'Activar';

  @override
  String get autoTurnHintDisableAction => 'Desactivar';

  @override
  String get autoTurnHintStatusOn => 'Activado';

  @override
  String get autoTurnHintStatusOff => 'Desactivado';

  @override
  String get autoTurnHintMinimizedSubtitle =>
      'Conmutador rápido para el flujo de turnos automático.';

  @override
  String visibilityShowAction(String label) {
    return 'Mostrar $label';
  }

  @override
  String visibilityHideAction(String label) {
    return 'Ocultar $label';
  }

  @override
  String get resignAction => 'Rendirse';

  @override
  String get resignMatchTitle => '¿Rendirse en la partida?';

  @override
  String get resignMatchMessage => 'La partida finalizará.';

  @override
  String get resignMatchError => 'No se pudo rendirse en la partida.';

  @override
  String get creditsTitle => 'Créditos';

  @override
  String creditsCreatedBy(String name) {
    return 'Creado por $name';
  }

  @override
  String get deleteGameTitle => 'Eliminar partida';

  @override
  String deleteGameMessage(String name) {
    return '¿Eliminar \"$name\"? Esto no se puede deshacer.';
  }

  @override
  String get deleteAction => 'ELIMINAR';

  @override
  String get retryAction => 'REINTENTAR';

  @override
  String get noSavedGames => 'No hay partidas guardadas.';

  @override
  String get resumeAction => 'REANUDAR';

  @override
  String get newGameAction => 'NUEVA PARTIDA';

  @override
  String get turnActionButtonLabel => 'Acción';

  @override
  String get endTurnButtonLabel => 'Terminar turno';

  @override
  String get waitingTurnButtonLabel => 'Esperando';

  @override
  String get waitingForPlayersTooltip => 'Esperando a otros jugadores';

  @override
  String submitTurnTooltip(int turn) {
    return 'Enviar preparación en el turno $turn';
  }

  @override
  String endTurnTooltip(int turn) {
    return 'Terminar turno $turn';
  }

  @override
  String get nextActionTooltip => 'Ir a la siguiente acción';

  @override
  String nextActionWithCountTooltip(int count) {
    return 'Ir a la siguiente acción ($count restantes)';
  }

  @override
  String get turnActionListTooltip => 'Elige una acción de la lista';

  @override
  String get hudActionDeckCollapseTooltip => 'Contraer barra inferior';

  @override
  String get hudActionDeckExpandTooltip => 'Expandir barra inferior';

  @override
  String get turnActionUnitKind => 'Unidad';

  @override
  String get turnActionCityProductionKind => 'Ciudad';

  @override
  String get turnActionResearchKind => 'Investigación';

  @override
  String turnActionCityProductionLabel(String cityName) {
    return 'producción de $cityName';
  }

  @override
  String get turnActionResearchLabel => 'Elegir investigación';

  @override
  String turnLabel(int turn) {
    return 'TURNO $turn';
  }

  @override
  String loadGameError(String error) {
    return 'Error de carga: $error';
  }

  @override
  String get backAction => 'Atrás';

  @override
  String get continueAction => 'Continuar';

  @override
  String get gameLoadingTitle => 'Cargando mundo';

  @override
  String get gameLoadingMessage =>
      'Preparando el mapa, las unidades y la interfaz. La partida aparecerá cuando los recursos estén listos.';

  @override
  String get firstTurnTutorialPopupTitle => 'Tutorial';

  @override
  String get firstTurnTutorialPopupSubtitle => 'Guía del primer turno';

  @override
  String firstTurnTutorialSemantics(String title) {
    return 'Primer turno: $title';
  }

  @override
  String firstTurnCoachmarkProgressLabel(int current, int total) {
    return 'Paso $current/$total';
  }

  @override
  String get firstTurnCoachmarkMinimizeTooltip => 'Minimizar';

  @override
  String get firstTurnCoachmarkSkipAction => 'Omitir';

  @override
  String get firstTurnCoachmarkNextAction => 'Siguiente';

  @override
  String get firstTurnCoachmarkDoneAction => 'Hecho';

  @override
  String get firstTurnCoachmarkSelectionTitle => 'Paso 1: lee la selección';

  @override
  String get firstTurnCoachmarkSelectionBody =>
      'La partida empieza seleccionando automáticamente tu primera unidad. El panel inferior te dice qué comandas, cuántas acciones quedan y qué órdenes puedes dar ahora.';

  @override
  String get firstTurnCoachmarkSelectionBodyUnit =>
      'La barra inferior describe la unidad seleccionada: tipo, movimiento, cola de acciones y órdenes disponibles. Úsala para entrar en el modo Mover y cancélalo cuando quieras que los toques en hexágonos vuelvan a inspeccionar.';

  @override
  String get firstTurnCoachmarkSelectionBodyCity =>
      'Tienes una ciudad seleccionada. El panel inferior muestra su producción, población, edificios y decisiones económicas. Es un contexto distinto al de las órdenes de unidad, así que el tutorial hablará de la ciudad.';

  @override
  String get firstTurnCoachmarkSelectionBodyNone =>
      'Cuando no hay nada seleccionado, el panel inferior muestra el estado general del turno. Toca una de tus unidades o ciudades para ver órdenes e información concretas.';

  @override
  String get firstTurnCoachmarkResourcesTitle => 'Paso 2: revisa tu imperio';

  @override
  String get firstTurnCoachmarkResourcesBody =>
      'La barra superior muestra el turno, el oro, la ciencia y los recursos. El oro sostiene la economía, la ciencia impulsa la investigación y los recursos sugieren qué merece la pena construir.';

  @override
  String get firstTurnCoachmarkMenuTitle => 'Paso 3: aprende el menú izquierdo';

  @override
  String get firstTurnCoachmarkMenuBody =>
      'El menú izquierdo reúne vistas que revisarás cada turno: opciones del mapa, respuestas emergentes minimizadas, objetivos, registro, investigación e imperio. Mantén pulsado el botón del menú para contraer la barra y luego toca el botón único para abrirla de nuevo.';

  @override
  String get firstTurnCoachmarkActionTitle => 'Paso 4: da la orden correcta';

  @override
  String get firstTurnCoachmarkActionBodyActive =>
      'Si el colono está sobre una buena casilla, usa la acción de fundar ciudad. Si la ubicación es débil, mueve la unidad y revela terreno. El movimiento y las acciones especiales consumen el turno de esa unidad.';

  @override
  String get firstTurnCoachmarkActionBodyWaiting =>
      'Cuando una unidad tiene una orden, aparece aquí. En los primeros turnos, pasa por unidades y ciudades una por una hasta no dejar atrás ninguna decisión importante.';

  @override
  String get firstTurnCoachmarkActionBodySettler =>
      'El colono decide el comienzo de tu imperio. Si la casilla ofrece crecimiento, producción y espacio para expandirse, funda una ciudad. Si el terreno es débil, mueve al colono e inspecciona primero la tierra cercana.';

  @override
  String get firstTurnCoachmarkActionBodyWorker =>
      'Un trabajador no funda ciudades. Su trabajo es mejorar casillas dentro de las fronteras de la ciudad: las granjas ayudan al crecimiento, las minas aumentan la producción y las mejoras de recursos fortalecen la economía.';

  @override
  String get firstTurnCoachmarkActionBodyUnit =>
      'Para unidades de combate y exploración, lo más importante son el movimiento, la visión y la seguridad. Revela terreno, protege las fronteras de la ciudad y ataca solo cuando el resultado previsto sea favorable.';

  @override
  String get firstTurnCoachmarkActionBodyCity =>
      'Con una ciudad seleccionada, esta zona conduce a producción y gestión. Elige un objetivo de construcción, revisa el crecimiento de la ciudad y evita que la ciudad quede inactiva.';

  @override
  String get firstTurnCoachmarkResearchTitle => 'Paso 5: elige investigación';

  @override
  String get firstTurnCoachmarkResearchBody =>
      'Abre Investigación antes de terminar el turno. Agricultura apoya el crecimiento, Minería aumenta la producción y Caza mejora la exploración y la defensa. Lo más importante: la ciencia no debe avanzar sin objetivo.';

  @override
  String get firstTurnCoachmarkResearchBodyAvailable =>
      'La investigación está lista para elegirse. Abre Investigación antes de terminar el turno: Agricultura apoya el crecimiento, Minería aumenta la producción y Caza mejora la exploración y la defensa.';

  @override
  String get firstTurnCoachmarkCityTitle => 'Paso 6: prepara la ciudad';

  @override
  String get firstTurnCoachmarkCityBody =>
      'Tras fundar la capital, elige producción. Un trabajador desarrolla casillas, un guerrero asegura la zona y los edificios fortalecen la economía. La ciudad siempre debería estar construyendo algo.';

  @override
  String get firstTurnCoachmarkCityBodySelected =>
      'Este es el panel de ciudad. Revisa producción, crecimiento, edificios y proyectos disponibles. La regla principal para nuevos turnos: cada ciudad debe tener un objetivo de producción.';

  @override
  String get firstTurnCoachmarkCityBodyNeedsProduction =>
      'Una de tus ciudades está esperando producción. Usa el botón de acción o selecciona la ciudad, elige una unidad, edificio o proyecto, y solo entonces termina el turno.';

  @override
  String get firstTurnCoachmarkCityBodyExisting =>
      'Tus ciudades ya tienen producción asignada. En turnos posteriores, vuelve aquí para observar crecimiento, edificios, especialización y necesidades defensivas.';

  @override
  String get firstTurnCoachmarkCityBodyFuture =>
      'Tras fundar la primera ciudad, volverás aquí para elegir producción. Un trabajador desarrolla casillas, un guerrero asegura la zona y los edificios fortalecen la economía.';

  @override
  String get firstTurnCoachmarkActionFlowTitle =>
      'Paso 7: limpia la cola de acciones';

  @override
  String get firstTurnCoachmarkActionFlowBodyReady =>
      'Todas las decisiones clave de este turno están listas. Antes de terminar el turno, confirma rápidamente que la investigación y la producción de la ciudad tengan objetivo.';

  @override
  String get firstTurnCoachmarkActionFlowBodyPending =>
      'El botón de acción lleva a la siguiente unidad, ciudad o elección pendiente. Sigue pulsándolo hasta que el juego muestre que es seguro terminar el turno.';

  @override
  String get firstTurnCoachmarkEndTurnTitle =>
      'Paso 8: termina el turno y repite';

  @override
  String get firstTurnCoachmarkEndTurnBody =>
      'Cuando nada necesite tu respuesta, termina el turno. El ritmo de los siguientes turnos es el mismo: recursos, unidades, ciudad, investigación y terminar turno.';

  @override
  String get firstTurnCoachmarkVictoryBody =>
      'Puedes ganar por dominación o por artefactos: coloca 6 artefactos únicos en tus ciudades y conserva la colección durante 5 turnos.';

  @override
  String get firstTurnCoachmarkHexTapBody =>
      'Haz clic o toca varias veces el mismo hexágono para alternar su información: selección de casilla, artefacto, objetivo de mapa y descripción.';

  @override
  String get gameLoadMapErrorTitle => 'No se pudo cargar el mapa';

  @override
  String gameLoadMapErrorMessage(String mapName, String error) {
    return 'No se pudo cargar el mapa \"$mapName\": $error';
  }

  @override
  String get gameOutcomeVictoryTitle => 'Victoria';

  @override
  String get gameOutcomeDefeatTitle => 'Derrota';

  @override
  String get gameOutcomeDrawTitle => 'Empate';

  @override
  String get gameOutcomeCompleteTitle => 'Fin de la partida';

  @override
  String get gameOutcomeConditionConquest => 'Conquista';

  @override
  String get gameOutcomeConditionScore => 'Puntuación';

  @override
  String get gameOutcomeConditionScoreDraw => 'Empate por puntuación';

  @override
  String get gameOutcomeConditionDomination => 'Dominación';

  @override
  String get gameOutcomeConquestNoWinner => 'Queda un imperio en el mapa.';

  @override
  String gameOutcomeConquestWinner(String winner) {
    return '$winner es el último imperio en el mapa.';
  }

  @override
  String get gameOutcomeScoreNoWinner =>
      'El límite de turnos decidió el resultado.';

  @override
  String gameOutcomeScoreWinner(String winner) {
    return '$winner gana tras el límite de turnos.';
  }

  @override
  String get gameOutcomeScoreDrawSubtitle =>
      'Límite de turnos alcanzado. La puntuación más alta está empatada.';

  @override
  String get gameOutcomeDominationNoWinner => 'Se mantuvo el control del mapa.';

  @override
  String gameOutcomeDominationWinner(String winner) {
    return '$winner mantiene la dominación territorial.';
  }

  @override
  String get gameOutcomeWinnerMetric => 'Ganador';

  @override
  String get gameOutcomeConditionMetric => 'Condición';

  @override
  String get gameOutcomeEliminationMetric => 'Eliminación';

  @override
  String get gameOutcomeMapControlMetric => 'Control del mapa';

  @override
  String get gameOutcomeHoldMetric => 'Mantenimiento';

  @override
  String get gameOutcomeThresholdMetric => 'Umbral';

  @override
  String gameOutcomeTurnsValue(int held, int required) {
    return '$held/$required turnos';
  }

  @override
  String get victoryConquestPrimary => 'Conquista';

  @override
  String get victoryGoalCompact => 'Objetivo';

  @override
  String get victoryNoLimit => 'Sin límite';

  @override
  String get victoryConquestTooltip =>
      'Objetivo: eliminar rivales. Sin límite de turnos.';

  @override
  String get victoryLimitLabel => 'Límite';

  @override
  String get victoryNoneValue => 'Ninguno';

  @override
  String get victoryScoreCapPrimary => 'LÍMITE DE PUNTUACIÓN';

  @override
  String victoryScoreRemainingPrimary(int turns) {
    return 'PUNTUACIÓN ${turns}T';
  }

  @override
  String get victoryScoreCapCompact => 'LÍMITE';

  @override
  String victoryTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String victoryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos',
      one: '1 turno',
    );
    return '$_temp0';
  }

  @override
  String get victoryRemainingLabel => 'Restante';

  @override
  String get victoryScoreLeaderLabel => 'Líder en puntuación';

  @override
  String victoryScoreDrawLabel(int score) {
    return 'EMPATE $score';
  }

  @override
  String victoryScoreLimitReachedTooltip(int turnLimit) {
    return 'Se alcanzó el límite de turnos $turnLimit. La puntuación decide el resultado.';
  }

  @override
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit) {
    return 'Desempate por puntuación en $remainingTurns turnos. Límite: $turnLimit.';
  }

  @override
  String victoryLeaderTooltip(String leader) {
    return 'Líder: $leader.';
  }

  @override
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  ) {
    return 'Dominación: $leader controla el $control% del mapa. Umbral: $required%, mantenimiento: $hold.';
  }

  @override
  String get victoryLeaderLabel => 'Líder';

  @override
  String get victoryControlLabel => 'Control';

  @override
  String get victoryHoldLabel => 'Mantener';

  @override
  String get victoryYouLabel => 'Tú';

  @override
  String get victoryPressureLabel => 'Presión';

  @override
  String get victoryFallbackLabel => 'Desempate';

  @override
  String victoryYourGoalGainControl(int points) {
    return 'Tu objetivo: ganar $points pp más de control del mapa.';
  }

  @override
  String get victoryYourGoalReady =>
      'Tu objetivo: la condición de dominación está lista para resolverse.';

  @override
  String victoryYourGoalHold(String turns) {
    return 'Tu objetivo: mantener el umbral durante $turns más.';
  }

  @override
  String victoryLeaderAboveThreshold(String leader) {
    return '$leader está por encima del umbral; rompe ese control antes de que se mantenga el objetivo.';
  }

  @override
  String victoryYourProgress(String control, String required) {
    return 'Tu progreso: $control% / $required%.';
  }

  @override
  String victoryPressureReachThreshold(int points) {
    return 'Alcanza el umbral: faltan $points pp';
  }

  @override
  String get victoryConditionReady => 'Condición lista';

  @override
  String victoryPressureHold(String turns) {
    return 'Mantener durante $turns';
  }

  @override
  String victoryPressureLeaderHolding(String leader, String turns) {
    return '$leader por encima del umbral: $turns';
  }

  @override
  String victoryPressureYourGap(int points) {
    return 'Tu objetivo: faltan $points pp';
  }

  @override
  String victoryPressureLeaderGap(String leader, int points) {
    return '$leader lidera: faltan $points pp';
  }

  @override
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  ) {
    return 'Un rival se acerca a la dominación: $player controla el $control% con el umbral en $required%; faltan $points pp.';
  }

  @override
  String victoryThreatHolding(String player, String hold) {
    return 'Un rival mantiene el umbral de dominación: $player $hold.';
  }

  @override
  String victoryThreatImminent(String player, String hold) {
    return 'Un rival está cerca de la dominación: $player $hold.';
  }

  @override
  String victoryThreatPressureApproaching(String player, int points) {
    return '$player cerca del umbral: faltan $points pp';
  }

  @override
  String victoryThreatPressureBreak(String player, String turns) {
    return 'Romper a $player: $turns';
  }

  @override
  String get victoryBelowThreshold => 'por debajo del umbral';

  @override
  String victoryHoldProgress(int held, int required) {
    return '$held/$required turnos';
  }

  @override
  String victoryHoldCompact(int held, int required) {
    return '$held/${required}T';
  }

  @override
  String get victoryReady => 'listo';

  @override
  String victoryRemainingTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count turnos',
      one: 'queda 1 turno',
    );
    return '$_temp0';
  }

  @override
  String get returnToMenuAction => 'Volver al menú';

  @override
  String get today => 'hoy';

  @override
  String get yesterday => 'ayer';

  @override
  String get objectivesPanelTitle => 'OBJETIVOS';

  @override
  String get objectivesCloseTooltip => 'Cerrar objetivos';

  @override
  String get objectivesMenuClosePrefix => 'Cerrar objetivos';

  @override
  String get objectivesMenuOpenPrefix => 'Objetivos';

  @override
  String objectivesMenuTooltip(
    String prefix,
    String descriptor,
    String title,
    String progress,
    String count,
  ) {
    return '$prefix: $descriptor - $title ($progress, $count)';
  }

  @override
  String objectivesMenuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objetivos',
      one: '1 objetivo',
    );
    return '$_temp0';
  }

  @override
  String get objectivesMenuBadgeScore => 'PTS';

  @override
  String get objectivesMenuBadgeDomination => 'DOM';

  @override
  String get objectivesMenuDescriptorDomination => 'dominación';

  @override
  String get objectivesMenuDescriptorDominationThreat =>
      'amenaza de dominación';

  @override
  String get objectivesMenuDescriptorScoreLead => 'defensa del liderazgo';

  @override
  String get objectivesMenuDescriptorScorePressure => 'presión de puntuación';

  @override
  String get objectivesMenuDescriptorActiveObjective => 'objetivo activo';

  @override
  String get objectiveMicroTooltipLabel => 'Por qué';

  @override
  String get objectiveOverviewGuidanceLabel => 'OBJETIVO ACTIVO';

  @override
  String get objectiveOverviewStrategicLabel => 'URGENTE';

  @override
  String get objectiveOverviewScoreCatchUpLabel => 'PRESIÓN DE PUNTUACIÓN';

  @override
  String get objectiveOverviewScoreProtectLabel => 'DEFENDER LIDERAZGO';

  @override
  String get objectiveOverviewDominationHoldLabel => 'DOMINACIÓN';

  @override
  String get objectiveOverviewDominationThreatLabel => 'AMENAZA DE DOMINACIÓN';

  @override
  String objectiveOverviewTitleLabel(String title) {
    return 'Prioridad principal: $title';
  }

  @override
  String objectiveOverviewProgressLabel(String progress) {
    return 'Progreso $progress';
  }

  @override
  String get objectivePhaseFoundation => 'Fundación';

  @override
  String get objectivePhaseExpansion => 'Expansión';

  @override
  String get objectivePhasePressure => 'Presión';

  @override
  String get objectivePhaseEndgame => 'Final de partida';

  @override
  String get objectiveChooseResearchTitle => 'Elegir investigación';

  @override
  String get objectiveChooseResearchHint =>
      'Define tu dirección de desarrollo antes de que termine el primer turno.';

  @override
  String get objectiveChooseResearchReward => '+ ritmo de ciencia';

  @override
  String get objectiveChooseResearchTooltip =>
      'La investigación orienta cada turno siguiente hacia una ruta de desarrollo concreta.';

  @override
  String get objectiveFoundCapitalTitle => 'Funda tu primera ciudad';

  @override
  String get objectiveFoundCapitalHint =>
      'Tu colono debería convertir pronto buen terreno en una capital.';

  @override
  String get objectiveFoundCapitalReward => '+ base de producción';

  @override
  String get objectiveFoundCapitalTooltip =>
      'La capital desbloquea producción, crecimiento y alcance territorial.';

  @override
  String get objectiveExploreNearbyTitle => 'Explora las tierras cercanas';

  @override
  String get objectiveExploreNearbyHint =>
      'Tu guerrero debería revelar recursos cercanos y sitios de ciudad.';

  @override
  String get objectiveExploreNearbyReward => '+ mejores decisiones';

  @override
  String get objectiveExploreNearbyTooltip =>
      'La exploración temprana ayuda a elegir sitios de ciudad y evitar movimientos a ciegas.';

  @override
  String get objectiveQueueWorkerTitle => 'Poner un trabajador en cola';

  @override
  String get objectiveQueueWorkerHint =>
      'Un trabajador convierte alimento y producción del mapa en una ventaja real.';

  @override
  String get objectiveQueueWorkerReward => '+ desarrollo del terreno';

  @override
  String get objectiveQueueWorkerTooltip =>
      'Un trabajador convierte buenas casillas en crecimiento estable de recursos.';

  @override
  String get objectiveImproveFirstHexTitle => 'Mejora tu primera casilla';

  @override
  String get objectiveImproveFirstHexHint =>
      'La primera mejora debería apoyar alimento, producción u oro.';

  @override
  String get objectiveImproveFirstHexReward => '+ economía más fuerte';

  @override
  String get objectiveImproveFirstHexTooltip =>
      'La primera mejora muestra qué parte de la economía de la ciudad debería crecer más rápido.';

  @override
  String get objectiveFoundSecondCityTitle => 'Funda una segunda ciudad';

  @override
  String get objectiveFoundSecondCityHint =>
      'Un segundo asentamiento abre la expansión sin llenar el mapa de unidades.';

  @override
  String get objectiveFoundSecondCityReward => '+ escala de imperio';

  @override
  String get objectiveFoundSecondCityTooltip =>
      'Una segunda ciudad aumenta el ritmo de producción sin depender de una sola capital.';

  @override
  String get objectiveBuildFirstBuildingTitle => 'Construye tu primer edificio';

  @override
  String get objectiveBuildFirstBuildingHint =>
      'El primer edificio debería fortalecer alimento, producción u oro.';

  @override
  String get objectiveBuildFirstBuildingReward => '+ ventaja urbana duradera';

  @override
  String get objectiveBuildFirstBuildingTooltip =>
      'Los edificios permanecen en la ciudad y escalan durante muchos turnos.';

  @override
  String get objectiveImproveThreeHexesTitle => 'Mejora tres casillas';

  @override
  String get objectiveImproveThreeHexesHint =>
      'Varias mejoras convierten un campamento inicial en una economía.';

  @override
  String get objectiveImproveThreeHexesReward => '+ ingresos estables';

  @override
  String get objectiveImproveThreeHexesTooltip =>
      'Tres mejoras crean una base estable para ejércitos, investigación o expansión.';

  @override
  String get objectiveFoundThirdCityTitle => 'Funda una tercera ciudad';

  @override
  String get objectiveFoundThirdCityHint =>
      'Un tercer asentamiento crea un verdadero imperio y una segunda dirección de expansión.';

  @override
  String get objectiveFoundThirdCityReward => '+ escala de mapa';

  @override
  String get objectiveFoundThirdCityTooltip =>
      'Una tercera ciudad te da un segundo frente de desarrollo y más decisiones cada turno.';

  @override
  String get objectiveExploreRegionTitle => 'Explora la región';

  @override
  String get objectiveExploreRegionHint =>
      'Un mapa más amplio revela recursos, rivales y lugares que merece la pena defender.';

  @override
  String get objectiveExploreRegionReward => '+ plan estratégico';

  @override
  String get objectiveExploreRegionTooltip =>
      'Un mapa más amplio revela rivales, recursos estratégicos y fronteras seguras.';

  @override
  String get objectiveBuildCombatForceTitle => 'Forma una fuerza defensiva';

  @override
  String get objectiveBuildCombatForceHint =>
      'Varias tropas te permiten proteger la expansión y presionar a los rivales.';

  @override
  String get objectiveBuildCombatForceReward => '+ seguridad fronteriza';

  @override
  String get objectiveBuildCombatForceTooltip =>
      'Una pantalla constante protege colonos, trabajadores y ciudades desarrolladas.';

  @override
  String get objectiveHoldDominationTitle => 'Mantén la dominación';

  @override
  String get objectiveHoldDominationHint =>
      'Estás por encima del umbral del mapa. Mantén el control hasta que termine la cuenta atrás.';

  @override
  String get objectiveHoldDominationReward => '+ victoria de mapa';

  @override
  String get objectiveHoldDominationTooltip =>
      'La dominación termina la partida antes del límite de puntuación si mantienes el porcentaje de mapa requerido durante turnos consecutivos.';

  @override
  String get objectiveBreakDominationHoldTitle =>
      'Rompe la dominación de un rival';

  @override
  String get objectiveBreakDominationHoldHint =>
      'Un rival está por encima del umbral del mapa. Toma territorio antes de que mantenga el objetivo.';

  @override
  String get objectiveBreakDominationHoldReward => '+ cuenta atrás detenida';

  @override
  String get objectiveBreakDominationHoldTooltip =>
      'Si un rival cae por debajo del umbral de control, sus turnos de mantenimiento se reinician a cero.';

  @override
  String get objectiveHoldScoreLeadTitle => 'Mantén el liderazgo';

  @override
  String get objectiveHoldScoreLeadHint =>
      'El límite de turnos está cerca. Protege tu puntuación y evita perder tu ventaja en los turnos finales.';

  @override
  String get objectiveHoldScoreLeadReward =>
      '+ victoria por límite de puntuación';

  @override
  String get objectiveHoldScoreLeadTooltip =>
      'El límite de puntuación decide la partida cuando se supera el límite de turnos, así que la ventaja de puntos debe durar hasta el final.';

  @override
  String get objectiveOvertakeScoreLeaderTitle =>
      'Alcanza al líder en puntuación';

  @override
  String get objectiveOvertakeScoreLeaderHint =>
      'El límite de turnos está cerca. Necesitas crecimiento rápido de puntuación o un líder más débil.';

  @override
  String get objectiveOvertakeScoreLeaderReward =>
      '+ opción de victoria por puntuación';

  @override
  String get objectiveOvertakeScoreLeaderTooltip =>
      'Construye ciudades, población, tecnologías, unidades y mejoras; si las puntuaciones empatan, el límite de puntuación acaba en empate.';

  @override
  String get objectiveSecureMapObjectiveTitle => 'Asegura el objetivo del mapa';

  @override
  String get objectiveSecureMapObjectiveHint =>
      'Mantén una unidad o influencia urbana sobre el objetivo hasta completar el control.';

  @override
  String get objectiveSecureMapObjectiveReward => '+ recompensas del objetivo';

  @override
  String get objectiveSecureMapObjectiveTooltip =>
      'Los objetivos del mapa usan marcadores triangulares y conceden puntos de victoria u oro solo tras control consecutivo.';

  @override
  String get objectiveBreakMapObjectiveHoldTitle => 'Rompe el objetivo rival';

  @override
  String get objectiveBreakMapObjectiveHoldHint =>
      'Un rival mantiene un objetivo del mapa. Disputa el marcador triangular antes de que complete el control.';

  @override
  String get objectiveBreakMapObjectiveHoldReward => '+ objetivo negado';

  @override
  String get objectiveBreakMapObjectiveHoldTooltip =>
      'Mover una fuerza propia al objetivo disputa el control y reinicia el progreso rival.';

  @override
  String get objectiveAdviceFoundCity =>
      'Mayor brecha: una ciudad nueva o capturada.';

  @override
  String get objectiveAdviceGrowPopulation =>
      'Mayor brecha: crecimiento de población.';

  @override
  String get objectiveAdviceClaimTerritory =>
      'Mayor brecha: más casillas controladas.';

  @override
  String get objectiveAdviceConstructBuilding =>
      'Mayor brecha: un edificio de ciudad.';

  @override
  String get objectiveAdviceTrainUnit => 'Mayor brecha: una unidad rápida.';

  @override
  String get objectiveAdviceUnlockTechnology =>
      'Mayor brecha: completar una tecnología.';

  @override
  String get objectiveAdviceImproveField =>
      'Mayor brecha: una mejora de casilla.';

  @override
  String get objectiveAdviceCollectGold => 'Mayor brecha: oro para puntuación.';

  @override
  String get objectiveAdviceProtectLead =>
      'Prioridad: no cedas ciudades y asegura la siguiente ganancia de puntuación.';

  @override
  String objectiveScoreBreakdownCatchUpHeader(int delta) {
    return 'Brecha de puntuación: $delta pts';
  }

  @override
  String objectiveScoreBreakdownProtectHeader(int delta) {
    return 'Ventaja de puntuación: $delta pts';
  }

  @override
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Tú $playerScore / líder $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Tú $playerScore / rival $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownCatchUpDelta(int delta) {
    return 'faltan $delta';
  }

  @override
  String objectiveScoreBreakdownProtectDelta(int delta) {
    return '+$delta';
  }

  @override
  String get objectiveScoreCategoryCity => 'Ciudades';

  @override
  String get objectiveScoreCategoryPopulation => 'Población';

  @override
  String get objectiveScoreCategoryTerritory => 'Territorio';

  @override
  String get objectiveScoreCategoryBuilding => 'Edificios';

  @override
  String get objectiveScoreCategoryUnit => 'Unidades';

  @override
  String get objectiveScoreCategoryTechnology => 'Tecnologías';

  @override
  String get objectiveScoreCategoryImprovement => 'Mejoras';

  @override
  String get objectiveScoreCategoryGold => 'Oro';

  @override
  String get cityBuildingGranary => 'Granero';

  @override
  String get cityBuildingWaterMill => 'Molino de agua';

  @override
  String get cityBuildingWorkshop => 'Taller';

  @override
  String get cityBuildingStorehouse => 'Almacén';

  @override
  String get cityBuildingHousing => 'Viviendas';

  @override
  String get cityBuildingMerchantHall => 'Lonja de mercaderes';

  @override
  String get cityBuildingStonemason => 'Cantero';

  @override
  String get cityBuildingBarracks => 'Cuartel';

  @override
  String get cityBuildingMarketplace => 'Mercado';

  @override
  String get cityBuildingPort => 'Puerto';

  @override
  String get cityBuildingAqueduct => 'Acueducto';

  @override
  String get cityBuildingForge => 'Forja';

  @override
  String get cityBuildingStable => 'Establo';

  @override
  String get cityBuildingBank => 'Banco';

  @override
  String get cityBuildingBuildersGuild => 'Gremio de constructores';

  @override
  String get cityBuildingFactory => 'Fábrica';

  @override
  String get cityBuildingLighthouse => 'Faro';

  @override
  String get cityBuildingTrainingGrounds => 'Campo de entrenamiento';

  @override
  String get cityBuildingTownHall => 'Ayuntamiento';

  @override
  String get cityBuildingMonument => 'Monumento';

  @override
  String get cityBuildingArchive => 'Archivo';

  @override
  String get cityBuildingAcademy => 'Academia';

  @override
  String get cityBuildingUniversity => 'Universidad';

  @override
  String get cityBuildingObservatory => 'Observatorio';

  @override
  String get cityBuildingLaboratory => 'Laboratorio';

  @override
  String get cityBuildingReactor => 'Reactor';

  @override
  String get cityBuildingCourthouse => 'Palacio de justicia';

  @override
  String get cityBuildingCourt => 'Tribunal';

  @override
  String get cityBuildingGovernorsOffice => 'Oficina del gobernador';

  @override
  String get cityBuildingSurveyorsOffice => 'Oficina de agrimensores';

  @override
  String get cityBuildingPlanningOffice => 'Oficina de planificación';

  @override
  String get cityBuildingApothecary => 'Botica';

  @override
  String get cityBuildingPublicBaths => 'Baños públicos';

  @override
  String get cityBuildingHospital => 'Hospital';

  @override
  String get cityBuildingMinistries => 'Ministerios';

  @override
  String get cityBuildingWalls => 'Murallas';

  @override
  String get cityBuildingArmory => 'Armería';

  @override
  String get cityBuildingSiegeWorkshop => 'Taller de asedio';

  @override
  String get cityBuildingCitadel => 'Ciudadela';

  @override
  String get cityBuildingWarCollege => 'Colegio militar';

  @override
  String get cityBuildingConscriptionOffice => 'Oficina de conscripción';

  @override
  String get cityBuildingBorderFort => 'Fuerte fronterizo';

  @override
  String get cityBuildingAirfield => 'Aeródromo';

  @override
  String get cityBuildingArtisansGuild => 'Gremio de artesanos';

  @override
  String get cityBuildingMasterWorkshop => 'Taller maestro';

  @override
  String get cityBuildingSteelworks => 'Acería';

  @override
  String get cityBuildingRailDepot => 'Depósito ferroviario';

  @override
  String get cityBuildingPowerPlant => 'Central eléctrica';

  @override
  String get cityBuildingAssemblyPlant => 'Planta de ensamblaje';

  @override
  String get cityBuildingRefinery => 'Refinería';

  @override
  String get cityBuildingMapRoom => 'Sala de mapas';

  @override
  String get cityBuildingShipyard => 'Astillero';

  @override
  String get cityBuildingDryDock => 'Dique seco';

  @override
  String get cityBuildingNavalAcademy => 'Academia naval';

  @override
  String get cityBuildingHarborCustoms => 'Aduana portuaria';

  @override
  String get cityBuildingMuseum => 'Museo';

  @override
  String get cityBuildingParliament => 'Parlamento';

  @override
  String get cityBuildingBroadcastTower => 'Torre de radiodifusión';

  @override
  String get cityBuildingWorldFairGrounds => 'Recinto de feria mundial';

  @override
  String get cityBuildingGranaryDescription =>
      'Un edificio temprano de alimento que estabiliza el crecimiento de la ciudad.';

  @override
  String get cityBuildingWaterMillDescription =>
      'Usa casillas de río controladas para aumentar el alimento de la ciudad.';

  @override
  String get cityBuildingWorkshopDescription =>
      'Un centro artesanal básico que eleva la producción de la ciudad.';

  @override
  String get cityBuildingStorehouseDescription =>
      'Mejora el almacenamiento de cosechas y aumenta el alimento almacenado.';

  @override
  String get cityBuildingHousingDescription =>
      'Amplía el espacio habitable y permite que la ciudad controle más casillas.';

  @override
  String get cityBuildingMerchantHallDescription =>
      'Organiza el comercio local y aumenta los ingresos de la ciudad.';

  @override
  String get cityBuildingStonemasonDescription =>
      'Refuerza la construcción de la ciudad y su base defensiva.';

  @override
  String get cityBuildingBarracksDescription =>
      'Proporciona infraestructura militar y defensa adicional.';

  @override
  String get cityBuildingMarketplaceDescription =>
      'Desarrolla el comercio urbano y aumenta mucho los ingresos de oro.';

  @override
  String get cityBuildingPortDescription =>
      'Abre la ciudad al comercio marítimo y al alimento costero.';

  @override
  String get cityBuildingAqueductDescription =>
      'Suministra agua, apoyando el crecimiento y una mayor expansión urbana.';

  @override
  String get cityBuildingForgeDescription =>
      'Concentra la metalurgia y aumenta mucho la producción.';

  @override
  String get cityBuildingStableDescription =>
      'Apoya la cría y la logística, añadiendo alimento y producción.';

  @override
  String get cityBuildingBankDescription =>
      'Centraliza las finanzas y aumenta significativamente los ingresos de la ciudad.';

  @override
  String get cityBuildingBuildersGuildDescription =>
      'Reúne especialistas en construcción, acelerando la producción y el crecimiento territorial.';

  @override
  String get cityBuildingFactoryDescription =>
      'Un edificio industrial de fase tardía que otorga una gran bonificación de producción.';

  @override
  String get cityBuildingLighthouseDescription =>
      'Fortalece la economía costera mediante navegación y comercio.';

  @override
  String get cityBuildingTrainingGroundsDescription =>
      'Desarrolla el entrenamiento militar y mejora la defensa de la ciudad.';

  @override
  String get cityBuildingTownHallDescription =>
      'El centro administrativo de la ciudad, que fortalece la economía y el control territorial.';

  @override
  String get cityBuildingMonumentDescription =>
      'Un símbolo de prestigio urbano que proporciona oro y defensa.';

  @override
  String get cityBuildingArchiveDescription =>
      'El primer edificio de conocimiento, que organiza registros y apoya la investigación.';

  @override
  String get cityBuildingAcademyDescription =>
      'Refuerza las ciudades científicas y prepara el camino hacia la educación superior.';

  @override
  String get cityBuildingUniversityDescription =>
      'Un edificio científico posterior para ciudades grandes y desarrolladas.';

  @override
  String get cityBuildingObservatoryDescription =>
      'Conecta la geografía con la ciencia y apoya la investigación avanzada.';

  @override
  String get cityBuildingLaboratoryDescription =>
      'Apoyo para proyectos tecnológicos tardíos y ciencia moderna.';

  @override
  String get cityBuildingReactorDescription =>
      'Un poderoso edificio de final de partida que requiere uranio e infraestructura sólida.';

  @override
  String get cityBuildingCourthouseDescription =>
      'Estabiliza ciudades grandes o capturadas mediante administración legal.';

  @override
  String get cityBuildingCourtDescription =>
      'Desarrolla la ley, las políticas urbanas y el control civil.';

  @override
  String get cityBuildingGovernorsOfficeDescription =>
      'Fortalece la especialización de la ciudad y la gestión territorial.';

  @override
  String get cityBuildingSurveyorsOfficeDescription =>
      'Facilita la planificación de fronteras y aumenta el alcance de control de la ciudad.';

  @override
  String get cityBuildingPlanningOfficeDescription =>
      'Desarrolla la ciudad mediante planificación, producción y control territorial.';

  @override
  String get cityBuildingApothecaryDescription =>
      'Salud urbana temprana que ayuda a mantener un crecimiento estable.';

  @override
  String get cityBuildingPublicBathsDescription =>
      'Mejoran la estabilidad y el crecimiento en ciudades más grandes.';

  @override
  String get cityBuildingHospitalDescription =>
      'Infraestructura de población tardía para desarrollo a largo plazo.';

  @override
  String get cityBuildingMinistriesDescription =>
      'Un edificio de imperio limitado que fortalece la administración y el oro.';

  @override
  String get cityBuildingWallsDescription =>
      'Defensa temprana de ciudad contra los primeros ataques.';

  @override
  String get cityBuildingArmoryDescription =>
      'Un mejor centro de reclutamiento y equipamiento para tropas.';

  @override
  String get cityBuildingSiegeWorkshopDescription =>
      'Produce y mantiene la base de apoyo para máquinas de asedio.';

  @override
  String get cityBuildingCitadelDescription =>
      'Defensa estratégica tardía para ciudades en fronteras importantes.';

  @override
  String get cityBuildingWarCollegeDescription =>
      'Una academia militar que fortalece la coordinación del ejército y los generales.';

  @override
  String get cityBuildingConscriptionOfficeDescription =>
      'Moviliza el ejército y acelera la preparación de nuevas tropas.';

  @override
  String get cityBuildingBorderFortDescription =>
      'Refuerza la defensa y la visibilidad en las fronteras del imperio.';

  @override
  String get cityBuildingAirfieldDescription =>
      'Un aeródromo militar para aviación, reconocimiento y proyección de fuerza moderna.';

  @override
  String get cityBuildingArtisansGuildDescription =>
      'Una etapa de producción anterior a la fábrica, basada en oficios y talleres.';

  @override
  String get cityBuildingMasterWorkshopDescription =>
      'Un taller especializado para ciudades centradas en la producción.';

  @override
  String get cityBuildingSteelworksDescription =>
      'Industria pesada basada en hierro o carbón.';

  @override
  String get cityBuildingRailDepotDescription =>
      'Un depósito ferroviario que mejora la logística y la movilidad entre ciudades.';

  @override
  String get cityBuildingPowerPlantDescription =>
      'Infraestructura energética tardía para una fuerte producción industrial.';

  @override
  String get cityBuildingAssemblyPlantDescription =>
      'Un edificio industrial de final de partida para producción en masa.';

  @override
  String get cityBuildingRefineryDescription =>
      'Procesa petróleo para ejércitos modernos y proyectos tardíos.';

  @override
  String get cityBuildingMapRoomDescription =>
      'Apoya la exploración, la visibilidad y la planificación de expediciones.';

  @override
  String get cityBuildingShipyardDescription =>
      'Desarrolla flotas y producción en ciudades portuarias.';

  @override
  String get cityBuildingDryDockDescription =>
      'Un puerto naval tardío para buques de guerra mayores.';

  @override
  String get cityBuildingNavalAcademyDescription =>
      'Una academia militar naval para puertos especializados.';

  @override
  String get cityBuildingHarborCustomsDescription =>
      'Una oficina portuaria que fortalece el comercio y el control costero.';

  @override
  String get cityBuildingMuseumDescription =>
      'Un prestigioso edificio imperial que fortalece la influencia de la ciudad.';

  @override
  String get cityBuildingParliamentDescription =>
      'Un edificio cívico limitado para un estado maduro.';

  @override
  String get cityBuildingBroadcastTowerDescription =>
      'Fortalece la influencia, la visibilidad y la comunicación del imperio.';

  @override
  String get cityBuildingWorldFairGroundsDescription =>
      'Un proyecto pacífico de prestigio para una ciudad rica y desarrollada.';

  @override
  String get unitCommander => 'General';

  @override
  String get unitWarrior => 'Guerrero';

  @override
  String get unitArcher => 'Arquero';

  @override
  String get unitSettler => 'Colono';

  @override
  String get unitWorker => 'Trabajador';

  @override
  String get unitMerchant => 'Mercader';

  @override
  String get unitScout => 'Explorador';

  @override
  String get unitSpearman => 'Lancero';

  @override
  String get unitCavalry => 'Caballería';

  @override
  String get unitCatapult => 'Catapulta';

  @override
  String get unitHeavyInfantry => 'Infantería pesada';

  @override
  String get unitFieldCannon => 'Cañón de campaña';

  @override
  String get unitRifleman => 'Fusilero';

  @override
  String get unitTank => 'Tanque';

  @override
  String get unitScoutShip => 'Barco explorador';

  @override
  String get unitWarship => 'Buque de guerra';

  @override
  String get unitReconPlane => 'Avión de reconocimiento';

  @override
  String get unitCommanderDescription =>
      'Un general comanda un ejército, dirige el reconocimiento y puede actuar más rápido que las tropas regulares.';

  @override
  String get unitWarriorDescription =>
      'Una unidad de combate básica para la defensa de ciudades y la lucha cuerpo a cuerpo.';

  @override
  String get unitArcherDescription =>
      'Una unidad a distancia que ataca desde más lejos pero se defiende mal en combate cuerpo a cuerpo.';

  @override
  String get unitSettlerDescription =>
      'Funda nuevas ciudades y expande el imperio, pero necesita protección en el camino.';

  @override
  String get unitWorkerDescription =>
      'Mejora casillas alrededor de ciudades, aumentando alimento, producción y oro.';

  @override
  String get unitMerchantDescription =>
      'Viaja automáticamente entre tus ciudades por una ruta comercial y puede entrar en centros de ciudad aliados ocupados.';

  @override
  String get unitScoutDescription =>
      'Una unidad de reconocimiento rápida para explorar el mapa y detectar amenazas.';

  @override
  String get unitSpearmanDescription =>
      'Infantería defensiva temprana, buena para cubrir ciudades y detener cargas.';

  @override
  String get unitCavalryDescription =>
      'Una unidad de golpe móvil que responde rápidamente a puntos débiles del frente.';

  @override
  String get unitCatapultDescription =>
      'Una máquina de asedio de mayor alcance, efectiva contra fortificaciones.';

  @override
  String get unitHeavyInfantryDescription =>
      'Infantería resistente de primera línea con alta defensa y ataque sólido.';

  @override
  String get unitFieldCannonDescription =>
      'Artillería de campaña moderna para bombardeo a distancia.';

  @override
  String get unitRiflemanDescription =>
      'Un soldado moderno a distancia, estable en ataque y defensa.';

  @override
  String get unitTankDescription =>
      'Una unidad blindada pesada con gran fuerza y alta movilidad.';

  @override
  String get unitScoutShipDescription =>
      'Un barco ligero para reconocimiento costero y protección de rutas marítimas tempranas.';

  @override
  String get unitWarshipDescription =>
      'Un fuerte buque de combate para control marítimo y bombardeo a distancia.';

  @override
  String get unitReconPlaneDescription =>
      'Una aeronave de reconocimiento con gran alcance de visión y movilidad muy alta.';

  @override
  String get unitRankRecruit => 'Recluta';

  @override
  String get unitRankSeasoned => 'Curtido';

  @override
  String get unitRankVeteran => 'Veterano';

  @override
  String get unitRankElite => 'Élite';

  @override
  String get troopWarrior => 'Guerreros';

  @override
  String get troopArcher => 'Arqueros';

  @override
  String get troopSettler => 'Colonos';

  @override
  String get fieldImprovementFarm => 'Granja';

  @override
  String get fieldImprovementRiverFarm => 'Granja fluvial';

  @override
  String get fieldImprovementMine => 'Mina';

  @override
  String get fieldImprovementLumberMill => 'Aserradero';

  @override
  String get fieldImprovementPasture => 'Pasto';

  @override
  String get fieldImprovementCamp => 'Campamento';

  @override
  String get fieldImprovementQuarry => 'Cantera';

  @override
  String get fieldImprovementFishingBoats => 'Barcos pesqueros';

  @override
  String get fieldImprovementOrchard => 'Huerto';

  @override
  String get fieldImprovementPlantation => 'Plantación';

  @override
  String get fieldImprovementVineyard => 'Viñedo';

  @override
  String get fieldImprovementTradingPost => 'Puesto comercial';

  @override
  String get fieldImprovementProspectorCamp => 'Campamento de prospección';

  @override
  String get fieldImprovementHorseRanch => 'Rancho de caballos';

  @override
  String get fieldImprovementPearlDivers => 'Buzos de perlas';

  @override
  String get fieldImprovementCoalShaft => 'Pozo de carbón';

  @override
  String get fieldImprovementOilWell => 'Pozo petrolífero';

  @override
  String get fieldImprovementBauxiteMine => 'Mina de bauxita';

  @override
  String get fieldImprovementUraniumMine => 'Mina de uranio';

  @override
  String get resourceWheat => 'trigo';

  @override
  String get resourceFish => 'pescado';

  @override
  String get resourceDeer => 'ciervos';

  @override
  String get resourceSheep => 'ovejas';

  @override
  String get resourceRice => 'arroz';

  @override
  String get resourceCow => 'ganado';

  @override
  String get resourceApple => 'manzanas';

  @override
  String get resourceBanana => 'bananas';

  @override
  String get resourceCitrus => 'cítricos';

  @override
  String get resourceGold => 'oro';

  @override
  String get resourceSilver => 'plata';

  @override
  String get resourceGems => 'gemas';

  @override
  String get resourceSilk => 'seda';

  @override
  String get resourceSpices => 'especias';

  @override
  String get resourceCotton => 'algodón';

  @override
  String get resourceGrapes => 'uvas';

  @override
  String get resourceIvory => 'marfil';

  @override
  String get resourcePearls => 'perlas';

  @override
  String get resourceCoffee => 'café';

  @override
  String get resourceCocoa => 'cacao';

  @override
  String get resourceTobacco => 'tabaco';

  @override
  String get resourceSugar => 'azúcar';

  @override
  String get resourceIron => 'hierro';

  @override
  String get resourceCoal => 'carbón';

  @override
  String get resourceOil => 'petróleo';

  @override
  String get resourceAluminium => 'aluminio';

  @override
  String get resourceUranium => 'uranio';

  @override
  String get resourceHorses => 'caballos';

  @override
  String get resourceMarble => 'mármol';

  @override
  String get technologyAgriculture => 'Agricultura';

  @override
  String get technologyWoodworking => 'Carpintería';

  @override
  String get technologyMining => 'Minería';

  @override
  String get technologyAnimalHusbandry => 'Ganadería';

  @override
  String get technologyHunting => 'Caza';

  @override
  String get technologyFishing => 'Pesca';

  @override
  String get technologyCraftsmanship => 'Artesanía';

  @override
  String get technologyTrade => 'Comercio';

  @override
  String get technologyStorage => 'Almacenamiento';

  @override
  String get technologyWaterEngineering => 'Ingeniería hidráulica';

  @override
  String get technologyStoneworking => 'Cantería';

  @override
  String get technologyMilitaryOrganization => 'Organización militar';

  @override
  String get technologyAdvancedTrade => 'Comercio avanzado';

  @override
  String get technologyConstruction => 'Construcción';

  @override
  String get technologyNavigation => 'Navegación';

  @override
  String get technologyIrrigation => 'Irrigación';

  @override
  String get technologyBanking => 'Banca';

  @override
  String get technologyEngineering => 'Ingeniería';

  @override
  String get technologyMetallurgy => 'Metalurgia';

  @override
  String get technologyHorsebackRiding => 'Equitación';

  @override
  String get technologyIronWorking => 'Trabajo del hierro';

  @override
  String get technologyCoalMining => 'Minería del carbón';

  @override
  String get technologyMachinery => 'Maquinaria';

  @override
  String get technologyAdministration => 'Administración';

  @override
  String get technologyLogistics => 'Logística';

  @override
  String get technologyShipbuilding => 'Construcción naval';

  @override
  String get technologyTactics => 'Tácticas';

  @override
  String get technologyEconomy => 'Economía';

  @override
  String get technologyUrbanization => 'Urbanización';

  @override
  String get technologyFortifications => 'Fortificaciones';

  @override
  String get technologyStrategy => 'Estrategia';

  @override
  String get technologySpecialization => 'Especialización';

  @override
  String get technologyWriting => 'Escritura';

  @override
  String get technologyMathematics => 'Matemáticas';

  @override
  String get technologyMedicine => 'Medicina';

  @override
  String get technologyCivilService => 'Servicio civil';

  @override
  String get technologySiegecraft => 'Técnicas de asedio';

  @override
  String get technologyCartography => 'Cartografía';

  @override
  String get technologyGuilds => 'Gremios';

  @override
  String get technologyLaw => 'Ley';

  @override
  String get technologyEducation => 'Educación';

  @override
  String get technologyUrbanPlanning => 'Planificación urbana';

  @override
  String get technologyNavalDoctrine => 'Doctrina naval';

  @override
  String get technologySteel => 'Acero';

  @override
  String get technologyBureaucracy => 'Burocracia';

  @override
  String get technologyNationalism => 'Nacionalismo';

  @override
  String get technologyScientificMethod => 'Método científico';

  @override
  String get technologySteamPower => 'Energía de vapor';

  @override
  String get technologyElectricity => 'Electricidad';

  @override
  String get technologyCombustion => 'Combustión';

  @override
  String get technologyFlight => 'Vuelo';

  @override
  String get technologyMassProduction => 'Producción en masa';

  @override
  String get technologyRadio => 'Radio';

  @override
  String get technologyNuclearPhysics => 'Física nuclear';

  @override
  String get technologyAgricultureDescription =>
      'Abre la ruta básica de crecimiento. Las granjas y granjas fluviales permiten que la población crezca más rápido y estabilizan la primera ciudad.';

  @override
  String get technologyWoodworkingDescription =>
      'Desarrolla el lado productivo de la minería. Los aserraderos convierten los bosques en producción sin profundizar en la metalurgia.';

  @override
  String get technologyMiningDescription =>
      'Abre la ruta de la industria y la infraestructura. Las minas son el primer gran salto en la producción urbana.';

  @override
  String get technologyAnimalHusbandryDescription =>
      'Fortalece el crecimiento mediante recursos animales. Los pastos construyen una economía alimentaria y preparan el camino hacia la equitación.';

  @override
  String get technologyHuntingDescription =>
      'Abre la rama militar y de exploración. Proporciona campamentos y la primera unidad a distancia para la producción urbana.';

  @override
  String get technologyFishingDescription =>
      'Desarrolla ciudades cerca del agua. Los barcos pesqueros ayudan a las ciudades costeras a crecer más rápido y preparan el camino hacia el puerto.';

  @override
  String get technologyCraftsmanshipDescription =>
      'La primera mejora de producción urbana. El taller evita que edificios y unidades posteriores bloqueen la cola demasiado tiempo.';

  @override
  String get technologyTradeDescription =>
      'El primer paso en la economía del oro. La lonja de mercaderes da a una ciudad una recompensa financiera sencilla tras elegir una rama de crecimiento.';

  @override
  String get technologyStorageDescription =>
      'Estabiliza el crecimiento de la ciudad. El almacenamiento ayuda a mantener el ritmo de alimento y reduce el riesgo de estancamientos de desarrollo.';

  @override
  String get technologyWaterEngineeringDescription =>
      'Expande la ruta de crecimiento basada en agua. El molino de agua recompensa a las ciudades que controlan ríos.';

  @override
  String get technologyStoneworkingDescription =>
      'Combina producción y defensa. Las canteras y el cantero fortalecen las ciudades en la rama de infraestructura.';

  @override
  String get technologyMilitaryOrganizationDescription =>
      'Construye el primer núcleo militar de una ciudad. Los cuarteles fortalecen producción y defensa antes de que aparezcan bonificaciones militares posteriores.';

  @override
  String get technologyAdvancedTradeDescription =>
      'Desarrolla la economía tras el comercio. El mercado es un edificio de oro más fuerte y prepara el camino hacia la banca.';

  @override
  String get technologyConstructionDescription =>
      'Expande el territorio y la madurez urbana. Las viviendas aumentan el control de casillas y conducen a administración e ingeniería.';

  @override
  String get technologyNavigationDescription =>
      'Abre una recompensa urbana para la costa. El puerto requiere acceso a costa u océano y recompensa las ciudades ribereñas con alimento y oro.';

  @override
  String get technologyIrrigationDescription =>
      'Especializa el crecimiento basado en agua. El acueducto otorga una fuerte bonificación de alimento y control territorial adicional.';

  @override
  String get technologyBankingDescription =>
      'Especializa la rama comercial. El banco convierte mercados anteriores en fuertes ingresos urbanos y desbloquea la economía más amplia.';

  @override
  String get technologyEngineeringDescription =>
      'Especialización de construcción. El gremio de constructores acelera la producción y aumenta el límite de casillas controladas.';

  @override
  String get technologyMetallurgyDescription =>
      'Una fuerte recompensa industrial tras la cantería. La forja aumenta la producción y prepara el camino hacia el hierro y el carbón.';

  @override
  String get technologyHorsebackRidingDescription =>
      'Una tecnología que vincula crecimiento y guerra. El establo apoya a las ciudades que invirtieron antes en animales y caza.';

  @override
  String get technologyIronWorkingDescription =>
      'Un efecto de recurso industrial. Cada recurso de hierro controlado aumenta la producción de la ciudad.';

  @override
  String get technologyCoalMiningDescription =>
      'Un efecto de recurso industrial posterior. El carbón controlado aumenta la producción de la ciudad y apoya la ruta hacia la fábrica.';

  @override
  String get technologyMachineryDescription =>
      'Una recompensa tardía de infraestructura. La fábrica da un gran aumento de producción a las ciudades que entraron en ingeniería.';

  @override
  String get technologyAdministrationDescription =>
      'Vincula infraestructura y economía. Los ayuntamientos y monumentos fortalecen ciudades maduras y llevan a la urbanización.';

  @override
  String get technologyLogisticsDescription =>
      'Acelera la producción de unidades. Esta es la tecnología principal para jugadores que quieren desplegar ejércitos desde ciudades con más frecuencia.';

  @override
  String get technologyShipbuildingDescription =>
      'Desarrolla la subrama costera y de exploración. El faro requiere acceso costero y fortalece ciudades de ribera.';

  @override
  String get technologyTacticsDescription =>
      'Especialización militar de ciudad. Los campos de entrenamiento añaden defensa y producción para centros militares.';

  @override
  String get technologyEconomyDescription =>
      'Una recompensa sistémica para la banca. Aumenta el oro generado por las economías urbanas.';

  @override
  String get technologyUrbanizationDescription =>
      'La dirección final para el crecimiento de grandes ciudades. Aumenta el límite de población cuando el sistema de población empieza a usar límites estrictos.';

  @override
  String get technologyFortificationsDescription =>
      'Refuerza la defensa de la ciudad. Otorga una bonificación defensiva a la economía urbana, cuyo significado completo crece tras la expansión de combate y asedio.';

  @override
  String get technologyStrategyDescription =>
      'La dirección militar final. Refuerza la efectividad del ejército como recompensa tardía tras la logística.';

  @override
  String get technologySpecializationDescription =>
      'La recompensa cívica/económica final. Desbloquea especializaciones de ciudad, añade ciencia urbana y ayuda a terminar tecnologías tardías en partidas largas.';

  @override
  String get technologyWritingDescription =>
      'El primer paso hacia ciencia, ley y administración. El archivo da a una ciudad una base permanente de investigación.';

  @override
  String get technologyMathematicsDescription =>
      'Conecta la ciencia con la planificación territorial. La oficina de agrimensores ayuda a las ciudades a controlar fronteras con más eficacia.';

  @override
  String get technologyMedicineDescription =>
      'Desarrolla salud y crecimiento a largo plazo en grandes ciudades mediante boticas, baños y hospitales.';

  @override
  String get technologyCivilServiceDescription =>
      'Mejora la gestión de un gran imperio y desbloquea tribunales que estabilizan ciudades.';

  @override
  String get technologySiegecraftDescription =>
      'Abre la guerra de asedio. Las catapultas y los talleres de asedio rompen ciudades fortaleza.';

  @override
  String get technologyCartographyDescription =>
      'Desarrolla exploración, mapas y costa. Otorga la sala de mapas y los primeros barcos exploradores.';

  @override
  String get technologyGuildsDescription =>
      'Da a las ciudades productivas una etapa entre el taller y la industria.';

  @override
  String get technologyLawDescription =>
      'Introduce orden, políticas y gobierno civil mediante tribunales.';

  @override
  String get technologyEducationDescription =>
      'Construye la ruta científica completa para ciudades mediante academias y universidades.';

  @override
  String get technologyUrbanPlanningDescription =>
      'Desarrolla grandes ciudades y control territorial mediante planificación espacial.';

  @override
  String get technologyNavalDoctrineDescription =>
      'Convierte los puertos en centros de flotas, astilleros y proyección de fuerza marítima.';

  @override
  String get technologySteelDescription =>
      'Introduce industria pesada e infantería pesada para el frente posterior.';

  @override
  String get technologyBureaucracyDescription =>
      'Proporciona un gran objetivo cívico tras la administración: oficinas, ministerios, museos y parlamento.';

  @override
  String get technologyNationalismDescription =>
      'Combina defensa fronteriza, movilización e identidad imperial.';

  @override
  String get technologyScientificMethodDescription =>
      'Prepara la ciencia tardía, laboratorios, observatorios y proyectos tecnológicos.';

  @override
  String get technologySteamPowerDescription =>
      'Abre el ferrocarril, logística más pesada e industria de vapor.';

  @override
  String get technologyElectricityDescription =>
      'Introduce energía, infraestructura y alcance de información.';

  @override
  String get technologyCombustionDescription =>
      'Da importancia al petróleo y desbloquea unidades modernas de primera línea.';

  @override
  String get technologyFlightDescription =>
      'Introduce aviación, reconocimiento y proyección de fuerza sobre el frente.';

  @override
  String get technologyMassProductionDescription =>
      'Desarrolla la producción industrial final, tanques y plantas de ensamblaje.';

  @override
  String get technologyRadioDescription =>
      'Fortalece la comunicación, la visibilidad y la influencia del imperio mediante torres de radiodifusión.';

  @override
  String get technologyNuclearPhysicsDescription =>
      'Abre el reactor, el uranio y proyectos tardíos de final de partida.';

  @override
  String get technologyEraFoundation => 'Fundación';

  @override
  String get technologyEraSettlement => 'Asentamiento';

  @override
  String get technologyEraExpansion => 'Expansión';

  @override
  String get technologyEraSpecialization => 'Especialización';

  @override
  String get technologyEraIndustry => 'Industria';

  @override
  String get technologyEraStrategy => 'Estrategia';

  @override
  String get technologyUnlockEffect => 'Efecto';

  @override
  String get technologyPrerequisitesNone => 'Ninguno';

  @override
  String get technologyStateCompleted => 'Completada';

  @override
  String get technologyStateInProgress => 'En progreso';

  @override
  String get technologyStateAvailable => 'Disponible';

  @override
  String get technologyButtonResearched => 'INVESTIGADA';

  @override
  String get technologyButtonActive => 'ACTIVA';

  @override
  String get technologyButtonResearch => 'INVESTIGAR';

  @override
  String get technologyButtonLocked => 'BLOQUEADA';

  @override
  String get technologyTreeTitle => 'ÁRBOL TECNOLÓGICO';

  @override
  String get technologyTreeEmptyTitle => 'No hay tecnologías que mostrar';

  @override
  String get technologyTreeEmptyBody =>
      'El árbol de investigación aparecerá aquí cuando el conjunto de reglas proporcione tecnologías para esta era.';

  @override
  String technologyResearchPointsShort(int points) {
    return '$points pts';
  }

  @override
  String get technologyDetailsTooltip => 'Detalles de tecnología';

  @override
  String get technologyDetailsStatus => 'Estado';

  @override
  String get technologyDetailsCost => 'Coste';

  @override
  String get technologyDetailsProgress => 'Progreso';

  @override
  String get technologyDetailsPrerequisites => 'Requisitos';

  @override
  String get technologyDetailsUnlocks => 'Desbloquea';

  @override
  String get technologyDetailsEffects => 'Efectos';

  @override
  String get technologyDetailsBoosts => 'Impulsos';

  @override
  String get technologyDetailsUnlockStatus => 'Desbloqueo';

  @override
  String get technologyDetailsNoEffects => 'Sin efectos pasivos';

  @override
  String get technologyDetailsNoBoosts => 'Sin impulsos';

  @override
  String get technologyUnlocksNone => 'Sin desbloqueos directos';

  @override
  String get technologyBoostActiveBadge => 'Impulso';

  @override
  String get technologyBoostActiveBest =>
      'El mejor impulso disponible está activo.';

  @override
  String technologyBoostLine(String condition, String discount) {
    return '$condition (-$discount coste)';
  }

  @override
  String get technologyUnlockFieldImprovementCategory => 'Mejora de casilla';

  @override
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  ) {
    return '+$production producción por cada recurso controlado: $resource';
  }

  @override
  String technologyEffectGlobalGoldMultiplier(String percent) {
    return '+$percent oro en la economía urbana';
  }

  @override
  String technologyEffectCityDefenseBonus(int amount) {
    return '+$amount defensa de ciudad';
  }

  @override
  String technologyEffectArmyProductionMultiplier(String percent) {
    return '+$percent producción de unidades en ciudades';
  }

  @override
  String technologyEffectArmyStrengthMultiplier(String percent) {
    return '+$percent fuerza del ejército';
  }

  @override
  String technologyEffectMaxCityPopulationBonus(int amount) {
    return '+$amount población máxima de ciudad';
  }

  @override
  String technologyEffectMaxControlledHexesBonus(int amount) {
    return '+$amount territorio máximo de ciudad';
  }

  @override
  String technologyEffectCityScienceBonus(int amount) {
    return '+$amount ciencia por ciudad';
  }

  @override
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  ) {
    return 'Tener ${count}x $improvement';
  }

  @override
  String technologyBoostConditionHasImprovement(String improvement) {
    return 'Tener $improvement';
  }

  @override
  String technologyBoostConditionControlsResource(String resource) {
    return 'Controlar $resource';
  }

  @override
  String technologyBoostConditionControlsAnyResource(String resources) {
    return 'Controlar: $resources';
  }

  @override
  String technologyEffectAttackBonus(String value) {
    return '$value ataque';
  }

  @override
  String technologyEffectDefenseBonus(String value) {
    return '$value defensa';
  }

  @override
  String get technologyEffectNoArmyStatsBonus =>
      'Sin bonificación de estadísticas de ejército';

  @override
  String technologyEffectArmyStatsBonus(String parts) {
    return '$parts para ejércitos';
  }

  @override
  String commonListOr(String first, String last) {
    return '$first o $last';
  }

  @override
  String get buildingDetailsTooltip => 'Detalles del edificio';

  @override
  String get buildingDetailsNoRequirements => 'Ninguno';

  @override
  String get buildingDetailsYieldImpact => 'Impacto en la ciudad';

  @override
  String buildingDetailsRequirementTechnology(String technology) {
    return 'Tecnología: $technology';
  }

  @override
  String get buildingDetailsRequirementCoastalAccess => 'Acceso costero';

  @override
  String buildingDetailsRequirementResources(String resources) {
    return 'Recurso: $resources';
  }

  @override
  String buildingDetailsFlatYieldEffect(String yield) {
    return '$yield al rendimiento de la ciudad';
  }

  @override
  String buildingDetailsRiverHexYieldEffect(String yield) {
    return '$yield por casilla de río controlada';
  }

  @override
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  ) {
    return '$yield por casilla de río controlada (máx. $maxApplications)';
  }

  @override
  String buildingDetailsMaxControlledHexesEffect(int amount) {
    return '+$amount límite de casillas controladas por la ciudad';
  }

  @override
  String buildingDetailsFoodDepositMultiplierEffect(int percent) {
    return '+$percent% alimento almacenado después del turno';
  }

  @override
  String buildingDetailsYieldFood(String value) {
    return '$value alimento';
  }

  @override
  String buildingDetailsYieldProduction(String value) {
    return '$value producción';
  }

  @override
  String buildingDetailsYieldGold(String value) {
    return '$value oro';
  }

  @override
  String buildingDetailsYieldDefense(String value) {
    return '$value defensa';
  }

  @override
  String buildingDetailsYieldScience(String value) {
    return '$value ciencia';
  }

  @override
  String get buildingDetailsNoYieldChange => 'Sin cambio de recursos';

  @override
  String get unitDetailsTooltip => 'Detalles de unidad';

  @override
  String get unitDetailsMovement => 'Movimiento';

  @override
  String get unitDetailsCombat => 'Combate';

  @override
  String unitDetailsMovementPerTurn(int movement) {
    return '$movement casillas/turno';
  }

  @override
  String get unitDetailsPace => 'Ritmo';

  @override
  String unitDetailsRequirementTechnology(String technology) {
    return 'Tecnología: $technology';
  }

  @override
  String unitDetailsAttackLine(int value) {
    return 'Ataque: $value';
  }

  @override
  String unitDetailsDefenseLine(int value) {
    return 'Defensa: $value';
  }

  @override
  String unitDetailsHpLine(int value) {
    return 'PV: $value';
  }

  @override
  String unitDetailsRangeLine(int value) {
    return 'Alcance: $value';
  }

  @override
  String sciencePerTurn(int science) {
    return '$science ciencia/turno';
  }

  @override
  String get activeResearchLabel => 'INVESTIGANDO';

  @override
  String get requirementTechnology => 'Requiere tecnología';

  @override
  String requirementTechnologyName(String technology) {
    return 'Requiere: $technology';
  }

  @override
  String requirementResourcesName(String resources) {
    return 'Requiere: $resources';
  }

  @override
  String technologyBlockedBy(String technology) {
    return 'Bloqueada por: $technology';
  }

  @override
  String get requirementCoastalAccess => 'Requiere: acceso costero';

  @override
  String get productionCategoryBuilding => 'Edificio';

  @override
  String get productionCategoryUnit => 'Unidad';

  @override
  String get productionTitle => 'PRODUCCIÓN';

  @override
  String get productionInProgressLabel => 'EN PROGRESO';

  @override
  String productionPerTurn(int production) {
    return '$production producción/turno';
  }

  @override
  String get productionNoProduction => 'sin producción';

  @override
  String get productionButtonProduce => 'PRODUCIR';

  @override
  String get productionButtonLocked => 'BLOQUEADA';

  @override
  String get productionEmptyState =>
      'No hay producción disponible actualmente.';

  @override
  String get buildingsSection => 'Edificios';

  @override
  String get unitsSection => 'Unidades';

  @override
  String futureBuildingsSection(int count) {
    return 'Edificios futuros ($count)';
  }

  @override
  String get futureBuildingsSubtitle => 'Desbloqueados por tecnologías';

  @override
  String workerPanelTitle(String unitName) {
    return 'Trabajador - $unitName';
  }

  @override
  String get commonOpenAction => 'Abrir';

  @override
  String get commonShowDetailsAction => 'Mostrar detalles';

  @override
  String get commonExecuteAction => 'Ejecutar';

  @override
  String colorPickerChangeTooltip(String label) {
    return 'Cambiar color: $label';
  }

  @override
  String colorPickerColorSelected(String hex) {
    return '#$hex seleccionado';
  }

  @override
  String colorPickerSelectColor(String hex) {
    return 'Seleccionar #$hex';
  }

  @override
  String get commonDescription => 'Descripción';

  @override
  String get commonSummary => 'Resumen';

  @override
  String get commonStatus => 'Estado';

  @override
  String get commonTerrain => 'Terreno';

  @override
  String get commonResources => 'Recursos';

  @override
  String get commonImprovements => 'Mejoras';

  @override
  String get commonCities => 'Ciudades';

  @override
  String get commonBuildings => 'Edificios';

  @override
  String get commonGold => 'Oro';

  @override
  String get commonScience => 'Ciencia';

  @override
  String get commonProduction => 'Producción';

  @override
  String get commonResearch => 'Investigación';

  @override
  String get commonEmpire => 'Imperio';

  @override
  String get commonTurn => 'Turno';

  @override
  String get commonProjects => 'Proyectos';

  @override
  String get commonPopulation => 'Población';

  @override
  String get commonTechnologies => 'Tecnologías';

  @override
  String get commonFields => 'Casillas';

  @override
  String get commonMultipliers => 'Multiplicadores';

  @override
  String get commonOther => 'Otro';

  @override
  String get commonReady => 'Listo';

  @override
  String get commonDone => 'Hecho';

  @override
  String get commonDefault => 'Predeterminado';

  @override
  String get commonAvailable => 'Disponible';

  @override
  String get commonBlocked => 'Bloqueado';

  @override
  String get commonSelectAction => 'Seleccionar';

  @override
  String get commonSelectedAction => 'Seleccionado';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDoNotShowAgain => 'No volver a mostrar';

  @override
  String get commonNoneLower => 'ninguno';

  @override
  String get visualCurrentLabel => 'Ahora';

  @override
  String get visualAfterLabel => 'Tras el cambio';

  @override
  String get terrainDetailEmpty => 'Sin información de terreno';

  @override
  String get yieldFoodShort => 'ALIMENTO';

  @override
  String get yieldProductionShort => 'PROD';

  @override
  String get yieldGoldShort => 'ORO';

  @override
  String get yieldDefenseShort => 'DEF';

  @override
  String selectionChipBadgeSuffix(String badge) {
    return ' Contador visible: $badge.';
  }

  @override
  String selectionChipDisabledDescription(String badge) {
    return 'Este acceso rápido de información no está disponible para la selección actual.$badge';
  }

  @override
  String selectionChipOpenDescription(String label, String badge) {
    return 'Abre los detalles de “$label” para el contexto actual del mapa.$badge';
  }

  @override
  String get gameGoalTitle => 'Objetivo de la partida';

  @override
  String get globalHudCloseResearch => 'Cerrar investigación';

  @override
  String globalHudResearchActive(String technologyName) {
    return 'Investigación: $technologyName';
  }

  @override
  String globalHudResearchActiveWithEta(String technologyName, String eta) {
    return 'Investigación: $technologyName · $eta';
  }

  @override
  String get globalHudChooseResearch => 'Elegir investigación';

  @override
  String get globalHudCloseEmpire => 'Cerrar imperio';

  @override
  String get globalHudCloseActivityLog => 'Cerrar registro de actividad';

  @override
  String get bottomToolbarWaiting => 'Esperando';

  @override
  String get bottomToolbarPlan => 'Plan';

  @override
  String get bottomToolbarMove => 'Mover';

  @override
  String get bottomToolbarResolvingTurn => 'Resolviendo turno';

  @override
  String bottomToolbarWaitingFor(String players) {
    return 'Esperando: $players';
  }

  @override
  String turnHintNextUnit(String unit) {
    return 'Siguiente paso: $unit';
  }

  @override
  String turnHintNextCityProduction(String city) {
    return 'Siguiente paso: producción en $city';
  }

  @override
  String get turnHintChooseResearch => 'Siguiente paso: elegir investigación';

  @override
  String get turnHintCheckAction => 'Siguiente paso: comprobar acción';

  @override
  String turnHintObjective(String objective) {
    return 'Objetivo: $objective';
  }

  @override
  String turnHintObjectiveWithAdvice(String objective, String advice) {
    return 'Objetivo: $objective · $advice';
  }

  @override
  String get turnHintImproveFieldWithWorker =>
      'Objetivo: mejorar una casilla con un trabajador';

  @override
  String get turnHintFoundCityWithSettler =>
      'Objetivo: fundar una ciudad con un colono';

  @override
  String get turnHintClaimTerritoryWithSettler =>
      'Objetivo: reclamar territorio con un colono';

  @override
  String turnHintTrainUnit(String unit) {
    return 'Objetivo: establecer unidad: $unit';
  }

  @override
  String turnHintProtectLeadUnit(String unit) {
    return 'Objetivo: asegurar el liderazgo: $unit';
  }

  @override
  String turnHintConstructBuildingInCity(String city) {
    return 'Objetivo: poner un edificio en cola en $city';
  }

  @override
  String turnHintTrainUnitInCity(String city) {
    return 'Objetivo: poner una unidad en cola en $city';
  }

  @override
  String turnHintPrepareSettlerInCity(String city) {
    return 'Objetivo: preparar un colono en $city';
  }

  @override
  String turnHintGrowPopulationInCity(String city) {
    return 'Objetivo: establecer crecimiento en $city';
  }

  @override
  String turnHintPrepareWorkerInCity(String city) {
    return 'Objetivo: preparar un trabajador en $city';
  }

  @override
  String turnHintCollectGoldInCity(String city) {
    return 'Objetivo: cerrar oro en $city';
  }

  @override
  String turnHintProtectLeadProductionInCity(String city) {
    return 'Objetivo: asegurar producción en $city';
  }

  @override
  String get turnHintUnlockTechnologyForScore =>
      'Objetivo: elegir una tecnología de puntuación';

  @override
  String get turnHintProtectLeadResearch =>
      'Objetivo: terminar investigación segura';

  @override
  String topResourceTurnShortLabel(int turn) {
    return 'T$turn';
  }

  @override
  String topResourceTurnTooltip(int turn) {
    return 'Turno $turn';
  }

  @override
  String topResourceScienceTooltip(String scienceTurnLabel) {
    return 'Ciencia: $scienceTurnLabel / turno';
  }

  @override
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes) {
    return 'Recursos: $resourceTotal depósitos • $resourceTypes tipos controlados';
  }

  @override
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  ) {
    return 'Oro: $gold • ingresos +$goldIncome • mantenimiento -$unitUpkeep • neto $net / turno';
  }

  @override
  String topResourceGoldTooltipNegativeTreasury(String base) {
    return '$base • tesorería por debajo de cero';
  }

  @override
  String topResourceGoldTooltipBankruptcy(String base) {
    return '$base • riesgo de bancarrota en 3 turnos';
  }

  @override
  String get resourceBreakdownTreasury => 'Tesorería';

  @override
  String get resourceBreakdownCityIncome => 'Ingresos de ciudad';

  @override
  String get resourceBreakdownUpkeep => 'Mantenimiento';

  @override
  String get resourceBreakdownNetPerTurn => 'Neto / turno';

  @override
  String get resourceBreakdownNoCityIncome => 'Sin ingresos de ciudad';

  @override
  String get resourceBreakdownFreeLimit => 'Límite gratuito';

  @override
  String get resourceBreakdownNextWorkerUpkeep =>
      'Mantenimiento del siguiente trabajador';

  @override
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep) {
    return '-$upkeep oro/turno';
  }

  @override
  String get resourceBreakdownInsideFreeLimit => 'Dentro del límite gratuito';

  @override
  String get resourceBreakdownNoActiveTechnology =>
      'No hay tecnología seleccionada';

  @override
  String get resourceBreakdownScienceTitle => 'Ciencia e investigación';

  @override
  String get resourceBreakdownSciencePerTurn => 'Ciencia / turno';

  @override
  String get resourceBreakdownActiveResearch => 'Investigación activa';

  @override
  String get resourceBreakdownTurnsToComplete => 'Para completar';

  @override
  String get resourceBreakdownNoScienceSources => 'Sin fuentes de ciencia';

  @override
  String resourceBreakdownCityResearchProject(String cityName) {
    return '$cityName: Investigación';
  }

  @override
  String get resourceBreakdownNoControlledResources =>
      'Sin recursos controlados';

  @override
  String get resourceBreakdownGrowCitiesWithFood =>
      'Haz crecer ciudades con alimento';

  @override
  String get resourceBreakdownControlledDeposits => 'Depósitos controlados';

  @override
  String get resourceBreakdownResourceTypes => 'Tipos de recurso';

  @override
  String get resourceBreakdownTypesSection => 'Tipos';

  @override
  String get resourceBreakdownSourcesSection => 'Fuentes';

  @override
  String get technologyRecommendationsTitle => 'Investigación recomendada';

  @override
  String get technologyShowTreeAction => 'Mostrar árbol';

  @override
  String technologyShowTreeCountAction(int count) {
    return 'Mostrar árbol ($count)';
  }

  @override
  String get technologyRecommendationUnlocks => 'Desbloquea';

  @override
  String get technologyRecommendationReasonBoost =>
      'Un impulso activo reduce el coste de investigación.';

  @override
  String get technologyRecommendationReasonSection => 'Por qué ahora';

  @override
  String get technologyRecommendationReasonImprovements =>
      'Nuevas mejoras de casilla convierten recursos en rendimiento rápidamente.';

  @override
  String get technologyRecommendationReasonBuilding =>
      'Un nuevo edificio de ciudad abre otra dirección de desarrollo.';

  @override
  String get technologyRecommendationReasonUnit =>
      'Una nueva unidad refuerza la seguridad y el control del mapa.';

  @override
  String get technologyRecommendationReasonEffect =>
      'Una bonificación permanente se aplica a toda la economía.';

  @override
  String get technologyRecommendationReasonFast =>
      'Investigación rápida sin requisitos extra.';

  @override
  String get technologyRecommendationReasonDefault =>
      'Investigación disponible que cierra limpiamente el siguiente paso.';

  @override
  String get technologyNoRecommendations =>
      'No hay nuevas investigaciones disponibles actualmente.';

  @override
  String get technologyFullTreeTitle => 'Árbol tecnológico completo';

  @override
  String get technologyRecommendationsBackAction => 'Recomendaciones';

  @override
  String get empireUnitsEmptyTitle => 'Sin unidades';

  @override
  String get empireUnitsEmptyBody =>
      'Las nuevas unidades aparecerán aquí tras la producción de ciudad o el reclutamiento por evento.';

  @override
  String get empireCitiesEmptyTitle => 'Sin ciudades';

  @override
  String get empireCitiesEmptyBody =>
      'Funda tu primera ciudad con un colono para desbloquear producción, ciencia y fronteras del imperio.';

  @override
  String get empireCityCenters => 'Centros urbanos';

  @override
  String get empireShowFirstUnitTooltip =>
      'Mostrar la primera unidad en el mapa';

  @override
  String get empireShowUnitTooltip => 'Mostrar unidad en el mapa';

  @override
  String get empireShowFirstCityTooltip =>
      'Mostrar la primera ciudad en el mapa';

  @override
  String get empireShowCityTooltip => 'Mostrar ciudad en el mapa';

  @override
  String empireUnitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unidades',
      one: '1 unidad',
    );
    return '$_temp0';
  }

  @override
  String empireCityCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ciudades',
      one: '1 ciudad',
    );
    return '$_temp0';
  }

  @override
  String empireUnitMovement(int movement) {
    return 'Movimiento $movement';
  }

  @override
  String get empireUnitBuilding => 'Construyendo';

  @override
  String get empireUnitWorking => 'Trabajando';

  @override
  String get empireUnitFortifying => 'Fortificando';

  @override
  String get empireUnitHealing => 'Curándose';

  @override
  String get empireUnitEnRoute => 'En ruta';

  @override
  String get empireUnitNoMovement => 'sin movimiento';

  @override
  String empireUnitsWithMovement(int count) {
    return '$count con movimiento';
  }

  @override
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  ) {
    return 'Población $population - $hexes casillas - $buildings edif. - produciendo: $production';
  }

  @override
  String empireCityStoredArtifact(String artifactName) {
    return 'Artefacto: $artifactName';
  }

  @override
  String empireCityGroupSubtitle(String cityLabel, int population) {
    return '$cityLabel - población $population';
  }

  @override
  String get empireStatsTitle => 'Estado del imperio';

  @override
  String get empireStatsSubtitle =>
      'Una lectura rápida de preparación, composición y crecimiento urbano';

  @override
  String get empireStatsReadinessTitle => 'Preparación de unidades';

  @override
  String get empireStatsUnitCompositionTitle => 'Composición de unidades';

  @override
  String get empireStatsCityDevelopmentTitle => 'Desarrollo de ciudad';

  @override
  String get empireStatsCityComparisonTitle => 'Comparación de ciudades';

  @override
  String get empireStatsOrders => 'Con órdenes';

  @override
  String get empireStatsNoMovement => 'Sin movimiento';

  @override
  String get empireStatsAveragePopulation => 'Pob. media';

  @override
  String get empireStatsTotalBuildings => 'Edificios';

  @override
  String get empireStatsStoredArtifacts => 'Artefactos';

  @override
  String get empireStatsTerritory => 'Territorio';

  @override
  String get empireStatsCitiesProducing => 'Producción';

  @override
  String get empireStatsOther => 'Otro';

  @override
  String get empireStatsEmptyUnits => 'No hay unidades que analizar';

  @override
  String get empireStatsEmptyCities => 'No hay ciudades que analizar';

  @override
  String empireStatsCityBarDetail(int population, int buildings) {
    return 'Pob. $population • edif. $buildings';
  }

  @override
  String empireStatsCityComparisonDetail(
    int population,
    int production,
    int food,
    int gold,
  ) {
    return 'Pob. $population • Prod. $production • Alimento $food • Oro $gold';
  }

  @override
  String get empireStatsMetricPopulation => 'Pob.';

  @override
  String get empireStatsMetricProduction => 'Prod.';

  @override
  String get empireStatsMetricFood => 'Alimento';

  @override
  String get empireStatsMetricGold => 'Oro';

  @override
  String get activityLogTitle => 'Registro de actividad';

  @override
  String get activityLogShowAllAction => 'Mostrar todo';

  @override
  String activityLogShowMoreAction(int visible, int total) {
    return 'Mostrar más ($visible/$total)';
  }

  @override
  String get activityLogLoadingHistory => 'Cargando historial completo...';

  @override
  String get activityLogHistoryErrorTitle => 'No se pudo cargar el historial';

  @override
  String activityLogHistoryErrorBody(String error) {
    return 'El diario de eventos no está disponible: $error';
  }

  @override
  String get activityLogFilterAll => 'Todo';

  @override
  String get activityLogFilterAllShort => 'Todo';

  @override
  String get activityLogFilterCombat => 'Combate';

  @override
  String get activityLogFilterCities => 'Ciudades';

  @override
  String get activityLogFilterDiplomacy => 'Diplomacia';

  @override
  String get activityLogFilterDiplomacyShort => 'Dipl.';

  @override
  String get activityLogFilterTechnology => 'Ciencia';

  @override
  String get activityLogEmptyAllTitle => 'No hay eventos registrados';

  @override
  String get activityLogEmptyCombatTitle => 'No hay batallas registradas';

  @override
  String get activityLogEmptyCityTitle =>
      'No hay eventos de ciudad registrados';

  @override
  String get activityLogEmptyDiplomacyTitle => 'No hay diplomacia registrada';

  @override
  String get activityLogEmptyTechnologyTitle =>
      'No hay descubrimientos registrados';

  @override
  String get activityLogEmptyAllBody =>
      'Los primeros descubrimientos, batallas y construcciones aparecerán aquí tras realizar acciones.';

  @override
  String get activityLogEmptyCombatBody =>
      'Las batallas se registran tras ataques o defensas visibles para el jugador.';

  @override
  String get activityLogEmptyCityBody =>
      'Las ciudades fundadas, construcciones y casillas reclamadas crearán aquí la línea temporal del imperio.';

  @override
  String get activityLogEmptyDiplomacyBody =>
      'Los despachos, propuestas, respuestas y cambios de relación aparecerán aquí tras acciones diplomáticas.';

  @override
  String get activityLogEmptyTechnologyBody =>
      'Las tecnologías descubiertas aparecerán aquí cuando la investigación se complete.';

  @override
  String get turnTimelineTitle => 'Línea temporal de turnos';

  @override
  String turnTimelineSubtitle(int turn, int count) {
    return 'Turno $turn • eventos: $count';
  }

  @override
  String get turnTimelineChartTitle => 'Eventos a lo largo de los turnos';

  @override
  String get turnTimelineMetricEvents => 'Eventos';

  @override
  String get turnTimelineMetricActiveTurns => 'Turnos activos';

  @override
  String get turnTimelineMetricCurrentTurn => 'Turno actual';

  @override
  String get technologyDiscoveryEyebrow => 'Tecnología descubierta';

  @override
  String unitSelectionMovementSubtitle(int current, int max) {
    return 'Mover $current/$max';
  }

  @override
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  ) {
    return 'Mover $current/$max • PV $hp/$maxHp';
  }

  @override
  String get unitSelectionAttackLabel => 'Ataque';

  @override
  String get unitSelectionDefenseLabel => 'Defensa';

  @override
  String get unitSelectionHpLabel => 'PV';

  @override
  String get unitSelectionRangeLabel => 'Alcance';

  @override
  String get unitSelectionConstructionLabel => 'Construcción';

  @override
  String get unitSelectionWorkLabel => 'Trabajo';

  @override
  String get unitSelectionFieldBonusValue => 'Bonificación de casilla';

  @override
  String get tileSelectionYieldTitle => 'Potencial de la casilla';

  @override
  String get tileSelectionYieldTooltip =>
      'Estimación de inspección para esta casilla, no rendimiento real de ciudad.';

  @override
  String get tileSelectionBonusLabel => 'Bonificación';

  @override
  String get tileSelectionDefenseBonusValue => '+defensa';

  @override
  String get tileSelectionRiverBonusValue => '+río';

  @override
  String get citySelectionYieldTitle => 'Ingresos de ciudad';

  @override
  String get citySelectionYieldTooltip =>
      'Rendimiento real por turno desde la economía urbana.';

  @override
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  ) {
    return 'Población $population • $territoryHexCount/$maxHexes casillas • Producción: $production';
  }

  @override
  String get citySelectionTerritoryLabel => 'Territorio';

  @override
  String get citySelectionFoodLabel => 'Alimento';

  @override
  String get citySelectionNetFoodLabel => 'Alimento neto';

  @override
  String get citySelectionBuildingsLabel => 'Edificios';

  @override
  String get citySelectionArtifactLabel => 'Artefacto';

  @override
  String get worldArtifactBonusTitle => 'Bonificación';

  @override
  String get worldArtifactHeritageTitle => 'Patrimonio';

  @override
  String get worldArtifactHeritageBody =>
      'Recolecta y coloca 6 artefactos únicos en tus ciudades, y luego conserva la colección durante 5 turnos.';

  @override
  String get worldArtifactAncientImperialCrown => 'Antigua corona imperial';

  @override
  String get worldArtifactAstronomersTablets => 'Tablillas de los astrónomos';

  @override
  String get worldArtifactProphetMask => 'Máscara del profeta';

  @override
  String get worldArtifactHeroSword => 'Espada del héroe';

  @override
  String get worldArtifactMerchantsSeal => 'Sello del mercader';

  @override
  String get worldArtifactFirstPeoplesChronicle =>
      'Crónica de los primeros pueblos';

  @override
  String get worldArtifactTempleReliquary => 'Relicario del templo';

  @override
  String get worldArtifactQueensMirror => 'Espejo de la reina';

  @override
  String get worldArtifactAncientImperialCrownShortBonus => '+1 defensa';

  @override
  String get worldArtifactAstronomersTabletsShortBonus => '+1 ciencia';

  @override
  String get worldArtifactProphetMaskShortBonus => '+1 oro, diplomacia';

  @override
  String get worldArtifactHeroSwordShortBonus =>
      '+2 XP para unidades producidas';

  @override
  String get worldArtifactMerchantsSealShortBonus => '+2 oro';

  @override
  String get worldArtifactFirstPeoplesChronicleShortBonus => '+1 alimento';

  @override
  String get worldArtifactTempleReliquaryShortBonus =>
      '+1 alimento, +1 defensa';

  @override
  String get worldArtifactQueensMirrorShortBonus => '+1 oro, diplomacia';

  @override
  String get worldArtifactAncientImperialCrownDescription =>
      'Un símbolo del antiguo gobierno. Una vez guardada en una ciudad, fortalece la defensa y el prestigio de la colección.';

  @override
  String get worldArtifactAstronomersTabletsDescription =>
      'Tablillas de piedra con antiguos mapas del cielo. En una ciudad, apoyan la ciencia.';

  @override
  String get worldArtifactProphetMaskDescription =>
      'Una máscara ritual de gran peso político. En una ciudad, concede oro y valor diplomático.';

  @override
  String get worldArtifactHeroSwordDescription =>
      'El arma de un comandante legendario. Las unidades producidas en esta ciudad ganan experiencia adicional.';

  @override
  String get worldArtifactMerchantsSealDescription =>
      'La marca de los primeros gremios de mercaderes. En una ciudad, fortalece los ingresos de oro.';

  @override
  String get worldArtifactFirstPeoplesChronicleDescription =>
      'Un registro de los linajes y fronteras más antiguos. En una ciudad, apoya el crecimiento.';

  @override
  String get worldArtifactTempleReliquaryDescription =>
      'Un relicario sagrado que da a la ciudad estabilidad, alimento y defensa.';

  @override
  String get worldArtifactQueensMirrorDescription =>
      'Un tesoro cortesano que une comercio y diplomacia. En una ciudad, concede oro y prestigio.';

  @override
  String get worldArtifactLocationMap => 'Artefacto en el mapa';

  @override
  String get worldArtifactLocationExcavation => 'Excavación en progreso';

  @override
  String get worldArtifactLocationCarried => 'Transportado por una unidad';

  @override
  String get worldArtifactLocationStored => 'Guardado en una ciudad';

  @override
  String get worldArtifactStepExcavate => 'Excavar';

  @override
  String get worldArtifactStepMove => 'Mover';

  @override
  String get worldArtifactStepStore => 'Guardar';

  @override
  String get artifactGuidanceUnknownCityName => 'una ciudad';

  @override
  String get artifactGuidanceStoredTitle => 'Artefacto guardado';

  @override
  String artifactGuidanceStoredBody(String artifactName, String cityName) {
    return '$artifactName fortalece $cityName. La victoria cultural necesita 6 artefactos en ciudades durante 5 turnos.';
  }

  @override
  String get artifactGuidanceCarriedTitle => 'Artefacto transportado';

  @override
  String artifactGuidanceCarriedBody(String artifactName) {
    return 'La unidad transporta $artifactName. Llévalo a una de tus ciudades con un espacio libre y usa la acción de guardar.';
  }

  @override
  String get artifactGuidanceReachedTitle => 'Artefacto descubierto';

  @override
  String artifactGuidanceReachedBody(String artifactName) {
    return '$artifactName está bajo la unidad. Usa la acción Excavar para recogerlo.';
  }

  @override
  String get citySelectionSpecializationLabel => 'Especialización';

  @override
  String get fieldImprovementOutsideActiveCity => 'Fuera de la ciudad activa';

  @override
  String get fieldImprovementYieldTitle => 'Bonificación de mejora';

  @override
  String get fieldImprovementYieldTooltip =>
      'Rendimiento adicional de la mejora de casilla.';

  @override
  String get hexKindIdealCitySite => 'Sitio de ciudad ideal';

  @override
  String get hexKindGoodCitySite => 'Buen sitio de ciudad';

  @override
  String get hexKindFertileField => 'Campo fértil';

  @override
  String get hexKindFertilePlains => 'Llanuras fértiles';

  @override
  String get hexKindRichPlain => 'Llanura rica';

  @override
  String get hexKindStrategicBorderland => 'Territorio fronterizo estratégico';

  @override
  String get hexKindStrategicField => 'Campo estratégico';

  @override
  String get hexKindDefensivePosition => 'Posición defensiva';

  @override
  String get hexKindFertileForest => 'Bosque fértil';

  @override
  String get hexKindForestBackline => 'Retaguardia boscosa';

  @override
  String get hexKindForestForge => 'Forja forestal';

  @override
  String get hexKindWildLand => 'Tierra salvaje';

  @override
  String get hexKindRichWilds => 'Tierras salvajes ricas';

  @override
  String get hexKindExoticBackline => 'Retaguardia exótica';

  @override
  String get hexKindDifficultStrategicTerrain => 'Terreno estratégico difícil';

  @override
  String get hexKindHighGround => 'Altura';

  @override
  String get hexKindRiverHills => 'Colinas fluviales';

  @override
  String get hexKindIndustrialStronghold => 'Bastión industrial';

  @override
  String get hexKindRichHills => 'Colinas ricas';

  @override
  String get hexKindBarrenLand => 'Tierra estéril';

  @override
  String get hexKindOasis => 'Oasis';

  @override
  String get hexKindTradeOasis => 'Oasis comercial';

  @override
  String get hexKindDesertDeposits => 'Depósitos del desierto';

  @override
  String get hexKindHarshLand => 'Tierra dura';

  @override
  String get hexKindColdPastures => 'Pastos fríos';

  @override
  String get hexKindResourceOutpost => 'Puesto avanzado de recursos';

  @override
  String get hexKindHostileLand => 'Tierra hostil';

  @override
  String get hexKindArcticDeposits => 'Depósitos árticos';

  @override
  String get hexKindCoast => 'Costa';

  @override
  String get hexKindFishingCoast => 'Costa pesquera';

  @override
  String get hexKindRichCoast => 'Costa rica';

  @override
  String get hexKindRiverPort => 'Puerto fluvial';

  @override
  String get hexKindRegionalPortHeart => 'Centro portuario regional';

  @override
  String get hexKindOpenSea => 'Mar abierto';

  @override
  String get hexKindNaturalBarrier => 'Barrera natural';

  @override
  String get hexKindPromisingLand => 'Tierra prometedora';

  @override
  String get hexKindWeakLand => 'Tierra débil';

  @override
  String get hexKindOrdinaryLand => 'Tierra común';

  @override
  String get hexKindMapTile => 'Casilla del mapa';

  @override
  String get hexKindIdealCitySiteDescription =>
      'Una casilla de asentamiento de alto valor con alimento, crecimiento y presión de expansión ya alineados.';

  @override
  String get hexKindGoodCitySiteDescription =>
      'Terreno sólido para un centro urbano con suficiente valor básico para apoyar el crecimiento temprano.';

  @override
  String get hexKindFertileFieldDescription =>
      'Pradera alimentada por río que favorece alimento, crecimiento de población y mejoras de trabajadores.';

  @override
  String get hexKindFertilePlainsDescription =>
      'Llanuras abiertas con apoyo fluvial, útiles para equilibrar alimento y producción.';

  @override
  String get hexKindRichPlainDescription =>
      'Una valiosa casilla abierta con lujo o valor comercial que merece incorporarse a las fronteras.';

  @override
  String get hexKindStrategicBorderlandDescription =>
      'Buena tierra con valor estratégico, útil para expandirse antes de que los rivales la reclamen.';

  @override
  String get hexKindStrategicFieldDescription =>
      'Una casilla de llanura ligada a recursos estratégicos o presión en la frontera.';

  @override
  String get hexKindDefensivePositionDescription =>
      'Terreno que mejora el control defensivo y ayuda a mantener accesos cercanos.';

  @override
  String get hexKindFertileForestDescription =>
      'Un bosque con apoyo fluvial, que mezcla potencial de crecimiento con cobertura natural.';

  @override
  String get hexKindForestBacklineDescription =>
      'Una casilla boscosa más segura que puede apoyar crecimiento o mejoras orientadas a la caza.';

  @override
  String get hexKindForestForgeDescription =>
      'Bosque con valor de recurso industrial, prometedor para producción una vez mejorado.';

  @override
  String get hexKindWildLandDescription =>
      'Terreno denso con fricción; útil solo cuando tienes un plan claro de trabajador o expansión.';

  @override
  String get hexKindRichWildsDescription =>
      'Terreno salvaje con suficiente fertilidad o recursos para justificar un desarrollo cuidadoso.';

  @override
  String get hexKindExoticBacklineDescription =>
      'Una casilla de jungla o humedal con valor de lujo para fronteras y comercio posteriores.';

  @override
  String get hexKindDifficultStrategicTerrainDescription =>
      'Terreno difícil con valor de recurso estratégico; poderoso más tarde, incómodo al principio.';

  @override
  String get hexKindHighGroundDescription =>
      'Colinas que favorecen defensa y control del mapa más que crecimiento rápido.';

  @override
  String get hexKindRiverHillsDescription =>
      'Colinas junto a un río, que combinan defensa con mejor potencial económico.';

  @override
  String get hexKindIndustrialStrongholdDescription =>
      'Colinas con recursos industriales, un fuerte objetivo de producción para una ciudad.';

  @override
  String get hexKindRichHillsDescription =>
      'Colinas con recursos de riqueza, útiles para expansión centrada en oro o producción.';

  @override
  String get hexKindBarrenLandDescription =>
      'Tierra seca con poco valor inmediato salvo que tecnología o fronteras posteriores cambien el plan.';

  @override
  String get hexKindOasisDescription =>
      'Desierto suavizado por acceso fluvial, que convierte tierra débil en una casilla de crecimiento usable.';

  @override
  String get hexKindTradeOasisDescription =>
      'Un bolsillo comercial desértico que puede volverse valioso con la mejora adecuada.';

  @override
  String get hexKindDesertDepositsDescription =>
      'Mala tierra de asentamiento con un depósito estratégico que importa más en eras posteriores.';

  @override
  String get hexKindHarshLandDescription =>
      'Tierra fría o abrupta con economía temprana limitada y desarrollo lento.';

  @override
  String get hexKindColdPasturesDescription =>
      'Terreno frío con suficiente valor de pasto para apoyar una ciudad fronteriza.';

  @override
  String get hexKindResourceOutpostDescription =>
      'Tierra fría remota que merece reclamarse principalmente por el recurso que protege.';

  @override
  String get hexKindHostileLandDescription =>
      'Terreno poco amistoso con bajo valor de asentamiento y pocos retornos inmediatos.';

  @override
  String get hexKindArcticDepositsDescription =>
      'Tierra nevada con recursos, difícil de usar pero estratégicamente relevante.';

  @override
  String get hexKindCoastDescription =>
      'Tierra costera que abre acceso naval y crecimiento urbano flexible.';

  @override
  String get hexKindFishingCoastDescription =>
      'Costa con valor alimentario, una razón fuerte para trabajar o asentarse cerca del agua.';

  @override
  String get hexKindRichCoastDescription =>
      'Lujo costero o valor comercial que merece incorporarse a las fronteras de la ciudad.';

  @override
  String get hexKindRiverPortDescription =>
      'Una desembocadura con valor comercial y de movimiento para una ciudad costera.';

  @override
  String get hexKindRegionalPortHeartDescription =>
      'Un fuerte centro costero donde se combinan valor fluvial y de recursos.';

  @override
  String get hexKindOpenSeaDescription =>
      'Agua útil para barcos y exploración, pero no para asentamientos terrestres.';

  @override
  String get hexKindNaturalBarrierDescription =>
      'Terreno bloqueado que moldea movimiento y defensa más que la economía.';

  @override
  String get hexKindPromisingLandDescription =>
      'Una casilla generalmente útil con suficiente valor para inspeccionarla antes de seguir.';

  @override
  String get hexKindWeakLandDescription =>
      'Terreno de bajo rendimiento que rara vez merece tiempo temprano de trabajador.';

  @override
  String get hexKindOrdinaryLandDescription =>
      'Una casilla normal sin fortaleza destacada, útil cuando encaja con el plan de ciudad.';

  @override
  String get hexKindMapTileDescription =>
      'Una casilla de mapa simple sin suficiente información para emitir un juicio fuerte.';

  @override
  String get hexTagCity => 'Sitio de ciudad';

  @override
  String get hexTagDefense => 'Posición defensiva';

  @override
  String get hexTagTrade => 'Ruta comercial';

  @override
  String get hexTagFertile => 'Campo fértil';

  @override
  String get hexTagProduction => 'Buena producción';

  @override
  String get hexTagHostile => 'Tierra hostil';

  @override
  String get hexTagStrategic => 'Recurso estratégico';

  @override
  String get hexTagWater => 'Paso de agua';

  @override
  String get hexRecommendationFoundCity => 'Buen sitio de desarrollo';

  @override
  String get hexRecommendationDefendHere => 'Buena posición defensiva';

  @override
  String get hexRecommendationExploitEconomy => 'Vale la pena explotarlo';

  @override
  String get hexRecommendationAvoid => 'Evitar sin un plan';

  @override
  String get hexRecommendationNeutral => 'Inspeccionar antes de moverse';

  @override
  String get hexRecommendationFoundCityDetail =>
      'Si las fronteras están libres, considera fundar aquí o dirigir un colono hacia este lugar.';

  @override
  String get hexRecommendationDefendHereDetail =>
      'Úsalo para anclar unidades, proteger fronteras o cubrir ciudades cercanas.';

  @override
  String get hexRecommendationExploitEconomyDetail =>
      'Incorpóralo a las fronteras y asigna un trabajador cuando la ciudad pueda beneficiarse.';

  @override
  String get hexRecommendationAvoidDetail =>
      'Omítelo al principio salvo que un recurso, ruta o necesidad militar cambie su valor.';

  @override
  String get hexRecommendationNeutralDetail =>
      'Explora casillas vecinas y compara recursos antes de comprometer un trabajador o colono.';

  @override
  String get selectionActionLockedReason => 'No puedes emitir órdenes ahora.';

  @override
  String get selectionActionFoundCity => 'Fundar ciudad';

  @override
  String get selectionActionCancel => 'Cancelar';

  @override
  String get selectionActionCancelAttack => 'Cancelar ataque';

  @override
  String get selectionActionCancelWorkerBuild => 'Cancelar mejora';

  @override
  String get selectionActionCancelCityFounding =>
      'Cancelar fundación de ciudad';

  @override
  String get selectionActionCancelAutoExplore => 'Cancelar exploración';

  @override
  String get selectionActionCancelArtifactExcavation =>
      'Cancelar excavación de artefacto';

  @override
  String get selectionActionCancelTradeRouteSelection =>
      'Cancelar selección de ruta comercial';

  @override
  String get selectionActionCancelMerchantMoveToCity =>
      'Cancelar viaje a la ciudad';

  @override
  String get selectionActionCancelCommanderMerge => 'Cancelar fusión de tropas';

  @override
  String get selectionActionConfirm => 'Confirmar';

  @override
  String selectionActionConfirmWithTurns(String turns) {
    return 'Confirmar ($turns)';
  }

  @override
  String get selectionActionMinimize => 'Minimizar';

  @override
  String get selectionActionConfirmAttack => 'Confirmar ataque';

  @override
  String get selectionActionCaptureCity => 'Capturar ciudad';

  @override
  String get selectionActionDestroyCity => 'Destruir ciudad';

  @override
  String get selectionActionStopFortifying => 'Dejar de fortificar';

  @override
  String get selectionActionStopHealing => 'Dejar de curarse';

  @override
  String get selectionActionMove => 'Mover';

  @override
  String get selectionActionAttack => 'Atacar';

  @override
  String get selectionActionAutoExplore => 'Explorar';

  @override
  String get selectionActionTradeRoute => 'Ruta comercial';

  @override
  String selectionActionTradeRouteToCity(String cityName) {
    return 'Comerciar con $cityName';
  }

  @override
  String get selectionActionMerchantMoveToCity => 'Ir a ciudad';

  @override
  String selectionActionMerchantMoveToCityTarget(String cityName) {
    return 'Ir a $cityName';
  }

  @override
  String get selectionActionArmy => 'Ejército';

  @override
  String get selectionArmyEmpty => 'Sin tropas';

  @override
  String selectionTroopDetachTooltip(String troop) {
    return 'Separar $troop';
  }

  @override
  String get selectionActionImprove => 'Mejorar';

  @override
  String get selectionActionSkip => 'Omitir';

  @override
  String get selectionActionFortify => 'Fortificar';

  @override
  String get selectionActionHeal => 'Curar';

  @override
  String get selectionActionCancelCityGrowth => 'Cancelar crecimiento';

  @override
  String get selectionActionCityGrowth => 'Crecimiento de ciudad';

  @override
  String get selectionActionProduction => 'Producción';

  @override
  String get selectionActionExcavateArtifact => 'Excavar';

  @override
  String get selectionActionStoreArtifact => 'Guardar';

  @override
  String get selectionActionCancelCurrentMoveFirst =>
      'Cancela primero el movimiento actual.';

  @override
  String get selectionActionArtifactAlreadyCarried =>
      'La unidad ya transporta un artefacto.';

  @override
  String get selectionActionStoreArtifactOwnCityRequired =>
      'Muévete a una de tus ciudades.';

  @override
  String get selectionActionStoreArtifactCityOccupied =>
      'Esta ciudad ya guarda un artefacto.';

  @override
  String get selectionActionNoBuildAvailable =>
      'No hay construcción disponible en esta casilla.';

  @override
  String get selectionActionUnitWorking => 'La unidad ya está trabajando.';

  @override
  String get selectionActionUnitFortified => 'La unidad está fortificada.';

  @override
  String get selectionActionUnitHealing => 'La unidad se está curando.';

  @override
  String get selectionActionNoMovement =>
      'No quedan puntos de movimiento este turno.';

  @override
  String get selectionActionNoAttack => 'Esta unidad no tiene ataque.';

  @override
  String get selectionActionNoVisibleEnemy =>
      'No hay enemigos visibles al alcance.';

  @override
  String get selectionActionMerchantNoOriginCity =>
      'Mueve el mercader a una de tus ciudades.';

  @override
  String get selectionActionMerchantNoDestinationCity =>
      'Necesitas otra ciudad conectada.';

  @override
  String get selectionActionMerchantNoRoute =>
      'Ninguna ruta comercial puede llegar a esta ciudad.';

  @override
  String get selectionActionMerchantNoCityPath =>
      'El mercader no puede llegar a esta ciudad.';

  @override
  String get selectionActionCannotFoundCityHere =>
      'No se puede fundar una ciudad aquí.';

  @override
  String get selectionActionFoundCityNoCommander =>
      'Solo un colono o un comandante con colonos puede fundar una ciudad.';

  @override
  String get selectionActionFoundCityNoSettlers =>
      'Se requieren colonos para fundar una ciudad.';

  @override
  String get selectionActionFoundCityInvalidCenter =>
      'No se puede fundar una ciudad en esta casilla.';

  @override
  String get selectionActionFoundCityCityAlreadyExists =>
      'Ya hay una ciudad en esta casilla.';

  @override
  String get selectionActionFoundCityCenterOccupied =>
      'Esta casilla ya pertenece a una ciudad.';

  @override
  String get selectionActionFoundCityTooCloseToCity =>
      'Una ciudad no puede estar adyacente a otra ciudad.';

  @override
  String get selectionActionFoundCityInvalidControlledHexes =>
      'Elige primero casillas de ciudad válidas.';

  @override
  String get selectionActionCannotImproveCityCenter =>
      'No se pueden construir mejoras en el centro de la ciudad.';

  @override
  String get selectionActionTileAlreadyImproved =>
      'Esta casilla ya tiene una mejora.';

  @override
  String get selectionActionTileMustBelongToCity =>
      'La casilla debe pertenecer a una ciudad.';

  @override
  String get selectionActionNoWorkerTile =>
      'No hay casilla bajo el trabajador.';

  @override
  String get hudFeedbackNoTurnCostDetail => 'La acción no consumió el turno';

  @override
  String get hudFeedbackAutoExploreNoTargetTitle => 'Sin ruta de exploración';

  @override
  String get hudFeedbackAutoExploreNoTargetBody =>
      'El explorador no tiene ningún movimiento que revele nuevas casillas este turno.';

  @override
  String get hudFeedbackArtifactGuidanceTitle => 'Artefacto mundial';

  @override
  String get hudFeedbackArtifactGuidanceBody =>
      'Entrégalo a una de tus ciudades y colócalo en un espacio de artefacto vacío.';

  @override
  String get hudFeedbackActionBlockedTitle => 'Acción no disponible';

  @override
  String get hudFeedbackActionBlockedBody =>
      'Esta acción está bloqueada ahora mismo. Elige otra casilla u otra orden.';

  @override
  String get hudFeedbackAttackProtectedByTreatyTitle =>
      'Un tratado bloquea el ataque';

  @override
  String get hudFeedbackAttackProtectedByTreatyBody =>
      'No puedes atacar una unidad de una civilización con la que tienes una alianza o una tregua. Cambia primero las relaciones diplomáticas.';

  @override
  String get hudFeedbackMovementCityOccupiedTitle => 'Ciudad ocupada';

  @override
  String get hudFeedbackMovementCityOccupiedBody =>
      'Solo una unidad puede estar en una ciudad. Saca primero la guarnición o elige otra casilla.';

  @override
  String get hudFeedbackMovementEnemyOccupiedTitle => 'Enemigo en esta casilla';

  @override
  String get hudFeedbackMovementEnemyOccupiedBody =>
      'No puedes entrar en una casilla enemiga con un movimiento normal. Usa Atacar o elige una casilla adyacente.';

  @override
  String get hudFeedbackMovementForeignCityTitle => 'Ciudad extranjera';

  @override
  String get hudFeedbackMovementForeignCityBody =>
      'No puedes entrar en una ciudad extranjera con un movimiento normal. Usa Atacar o elige otra casilla.';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarTitle =>
      'Ruta demasiado lejana';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarBody =>
      'No puedes trazar una ruta tan larga por terreno no descubierto. Elige un tramo más corto o usa la autoexploración del explorador.';

  @override
  String get hudFeedbackMovementBlockedTerrainTitle =>
      'El terreno bloquea el movimiento';

  @override
  String get hudFeedbackMovementBlockedTerrainBody =>
      'Esta unidad no puede entrar en ese tipo de terreno. Elige otra casilla o una ruta alrededor.';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementTitle =>
      'Movimiento insuficiente';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementBody =>
      'Esta unidad no tiene suficiente movimiento para entrar en esa zona. Mejórala o usa otra unidad.';

  @override
  String get hudFeedbackMovementNoRouteTitle => 'Sin ruta';

  @override
  String get hudFeedbackMovementNoRouteBody =>
      'No hay ruta disponible hacia esa casilla. Prueba con un objetivo más cercano u otro enfoque.';

  @override
  String selectionCommandUnavailableDescription(String label) {
    return 'La acción \"$label\" no está disponible para la selección actual.';
  }

  @override
  String selectionCommandActiveDescription(String label) {
    return 'La acción \"$label\" es un modo activo. Elige un objetivo en el mapa o cancela el modo si cambiaste de opinión.';
  }

  @override
  String selectionCommandProminentDescription(String label) {
    return 'La acción \"$label\" es actualmente la orden más importante para esta selección.';
  }

  @override
  String selectionCommandDefaultDescription(String label) {
    return 'Ejecuta la acción \"$label\" para la unidad, ciudad o casilla seleccionada actualmente.';
  }

  @override
  String get selectionInfoChipDisabledDescription =>
      'Este panel de información no está disponible para la selección actual.';

  @override
  String selectionInfoChipOpenDescription(String label) {
    return 'Abre los detalles de \"$label\" para la casilla, unidad o ciudad seleccionada actualmente.';
  }

  @override
  String turnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos',
      one: '1 turno',
      zero: '0 turnos',
    );
    return '$_temp0';
  }

  @override
  String turnPillLabel(int turn) {
    return 'T$turn';
  }

  @override
  String get turnEtaNoProgress => 'sin progreso';

  @override
  String turnEtaDetailLabel(String turnsLabel, int turn) {
    return '$turnsLabel • turno $turn';
  }

  @override
  String turnEtaTooltipNoTurn(String turnsLabel) {
    return '$turnsLabel para completar';
  }

  @override
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn) {
    return '$turnsLabel para completar • turno previsto $turn';
  }

  @override
  String get modeBannerWorkedTilesTitle => 'Casillas trabajadas';

  @override
  String get modeBannerWorkedTilesInstruction =>
      'Toca casillas controladas para alternar el trabajo de la ciudad.';

  @override
  String get modeBannerCityGrowthTitle => 'Crecimiento de ciudad';

  @override
  String get modeBannerCityGrowthInstructionSelected =>
      'La casilla seleccionada será reclamada en el próximo crecimiento de ciudad. Confírmala o elige otra casilla.';

  @override
  String get modeBannerCityGrowthInstructionEmpty =>
      'Toca una casilla delineada para elegir el siguiente hexágono de crecimiento. Sin elección, la ciudad usará su recomendación.';

  @override
  String get modeBannerWorkerActionTitle => 'Mejora de casilla';

  @override
  String get modeBannerWorkerActionInstructionPicked =>
      'Confirma la mejora en la ventana del trabajador.';

  @override
  String get modeBannerWorkerActionInstructionEmpty =>
      'Elige un tipo de mejora en la ventana del trabajador.';

  @override
  String get modeBannerMerchantTradeRouteTitle => 'Ruta comercial';

  @override
  String get modeBannerMerchantTradeRouteInstruction =>
      'Elige una de tus ciudades. El mercader viajará automáticamente hasta allí y volverá al llegar.';

  @override
  String get modeBannerMerchantMoveToCityTitle => 'Ir a ciudad';

  @override
  String get modeBannerMerchantMoveToCityInstruction =>
      'Elige una de tus ciudades. El mercader trazará una ruta hasta su centro sin crear una ruta comercial.';

  @override
  String workerActionSelectedImprovement(String title) {
    return 'Seleccionada: $title';
  }

  @override
  String get workerActionSelectImprovement => 'Elegir mejora';

  @override
  String get workerActionBuildDetailTitle => 'Mejora de casilla';

  @override
  String workerActionBuildImprovement(String title) {
    return 'Construir $title';
  }

  @override
  String get workerActionSelectionHint =>
      'Haz clic en una mejora para esta casilla, inspecciona los rendimientos y confirma la construcción.';

  @override
  String get workerActionNoYieldChange => 'sin cambio de rendimiento';

  @override
  String get modeBannerResearchSelectionTitle => 'Elegir investigación';

  @override
  String get modeBannerResearchSelectionInstruction =>
      'Abre el árbol tecnológico y elige un objetivo de investigación para continuar el turno.';

  @override
  String get modeBannerUnitTurnSkipTitle => 'Turno omitido';

  @override
  String get modeBannerUnitTurnSkipInstruction =>
      'La unidad espera hasta el siguiente turno. Su estado es visible en la barra inferior.';

  @override
  String get modeBannerCommanderMergeTitle => 'Fusionar tropas';

  @override
  String get modeBannerCommanderMergeInstruction =>
      'Selecciona una unidad aliada para que el comandante la añada al ejército.';

  @override
  String get modeBannerAttackTargetingTitle => 'Ataque';

  @override
  String get modeBannerAttackTargetingInstructionSelected =>
      'Comprueba la previsión de combate en la ventana y confirma el ataque.';

  @override
  String get modeBannerAttackTargetingInstructionEmpty =>
      'Selecciona un enemigo al alcance o su hexágono para ver la previsión de combate.';

  @override
  String get modeBannerAttackRetreatProgress => 'Retirada';

  @override
  String get modeBannerActionToolbarHint =>
      'Usa la barra inferior para las acciones cuando las necesites.';

  @override
  String get combatPreviewConfirmBody =>
      'La unidad seleccionada atacará inmediatamente tras la confirmación.';

  @override
  String get combatPreviewOutcomeLabel => 'Resultado';

  @override
  String get combatPreviewTargetLabel => 'Objetivo';

  @override
  String get combatPreviewRetaliationLabel => 'Contraataque';

  @override
  String get combatPreviewStrengthLabel => 'Fuerza';

  @override
  String get combatPreviewAttackerRole => 'Atacante';

  @override
  String get combatPreviewDefenderRole => 'Defensor';

  @override
  String get combatPreviewCityRole => 'Ciudad';

  @override
  String combatPreviewOutcomeLine(String outcome) {
    return 'Resultado: $outcome';
  }

  @override
  String get combatPreviewOutcomeCityFalls => 'la ciudad cae';

  @override
  String get combatPreviewOutcomeDefenderKilled => 'el defensor muere';

  @override
  String get combatPreviewOutcomeAttackerKilled =>
      'el atacante muere en el contraataque';

  @override
  String get combatPreviewOutcomeDefenderRetreated => 'el defensor se retirará';

  @override
  String get combatPreviewOutcomeCitySurvives => 'la ciudad sobrevive';

  @override
  String get combatPreviewOutcomeDefenderSurvives => 'el defensor sobrevive';

  @override
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Objetivo: PV $hpBefore->$hpAfter/$hpMax, Ataque $attack vs Defensa $defense (-$damage)';
  }

  @override
  String combatPreviewNoRetaliationLine(int distance, int range) {
    return 'Contraataque: ninguno (ataque a distancia, distancia $distance, alcance $range)';
  }

  @override
  String combatPreviewRetaliationLine(
    int attack,
    int defense,
    int damage,
    int hpBefore,
    int hpAfter,
    int hpMax,
  ) {
    return 'Contraataque: Ataque $attack vs Defensa $defense (-$damage), PV $hpBefore->$hpAfter/$hpMax';
  }

  @override
  String combatPreviewHpDamageValue(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int damage,
  ) {
    return '$hpBefore → $hpAfter/$hpMax PV, -$damage';
  }

  @override
  String get combatPreviewForecastTitle => 'Previsión de combate';

  @override
  String get combatPreviewNoHpLoss => 'sin daño';

  @override
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss) {
    return '$hpAfter de $hpMax PV tras el combate, $loss PV perdidos';
  }

  @override
  String combatPreviewStrengthValue(int attack, int defense) {
    return '$attack ataque vs $defense defensa';
  }

  @override
  String get combatPreviewAdvantageTitle => '¿Por qué esta previsión?';

  @override
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Ventaja del atacante: $country tiene $attack de ataque contra $defense de defensa; el objetivo pierde unos $damage PV.';
  }

  @override
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Ventaja defensiva: $country tiene $defense de defensa contra $attack de ataque; el golpe inflige unos $damage PV.';
  }

  @override
  String combatPreviewAdvantageEven(int attack, int defense, int damage) {
    return 'Combate igualado: $attack de ataque contra $defense de defensa; el daño previsto es de unos $damage PV.';
  }

  @override
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  ) {
    return 'Posiciones: $attackerCountry ataca desde $attackerTerrain. $defenderCountry defiende en $defenderTerrain.';
  }

  @override
  String combatPreviewSourcesLine(String sources) {
    return 'La ventaja proviene de: $sources.';
  }

  @override
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  ) {
    return 'Ayuda al ataque ($attackerCountry): $sources.';
  }

  @override
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  ) {
    return 'Ayuda a la defensa ($defenderCountry): $sources.';
  }

  @override
  String get combatPreviewNoSourcesLine =>
      'No se aplican modificadores: las estadísticas base de la unidad y el resultado de combate deciden esta previsión.';

  @override
  String combatPreviewNoRetaliationReason(int distance, int range) {
    return 'Sin contraataque: este es un ataque a distancia (distancia $distance, alcance de ataque $range).';
  }

  @override
  String get combatPreviewNoRetaliationDefenderDefeated =>
      'Sin contraataque: el objetivo es derrotado antes de poder responder.';

  @override
  String get combatPreviewNoRetaliationDefenderRetreats =>
      'Sin contraataque: el objetivo se retira tras el golpe.';

  @override
  String get combatPreviewNoRetaliationNoAttack =>
      'Sin contraataque: el objetivo no tiene fuerza de ataque en esta previsión.';

  @override
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  ) {
    return 'Contraataque: $defenderCountry responde y $attackerCountry pierde unos $damage PV.';
  }

  @override
  String get combatPreviewSourceAttackTerrain => 'terreno del atacante';

  @override
  String get combatPreviewSourceDefenseTerrain => 'terreno del defensor';

  @override
  String get combatPreviewSourceTechnology => 'tecnología';

  @override
  String get combatPreviewSourceVeterancy => 'experiencia';

  @override
  String get combatPreviewSourceCityGarrison => 'guarnición de ciudad';

  @override
  String get combatPreviewSourceMixedArmy => 'composición de unidades';

  @override
  String get combatCounterSpearmanVsMountedAttack =>
      'lanceros contra unidades montadas';

  @override
  String get combatCounterSpearmanVsMountedDefense =>
      'lanceros resisten a unidades montadas';

  @override
  String get combatCounterArcherDefensiveTerrainDefense =>
      'arqueros en terreno defensivo';

  @override
  String get combatCounterCavalryRoughAttack =>
      'caballería frenada por terreno difícil';

  @override
  String get combatCounterCavalryOpenRaid =>
      'incursión de caballería en terreno abierto';

  @override
  String get combatCounterHeavyInfantryBreakthrough =>
      'infantería pesada rompe la línea';

  @override
  String get terrainOcean => 'océano';

  @override
  String get terrainCoast => 'costa';

  @override
  String get terrainLake => 'lago';

  @override
  String get terrainPlains => 'llanuras';

  @override
  String get terrainGrassland => 'pradera';

  @override
  String get terrainDesert => 'desierto';

  @override
  String get terrainTundra => 'tundra';

  @override
  String get terrainSnow => 'nieve';

  @override
  String get terrainMountain => 'montañas';

  @override
  String get terrainHills => 'colinas';

  @override
  String get terrainWetlands => 'humedales';

  @override
  String get terrainJungle => 'jungla';

  @override
  String get terrainForest => 'bosque';

  @override
  String get terrainRiver => 'río';

  @override
  String get modeBannerMoveTargetingTitle => 'Modo de movimiento';

  @override
  String get modeBannerMoveTargetingInstruction =>
      'El primer toque en un hexágono traza la ruta. Toca de nuevo el mismo hexágono para moverte; una ruta más larga se pone en cola para turnos futuros.';

  @override
  String get modeBannerMoveTargetingCancelAction => 'Salir de movimiento';

  @override
  String get modeBannerWorkerFindTileTitle => 'Trabajador: buscar una casilla';

  @override
  String modeBannerWorkerFindTileInstruction(String reason) {
    return '$reason Mueve el trabajador a una de tus casillas de ciudad sin mejora, o a terreno que coincida con una construcción desbloqueada.';
  }

  @override
  String get modeBannerWorkerFindTileDetailOwnCity =>
      'Casilla de ciudad propia';

  @override
  String get modeBannerWorkerFindTileDetailNoImprovement => 'Sin mejora';

  @override
  String get modeBannerWorkerFindTileDetailMatchingTerrain =>
      'Terreno compatible';

  @override
  String get modeBannerWorkerImproveTileTitle => 'Trabajador: mejorar casilla';

  @override
  String get modeBannerWorkerImproveTileInstruction =>
      'Esta casilla se puede mejorar. Si quieres actuar, usa la barra inferior, elige la mejor construcción y confírmala en el panel inferior.';

  @override
  String get modeBannerWorkerImproveTileDetailYields =>
      'Aumenta rendimientos de la casilla';

  @override
  String get modeBannerWorkerImproveTileDetailMovement => 'Usa movimiento';

  @override
  String get modeBannerScoutExploreTitle => 'Explorador: explorar';

  @override
  String get modeBannerScoutExploreInstruction =>
      'Activa la exploración desde la barra inferior para que el explorador descubra automáticamente las casillas desconocidas más cercanas. Puedes cancelarla después desde las acciones de unidad.';

  @override
  String get modeBannerScoutExploreDetailAuto => 'Autoexploración';

  @override
  String get modeBannerScoutExploreDetailReveal => 'Revela el mapa';

  @override
  String get modeBannerSettlerFindSiteTitle => 'Colono: buscar un sitio';

  @override
  String modeBannerSettlerFindSiteInstruction(String reason) {
    return '$reason Mueve el colono a una casilla libre fuera de las fronteras de ciudad; evita agua, montañas y centros ocupados.';
  }

  @override
  String get modeBannerSettlerFindSiteDetailFreeHex => 'Hexágono libre';

  @override
  String get modeBannerSettlerFindSiteDetailOutsideBorders =>
      'Fuera de fronteras';

  @override
  String get modeBannerSettlerFindSiteDetailLandOrCoast => 'Tierra o costa';

  @override
  String get modeBannerSettlerFoundCityTitle => 'Colono: fundar ciudad';

  @override
  String get modeBannerSettlerFoundCityInstruction =>
      'Esta casilla puede convertirse en ciudad. Si quieres fundarla, usa la barra inferior y luego elige las casillas iniciales de la ciudad en el mapa.';

  @override
  String get modeBannerSettlerFoundCityDetailNewCity => 'Nueva ciudad';

  @override
  String get modeBannerSettlerFoundCityDetailChooseTiles =>
      'Elige casillas tras tocar';

  @override
  String get modeBannerCityFoundingTitle => 'Fundar una ciudad';

  @override
  String get modeBannerCityFoundingInstructionReady =>
      'Listo. Confirma la fundación de la ciudad en la barra inferior o cambia las casillas seleccionadas en el mapa.';

  @override
  String modeBannerCityFoundingInstructionPick(int count) {
    return 'Elige $count casillas conectadas alrededor del colono. Tras elegirlas, la acción de fundar ciudad estará disponible en la barra inferior.';
  }

  @override
  String get selectionImprovementListTitle => 'Mejoras de casilla';

  @override
  String get mapInspectionPossibleImprovementsTitle => 'Mejoras posibles';

  @override
  String get mapInspectionNoPossibleImprovements => 'No hay mejoras posibles';

  @override
  String get mapInspectionImprovementAvailableFromStart => 'desde el inicio';

  @override
  String get mapInspectionObjectiveTitle => 'Objetivo del mapa';

  @override
  String get mapObjectiveRuins => 'Ruinas';

  @override
  String get mapObjectiveStrategicPass => 'Paso estratégico';

  @override
  String get mapObjectiveHolySite => 'Lugar sagrado';

  @override
  String get mapObjectiveLegendaryResource => 'Yacimiento legendario';

  @override
  String get mapObjectiveRuinsDescription =>
      'Un punto neutral de exploración. Mantenerlo suma presión de victoria.';

  @override
  String get mapObjectiveStrategicPassDescription =>
      'Un paso clave del terreno. Controlarlo convierte el movimiento en ventaja.';

  @override
  String get mapObjectiveHolySiteDescription =>
      'Un lugar de importancia cultural. Controlarlo otorga oro y puntos de victoria.';

  @override
  String get mapObjectiveLegendaryResourceDescription =>
      'Un yacimiento raro que merece expansión o conflicto. Controlarlo da la mayor recompensa.';

  @override
  String mapObjectiveStatusNeutral(int turns) {
    return 'Mantén $turns turnos';
  }

  @override
  String mapObjectiveStatusHolding(int held, int required) {
    return 'Manteniendo $held/$required';
  }

  @override
  String mapObjectiveStatusCompleted(int held, int required) {
    return 'Controlado $held/$required';
  }

  @override
  String get mapObjectiveStatusContested => 'Disputado';

  @override
  String mapObjectiveRewardVictoryPoints(int points) {
    return '+$points PV';
  }

  @override
  String mapObjectiveRewardGoldPerTurn(int gold) {
    return '+$gold oro/turno';
  }

  @override
  String get selectionImprovementStateBuilt => 'CONSTRUIDA';

  @override
  String get selectionImprovementStateAvailable => 'DISPONIBLE';

  @override
  String get selectionImprovementStateNeedsTechnology => 'TEC.';

  @override
  String get selectionImprovementStateNeedsCity => 'CIUDAD';

  @override
  String get selectionImprovementStateBlocked => 'LÍMITE';

  @override
  String get selectionImprovementNoBonus => 'Sin bonificación';

  @override
  String workerImprovementYieldFood(int value) {
    return '+$value alimento';
  }

  @override
  String workerImprovementYieldProduction(int value) {
    return '+$value producción';
  }

  @override
  String workerImprovementYieldGold(int value) {
    return '+$value oro';
  }

  @override
  String workerImprovementYieldDefense(int value) {
    return '+$value defensa';
  }

  @override
  String get workerImprovementNoBonus => 'Sin bonificación extra.';

  @override
  String get workerImprovementOnlyWorker =>
      'Solo un trabajador puede construir esto.';

  @override
  String get workerImprovementWorkerBusy =>
      'El trabajador ya está construyendo.';

  @override
  String get workerImprovementStopQueuedMove =>
      'Detén primero el movimiento planificado.';

  @override
  String get workerImprovementMissingTile => 'No hay casilla bajo la unidad.';

  @override
  String get workerImprovementMissingResource =>
      'Esta mejora requiere un recurso compatible.';

  @override
  String get workerImprovementInvalidTerrain =>
      'Terreno base incorrecto para esta mejora.';

  @override
  String get workerImprovementMissingRiver => 'Esta mejora requiere un río.';

  @override
  String get workerImprovementBlocked => 'Esta acción está bloqueada ahora.';

  @override
  String unitSelectionWorkerJobTurns(String name, int turns) {
    return '$name (${turns}T)';
  }

  @override
  String get resourceValueNoMatchingImprovement => 'Sin mejora compatible';

  @override
  String get resourceValueSelectWorkerOrCity =>
      'Selecciona trabajador o ciudad';

  @override
  String get resourceValueTileAlreadyImproved =>
      'La casilla ya tiene una mejora';

  @override
  String get resourceValueCityCenter => 'Centro de ciudad';

  @override
  String resourceValueWorksForCity(String city) {
    return 'Trabaja para: $city';
  }

  @override
  String get resourceValueOutsideCityBorders =>
      'Fuera de las fronteras de ciudad';

  @override
  String get resourceValueNoLegalImprovementForTile =>
      'No hay mejora legal para esta casilla';

  @override
  String resourceValueRequiresTechnology(String technology) {
    return 'Requiere: $technology';
  }

  @override
  String get resourceValueAvailableForWorker => 'Disponible para trabajador';

  @override
  String get resourceDetailNoResourcesOnTile =>
      'No hay recursos en esta casilla';

  @override
  String get resourceDetailValueSection => 'Valor';

  @override
  String get resourceDetailCurrentSection => 'Ahora';

  @override
  String get resourceDetailAfterImprovementSection => 'Tras la mejora';

  @override
  String get resourceDetailYieldComparison => 'Rendimientos de casilla';

  @override
  String get resourceDetailRequiresSection => 'Requiere';

  @override
  String get resourceDetailBestMoveSection => 'Mejor movimiento';

  @override
  String get resourceDetailNoMatchingImprovementBody =>
      'No hay mejora compatible para este recurso.';

  @override
  String get resourceDetailRequirementNoneCanBuild =>
      'Nada. Puedes construir inmediatamente.';

  @override
  String get resourceDetailRequirementOutsideCity =>
      'La casilla debe estar dentro de las fronteras de ciudad.';

  @override
  String get resourceDetailRequirementAlreadyImproved =>
      'Nada. La casilla ya está mejorada.';

  @override
  String get resourceDetailRequirementCityCenter =>
      'No hay construcción de trabajador en el centro de la ciudad.';

  @override
  String get resourceDetailRequirementSelectWorkerOrCity =>
      'Una selección de trabajador o ciudad.';

  @override
  String get resourceDetailRequirementNoLegalImprovement =>
      'No hay construcción disponible para esta casilla.';

  @override
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  ) {
    return 'Desbloquea primero $technology y luego construye $improvement.';
  }

  @override
  String resourceDetailBestMoveAvailable(String improvement) {
    return 'Envía un trabajador y construye $improvement.';
  }

  @override
  String get resourceDetailBestMoveOutsideCity =>
      'Expande las fronteras de la ciudad o funda una ciudad más cerca del recurso.';

  @override
  String get resourceDetailBestMoveAlreadyImproved =>
      'Mantén la casilla dentro de fronteras y trabájala cuando encaje con el plan de ciudad.';

  @override
  String get resourceDetailBestMoveCityCenter =>
      'Trata el recurso como valor del centro urbano; los trabajadores no mejoran esta casilla.';

  @override
  String get resourceDetailBestMoveSelectWorkerOrCity =>
      'Selecciona un trabajador o una ciudad para comprobar la construcción legal.';

  @override
  String get resourceDetailBestMoveNoLegalImprovement =>
      'Trata el recurso como objetivo de expansión; aquí no hay construcción separada.';

  @override
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  ) {
    return 'Desbloqueado por $technology: $improvement.';
  }

  @override
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  ) {
    return 'Después de $technology: $improvement desbloquea el rendimiento completo de la casilla.';
  }

  @override
  String resourceValueResearchBoostLine(String technology, String discount) {
    return 'Impulso de investigación: controlar este recurso acelera $technology (-$discount coste).';
  }

  @override
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  ) {
    return 'Después de $technology: +$production PROD por cada recurso controlado.';
  }

  @override
  String resourceValueNoBaseYieldSummary(String yield) {
    return 'El recurso en sí no añade rendimiento base. Todo el hexágono tiene ahora $yield; el valor completo viene de mejoras y desbloqueos.';
  }

  @override
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield) {
    return 'El recurso da $resourceYield. Todo el hexágono tiene ahora $tileYield antes de la mejora.';
  }

  @override
  String get resourceValueExpansionStrategic =>
      'Reclámalo antes que un rival: es un recurso estratégico para producción, ejércitos o tecnologías posteriores.';

  @override
  String get resourceValueExpansionFood =>
      'Un buen objetivo de expansión para el crecimiento urbano: más alimento significa población más rápida y más casillas trabajadas.';

  @override
  String get resourceValueExpansionProduction =>
      'Un buen objetivo de expansión para el ritmo de producción: edificios, unidades y presión de mapa llegan más rápido.';

  @override
  String get resourceValueExpansionTrade =>
      'Un buen objetivo de expansión para el comercio: tras la mejora apoya con fuerza el oro y el mantenimiento del crecimiento continuo.';

  @override
  String get resourceValueExpansionEconomy =>
      'Un buen objetivo de expansión para la economía: el oro ayuda a mantener ejércitos, acumular reservas y cerrar objetivos de puntuación.';

  @override
  String resourceValueYieldFood(int amount) {
    return '+$amount ALIMENTO';
  }

  @override
  String resourceValueYieldProduction(int amount) {
    return '+$amount PROD';
  }

  @override
  String resourceValueYieldGold(int amount) {
    return '+$amount ORO';
  }

  @override
  String resourceValueYieldDefense(int amount) {
    return '+$amount DEF';
  }

  @override
  String get resourceValueZeroBaseYield => '0 rendimiento base';

  @override
  String get resourceValueCategoryBonus => 'Bonificación';

  @override
  String get resourceValueCategoryLuxury => 'Lujo';

  @override
  String get resourceValueCategoryStrategic => 'Estratégico';

  @override
  String get resourceValueCategoryBonusFuture =>
      'El valor funciona casi de inmediato: crecimiento más rápido y mejor inicio de ciudad.';

  @override
  String get resourceValueCategoryLuxuryFuture =>
      'El mayor valor aparece tras reclamar la frontera y hacer la mejora adecuada.';

  @override
  String get resourceValueCategoryStrategicFuture =>
      'Este es un recurso estratégico: asegúralo para producción posterior y presión militar.';

  @override
  String get cityYieldBreakdownTitle => 'Economía de ciudad';

  @override
  String cityYieldBreakdownSubtitle(String growth, String eta) {
    return 'Rendimiento real/turno • crecimiento $growth • $eta';
  }

  @override
  String get cityYieldBreakdownProductionSources => 'Fuentes de producción';

  @override
  String get cityYieldBreakdownScienceSources => 'Fuentes de ciencia';

  @override
  String get cityYieldBreakdownPerTurnSuffix => '/turno';

  @override
  String get cityYieldBreakdownNoProduction => 'Sin producción';

  @override
  String get cityYieldBreakdownNoScience => 'Sin ciencia';

  @override
  String get cityYieldBreakdownCenter => 'Centro';

  @override
  String get cityYieldBreakdownPopulationFields => 'Casillas de población';

  @override
  String get cityYieldBreakdownWorkers => 'Trabajadores';

  @override
  String get cityYieldBreakdownBuildings => 'Edificios';

  @override
  String get cityYieldBreakdownTechnologies => 'Tecnologías';

  @override
  String get cityYieldBreakdownSpecialization => 'Especialización';

  @override
  String get cityYieldBreakdownGoldMultiplier => 'Multiplicador de oro';

  @override
  String get cityYieldBreakdownUpkeep => 'Mantenimiento';

  @override
  String get cityYieldBreakdownFieldsBucket => 'Casillas';

  @override
  String get cityYieldBreakdownCenterDetail =>
      'Rendimiento fijo del centro de la ciudad';

  @override
  String get cityYieldBreakdownGoldMultiplierDetail =>
      'Bonificación porcentual tras sumar fuentes de oro';

  @override
  String get cityYieldBreakdownBaseScience => 'Base de ciudad';

  @override
  String get cityYieldBreakdownBaseScienceDetail =>
      'Ciencia fija generada por cada ciudad';

  @override
  String get cityYieldBreakdownResearchProject => 'Proyecto de investigación';

  @override
  String get cityYieldBreakdownResearchProjectDetail =>
      'Producción actual de la ciudad convertida en ciencia';

  @override
  String get cityYieldBreakdownScienceSpecializationDetail =>
      'Perfil científico de ciudad';

  @override
  String get cityYieldBreakdownScienceTechnologyDetail =>
      'Bonificación de ciencia de tecnologías desbloqueadas';

  @override
  String get cityYieldBreakdownNoWorkedPopulationFields =>
      'Sin casillas de población trabajadas';

  @override
  String get cityYieldBreakdownOneWorkedPopulationField =>
      '1 casilla de población trabajada';

  @override
  String cityYieldBreakdownManyWorkedPopulationFields(int count) {
    return '$count casillas de población trabajadas';
  }

  @override
  String get cityYieldBreakdownNoAssignedWorkers =>
      'Sin trabajadores asignados';

  @override
  String get cityYieldBreakdownOneAssignedWorker =>
      '1 casilla activada por un trabajador';

  @override
  String cityYieldBreakdownManyAssignedWorkers(int count) {
    return '$count casillas activadas por trabajadores';
  }

  @override
  String get cityYieldBreakdownNoPassiveImprovements => 'Sin mejoras pasivas';

  @override
  String get cityYieldBreakdownOnePassiveImprovement =>
      '1 mejora sin trabajar, medio rendimiento';

  @override
  String cityYieldBreakdownManyPassiveImprovements(int count) {
    return '$count mejoras sin trabajar, medio rendimiento';
  }

  @override
  String get cityYieldBreakdownNoBuildings => 'Sin edificios';

  @override
  String get cityYieldBreakdownBuildingsNoDirectYield =>
      'Edificios sin rendimiento directo';

  @override
  String get cityYieldBreakdownOneBuildingEconomicEffect =>
      '1 edificio con efecto económico';

  @override
  String cityYieldBreakdownManyBuildingEconomicEffects(int count) {
    return '$count edificios con efectos económicos';
  }

  @override
  String get cityYieldBreakdownNoTechnologyYield =>
      'Sin bonificación de rendimiento tecnológico';

  @override
  String get cityYieldBreakdownTechnologyYield =>
      'Bonificaciones de tecnologías desbloqueadas';

  @override
  String get cityYieldBreakdownNoScienceBuildings =>
      'Sin edificios científicos';

  @override
  String get cityYieldBreakdownOneScienceBuilding => '1 edificio científico';

  @override
  String cityYieldBreakdownManyScienceBuildings(int count) {
    return '$count edificios científicos con rendimientos decrecientes';
  }

  @override
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost) {
    return '$storedFood/$growthCost alimento';
  }

  @override
  String get cityYieldBreakdownStagnation => 'estancamiento';

  @override
  String cityYieldBreakdownUpkeepBlocked(int population, int cost) {
    return 'Población $population: coste $cost, crecimiento detenido';
  }

  @override
  String cityYieldBreakdownUpkeepCost(int population) {
    return 'Mantenimiento de alimento para población $population';
  }

  @override
  String get cityYieldBreakdownGrowthSpecializationDetail =>
      'Perfil de crecimiento de ciudad';

  @override
  String get cityYieldBreakdownIndustrySpecializationDetail =>
      'Perfil industrial de ciudad';

  @override
  String get cityYieldBreakdownCommerceSpecializationDetail =>
      'Perfil comercial de ciudad';

  @override
  String get cityYieldBreakdownScienceSpecializationCityDetail =>
      'Perfil científico de ciudad';

  @override
  String get cityYieldBreakdownMilitarySpecializationDetail =>
      'Perfil de guarnición de ciudad';

  @override
  String get cityYieldBreakdownNoSpecialization => 'Sin especialización';

  @override
  String get cityProjectWealth => 'Riqueza';

  @override
  String get cityProjectResearch => 'Investigación';

  @override
  String get cityProductionProjectsSection => 'Proyectos de ciudad';

  @override
  String get cityProductionSpecializationSection => 'Especialización de ciudad';

  @override
  String get cityProductionSortLabel => 'Ordenar';

  @override
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  ) {
    return '$title • $productionPerTurn • $gold oro';
  }

  @override
  String get cityProductionBuiltLabel => 'Construido';

  @override
  String get cityProductionAvailableLabel => 'Disponible';

  @override
  String get cityProductionAvailableUnitLabel => 'Disponible';

  @override
  String cityProductionUnitSupplyLimit(int used, int capacity) {
    return 'Límite de alimento $used/$capacity';
  }

  @override
  String cityProductionUnitSupplyCost(int cost) {
    return 'alimento $cost';
  }

  @override
  String cityProductionUnitSupplyUsed(int used, int capacity) {
    return 'límite $used/$capacity';
  }

  @override
  String cityProductionNextWorkerUpkeep(int upkeep) {
    return 'siguiente mantenimiento: $upkeep';
  }

  @override
  String cityProductionCostShort(int production) {
    return '$production prod.';
  }

  @override
  String cityProductionPaceShort(int production) {
    return '$production prod./turno';
  }

  @override
  String get cityBuildingSortRecommended => 'Recomendado';

  @override
  String cityBuildingReplaceProgressWarning(String building) {
    return 'Elegir otro edificio reemplazará $building. El progreso se conservará.';
  }

  @override
  String get cityBuildingSortFastestImpact => 'Impacto más rápido';

  @override
  String get cityBuildingSortBestReturn => 'Mejor retorno';

  @override
  String get cityBuildingSortGrowth => 'Crecimiento';

  @override
  String get cityBuildingSortIndustry => 'Industria';

  @override
  String get cityBuildingSortScience => 'Ciencia';

  @override
  String get cityBuildingSortDefenseMilitary => 'Defensa / militar';

  @override
  String get cityBuildingSortEconomy => 'Economía';

  @override
  String get cityBuildingRequiresTechnology => 'Requiere tecnología';

  @override
  String get cityProductionContinuous => 'continuo';

  @override
  String get cityProductionNoProduction => 'sin producción';

  @override
  String get cityProductionReady => 'listo';

  @override
  String get cityProductionTurnOne => '1 turno';

  @override
  String cityProductionTurns(int turns) {
    return '$turns turnos';
  }

  @override
  String cityProductionTreasuryGold(int gold) {
    return 'Tesorería: $gold oro';
  }

  @override
  String cityProductionRushAction(int gold) {
    return 'Acelerar -$gold';
  }

  @override
  String cityProjectGoldPerTurn(int gold) {
    return '+$gold oro / turno';
  }

  @override
  String cityProjectSciencePerTurn(int science) {
    return '+$science ciencia / turno';
  }

  @override
  String get citySpecializationGrowth => 'Crecimiento';

  @override
  String get citySpecializationIndustry => 'Industria';

  @override
  String get citySpecializationCommerce => 'Comercio';

  @override
  String get citySpecializationMilitary => 'Guarnición';

  @override
  String get citySpecializationGrowthBonus => '+2 alimento';

  @override
  String get citySpecializationIndustryBonus => '+2 producción';

  @override
  String get citySpecializationCommerceBonus => '+3 oro';

  @override
  String get citySpecializationScienceBonus => '+2 ciencia';

  @override
  String get citySpecializationMilitaryProductionBonus => '+1 producción';

  @override
  String get citySpecializationMilitaryDefenseBonus => '+2 defensa';

  @override
  String get citySpecializationMilitaryUnitProductionBonus =>
      '+1 prod. de unidad';

  @override
  String get citySpecializationBestFit => 'Mejor encaje';

  @override
  String get eventCityFoundedTitle => 'Ciudad fundada';

  @override
  String get eventCityBuiltBuildingTitle => 'Construcción completada';

  @override
  String get eventCityProducedUnitTitle => 'Unidad entrenada';

  @override
  String get eventCityClaimedHexTitle => 'Fronteras de ciudad';

  @override
  String eventCityClaimedHexBody(String cityName) {
    return '$cityName: nueva casilla';
  }

  @override
  String get eventUnitMovedTitle => 'Movimiento de unidad';

  @override
  String get eventUnitPromotedTitle => 'Unidad ascendida';

  @override
  String get eventUnitExperienceTitle => 'Experiencia';

  @override
  String eventUnitExperienceBody(String unitName, int amount, String rank) {
    return '$unitName: +$amount XP ($rank)';
  }

  @override
  String get eventUnitAttackedTitle => 'Ataque';

  @override
  String get eventCombatTitle => 'Combate';

  @override
  String eventCombatDamageLine(String unitName, int damage, String result) {
    return '$unitName: -$damage PV -> $result';
  }

  @override
  String eventCombatNoRetaliationLine(String unitName) {
    return '$unitName: sin contraataque';
  }

  @override
  String eventCombatSimpleBody(
    String attackerCountry,
    String attackerName,
    String defenderCountry,
    String defenderName,
    int attackerHp,
    int defenderHp,
  ) {
    return '$attackerName ($attackerCountry) atacó a $defenderName ($defenderCountry) - PV $attackerHp:$defenderHp';
  }

  @override
  String get eventDiplomaticProposalAcceptedStatus => 'Aceptada';

  @override
  String get eventDiplomaticProposalRejectedStatus => 'Rechazada';

  @override
  String get eventDiplomaticProposalExpiredStatus => 'Caducada';

  @override
  String get eventUnitKilledTitle => 'Unidad derrotada';

  @override
  String get eventUnitRetreatedTitle => 'Retirada';

  @override
  String get eventCityCapturedTitle => 'Ciudad capturada';

  @override
  String get eventCityDestroyedTitle => 'Ciudad destruida';

  @override
  String get eventTurnEndedTitle => 'Turno terminado';

  @override
  String get eventWorkerCompletedJobTitle => 'Trabajo completado';

  @override
  String get eventResearchPointsTitle => 'Ciencia';

  @override
  String eventResearchPointsBody(String playerName, int points) {
    return '$playerName: +$points ciencia';
  }

  @override
  String get eventTechnologyResearchedTitle => 'Tecnología descubierta';

  @override
  String get eventStrategicResourceDiscoveredTitle =>
      'Recurso estratégico descubierto';

  @override
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  ) {
    return '$playerName: $resourceName';
  }

  @override
  String eventStrategicResourceControlledDetail(int count) {
    return 'Controlados: $count';
  }

  @override
  String eventStrategicResourceRivalDetail(int count) {
    return 'Rivales: $count';
  }

  @override
  String eventStrategicResourceUnclaimedDetail(int count) {
    return 'Sin reclamar: $count';
  }

  @override
  String get eventStrategicResourcePressureSecured =>
      'Suministro asegurado; defiende la fuente.';

  @override
  String get eventStrategicResourcePressureExpansionRace =>
      'Carrera de asentamiento: reclama el depósito cercano antes que tus rivales.';

  @override
  String get eventStrategicResourcePressureContested =>
      'Suministro disputado: los rivales también controlan fuentes.';

  @override
  String get eventStrategicResourcePressureRivalMonopoly =>
      'Monopolio rival: prepara comercio o una expedición.';

  @override
  String eventStrategicResourceSettleHint(int col, int row) {
    return 'Depósito fuera de las fronteras en $col:$row; conviene fundar una ciudad.';
  }

  @override
  String get eventMapObjectiveSecuredTitle => 'Objetivo del mapa asegurado';

  @override
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName) {
    return '$playerName: $objectiveName';
  }

  @override
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns) {
    return 'Mantenido: $holdTurns/$requiredHoldTurns';
  }

  @override
  String eventMapObjectiveLocationDetail(int col, int row) {
    return 'Posición: $col:$row';
  }

  @override
  String eventMapObjectiveVictoryRewardDetail(int points) {
    return '+$points puntos de victoria';
  }

  @override
  String eventMapObjectiveGoldRewardDetail(int gold) {
    return '+$gold oro/turno';
  }

  @override
  String get eventCivilizationMetTitle => 'Nueva civilización';

  @override
  String eventCivilizationMetBody(String civilizationName, String playerName) {
    return '$civilizationName ($playerName)';
  }

  @override
  String get civilizationMetPopupEyebrow => 'Civilización encontrada';

  @override
  String civilizationMetPopupBody(String civilizationName) {
    return 'La civilización de $civilizationName ha aparecido en el horizonte. Un nuevo vecino, rival o futuro aliado forma ahora parte de tu mundo.';
  }

  @override
  String get civilizationMetPopupOk => 'OK';

  @override
  String get eventCommandRejectedTitle => 'Comando rechazado';

  @override
  String get eventAllPlayersSubmittedTitle => 'Todos listos';

  @override
  String eventAllPlayersSubmittedBody(int turn, int players) {
    return 'Turno $turn ($players)';
  }

  @override
  String get eventPlayerTimedOutTitle => 'Envío automático';

  @override
  String eventPlayerTimedOutBody(String playerName, int turn) {
    return '$playerName: tiempo agotado en el turno $turn';
  }

  @override
  String get eventCombatDefenderKilledDetail => 'Defensor derrotado';

  @override
  String get eventCombatAttackerKilledDetail => 'Atacante derrotado';

  @override
  String get eventCombatDefenderRetreatedDetail => 'Defensor retirado';

  @override
  String eventCombatAttackDamageDetail(int damage) {
    return 'Ataque: -$damage PV';
  }

  @override
  String eventCombatRetaliationDamageDetail(int damage) {
    return 'Contraataque: -$damage PV';
  }

  @override
  String eventCombatRollDetail(int value) {
    return 'Tirada $value';
  }

  @override
  String get eventCombatNoRetaliationDetail => 'Sin contraataque';

  @override
  String get eventDominationStartedTitle => 'Dominación iniciada';

  @override
  String get eventDominationRivalAboveTitle => 'Rival por encima del umbral';

  @override
  String eventDominationBody(
    String playerName,
    String control,
    String required,
  ) {
    return '$playerName: $control% / $required%';
  }

  @override
  String eventDominationHoldProgressDetail(int held, int required) {
    return 'Mantenido $held/$required turnos';
  }

  @override
  String get eventDominationReadyDetail => 'Condición lista';

  @override
  String eventDominationKeepHoldingDetail(String turns) {
    return 'Mantener durante $turns más';
  }

  @override
  String eventDominationInterruptDetail(String turns) {
    return 'Interrumpir en $turns';
  }

  @override
  String eventTurnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos',
      one: '1 turno',
      zero: '0 turnos',
    );
    return '$_temp0';
  }

  @override
  String get eventCombatDefeatedResult => 'derrotado';

  @override
  String eventCombatDefenderRetreatedResult(int hp) {
    return '$hp PV, retirada';
  }

  @override
  String eventCombatHpResult(int hp) {
    return '$hp PV';
  }

  @override
  String eventCombatTerrainModifierLabel(Object terrain) {
    return 'Terreno $terrain';
  }

  @override
  String eventCombatTechModifierLabel(Object technology) {
    return 'Tecnología $technology';
  }

  @override
  String eventCombatRankModifierLabel(Object rank) {
    return 'Rango $rank';
  }

  @override
  String get eventCombatCityGarrisonModifier => 'Guarnición de ciudad';

  @override
  String get eventCombatMixedArmyModifier => 'Ejército mixto';

  @override
  String get eventCombatStatAttack => 'ataque';

  @override
  String get eventCombatStatDefense => 'defensa';

  @override
  String get eventCombatStatHp => 'PV';

  @override
  String get eventCombatStatRange => 'alcance';

  @override
  String get eventCombatStatMobility => 'movimiento';

  @override
  String get closeAction => 'Cerrar';
}
