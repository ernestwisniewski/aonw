(() => {
  'use strict';

  const HEX_COLUMNS = 28;
  const HEX_ROWS = 17;
  const HEX_RADIUS = 38;
  const HEX_HEIGHT = Math.sqrt(3) * HEX_RADIUS;
  const MAP_MARGIN = 72;
  const MAP_WIDTH = MAP_MARGIN * 2 + HEX_RADIUS * 2 + (HEX_COLUMNS - 1) * HEX_RADIUS * 1.5;
  const MAP_HEIGHT = MAP_MARGIN * 2 + HEX_HEIGHT * (HEX_ROWS + 0.5);

  const SCREENS = [
    { id: 'main-menu', label: 'Main menu', icon: '⌂' },
    { id: 'new-game', label: 'New game', icon: '✦' },
    { id: 'map', label: 'Game map', icon: '⬡' },
    { id: 'settings', label: 'Settings', icon: '⚙' },
    { id: 'help', label: 'Help', icon: '?' },
    { id: 'onboarding', label: 'Onboarding', icon: '◎' },
    { id: 'multiplayer-auth', label: 'Multiplayer · sign in', icon: '⇄' },
    { id: 'multiplayer-lobby', label: 'Multiplayer · lobby', icon: '☷' },
    { id: 'multiplayer-match', label: 'Multiplayer · match', icon: '◉' },
    { id: 'replay', label: 'Replay', icon: '▶' }
  ];

  const MODALS = [
    { id: 'none', label: '— bez modala —', icon: '·' },
    { id: 'city', label: 'City overview', icon: '♜' },
    { id: 'production', label: 'City production', icon: '⚒' },
    { id: 'research', label: 'Technology tree', icon: '⚗' },
    { id: 'diplomacy', label: 'Diplomacy', icon: '⚑' },
    { id: 'unit', label: 'Unit details', icon: '♞' },
    { id: 'army', label: 'Army management', icon: '♟' },
    { id: 'worker', label: 'Worker improvements', icon: '⛏' },
    { id: 'combat', label: 'Combat preview', icon: '⚔' },
    { id: 'objectives', label: 'Objectives & victory', icon: '★' },
    { id: 'artifact', label: 'World artifact', icon: '◆' },
    { id: 'logistics', label: 'Resources & logistics', icon: '⇢' },
    { id: 'event', label: 'World event', icon: '☀' },
    { id: 'pause', label: 'Pause menu', icon: 'Ⅱ' },
    { id: 'save', label: 'Save game', icon: '▣' },
    { id: 'load', label: 'Load game', icon: '▤' },
    { id: 'end-turn', label: 'Confirm end turn', icon: '✓' },
    { id: 'tech-unlocked', label: 'Technology unlocked', icon: '✧' },
    { id: 'city-founded', label: 'City founded', icon: '⚐' },
    { id: 'turn-processing', label: 'AI turn processing', icon: '◌' },
    { id: 'declare-war', label: 'Declare war', icon: '!' },
    { id: 'developer', label: 'Map diagnostics', icon: '⌘' }
  ];

  const NATIONS = [
    { id: 'poland', name: 'Poland', color: '#5a84bd', colorSoft: '#88add7', flag: 'linear-gradient(#f5f4ef 0 50%, #c8454a 50%)', names: ['Kraków', 'Gdańsk', 'Poznań', 'Lublin', 'Toruń'] },
    { id: 'japan', name: 'Japan', color: '#c75955', colorSoft: '#df8b82', flag: 'radial-gradient(circle, #c8454a 0 31%, #f3f0e8 33%)', names: ['Kyoto', 'Osaka', 'Nara', 'Sapporo', 'Kobe'] },
    { id: 'netherlands', name: 'Netherlands', color: '#d38a42', colorSoft: '#e5b074', flag: 'linear-gradient(#ae3434 0 33%, #eee 33% 66%, #315f99 66%)', names: ['Amsterdam', 'Utrecht', 'Leiden', 'Delft', 'Breda'] },
    { id: 'egypt', name: 'Egypt', color: '#c4ab4c', colorSoft: '#dfcb7a', flag: 'linear-gradient(#b23c36 0 33%, #eee 33% 66%, #27221c 66%)', names: ['Memphis', 'Thebes', 'Alexandria', 'Abydos', 'Giza'] },
    { id: 'norway', name: 'Norway', color: '#4d9a91', colorSoft: '#7fc1b7', flag: 'linear-gradient(90deg, transparent 0 26%, #eee 26% 36%, #254f92 36% 43%, #eee 43% 53%, transparent 53%),linear-gradient(#b23a3d 0 43%, #eee 43% 54%, #254f92 54% 61%, #eee 61% 72%, #b23a3d 72%)', names: ['Oslo', 'Bergen', 'Trondheim', 'Stavanger', 'Tromsø'] },
    { id: 'persia', name: 'Persia', color: '#8f66ae', colorSoft: '#b191ca', flag: 'linear-gradient(#3f9b66 0 33%, #eee 33% 66%, #c84e4e 66%)', names: ['Persepolis', 'Susa', 'Pasargadae', 'Ecbatana', 'Sardis'] }
  ];

  const UNIT_TYPES = [
    { id: 'scout', name: 'Scout', symbol: '♞', domain: 'land', attack: 9, defense: 7, movement: 4 },
    { id: 'warrior', name: 'Warrior', symbol: '⚔', domain: 'land', attack: 13, defense: 12, movement: 3 },
    { id: 'archer', name: 'Archer', symbol: '➹', domain: 'land', attack: 15, defense: 8, movement: 3 },
    { id: 'worker', name: 'Worker', symbol: '⛏', domain: 'land', attack: 0, defense: 5, movement: 3 },
    { id: 'cavalry', name: 'Cavalry', symbol: '♘', domain: 'land', attack: 18, defense: 11, movement: 5 },
    { id: 'galley', name: 'Galley', symbol: '◭', domain: 'naval', attack: 11, defense: 10, movement: 5 }
  ];

  const CITY_SITES = [
    [4, 4], [5, 12], [9, 8], [12, 3], [14, 13], [18, 7], [21, 12], [24, 4], [25, 14], [16, 4], [8, 14], [22, 8]
  ];

  const TERRAIN_COST = {
    ocean: Infinity,
    coast: 2,
    plains: 1,
    grassland: 1,
    forest: 2,
    hills: 2,
    desert: 2,
    tundra: 2,
    swamp: 3,
    mountain: Infinity
  };

  const TERRAIN_LABELS = {
    ocean: 'Ocean', coast: 'Coast', plains: 'Plains', grassland: 'Grassland', forest: 'Forest', hills: 'Hills', desert: 'Desert', tundra: 'Tundra', swamp: 'Marsh', mountain: 'Mountains'
  };

  const TERRAIN_SYMBOLS = {
    forest: '♣', hills: '⌁', mountain: '▲', desert: '·', tundra: '✧', swamp: '≈', coast: '∿'
  };

  const RESOURCE_SYMBOLS = ['♨', '◆', '♜', '●', '✦', '♞'];
  const RESOURCE_NAMES = ['Iron', 'Horses', 'Coal', 'Oil', 'Uranium', 'Spices'];

  const state = {
    screen: 'map',
    modal: 'none',
    viewport: 'desktop',
    worldSeed: 41721,
    world: null,
    selectedUnitId: null,
    selectedCityId: null,
    selectedHexKey: null,
    route: [],
    zoom: 0.79,
    panX: 8,
    panY: 8,
    fogEnabled: true,
    resourcesEnabled: true,
    territoryEnabled: true,
    reducedMotion: false,
    highContrast: false,
    onboardingStep: 0,
    replayPlaying: false,
    replaySpeed: 1,
    replayPosition: 42,
    chromeHidden: false,
    toastTimer: null
  };

  const refs = {};

  document.addEventListener('DOMContentLoaded', initialize);

  function initialize() {
    refs.workbench = document.getElementById('workbench');
    refs.viewportShell = document.getElementById('viewport-shell');
    refs.gameRoot = document.getElementById('game-root');
    refs.screenSelect = document.getElementById('screen-select');
    refs.modalSelect = document.getElementById('modal-select');
    refs.screenRail = document.getElementById('screen-rail');
    refs.modalRail = document.getElementById('modal-rail');
    refs.statusScreen = document.getElementById('status-screen');
    refs.statusWorld = document.getElementById('status-world');
    refs.toast = document.getElementById('toast');
    refs.restoreChrome = document.getElementById('restore-chrome');

    refs.screenSelect.innerHTML = SCREENS.map((item) => `<option value="${item.id}">${item.label}</option>`).join('');
    refs.modalSelect.innerHTML = MODALS.map((item) => `<option value="${item.id}">${item.label}</option>`).join('');
    refs.screenRail.innerHTML = SCREENS.map((item) => railButton(item, 'screen')).join('');
    refs.modalRail.innerHTML = MODALS.filter((item) => item.id !== 'none').map((item) => railButton(item, 'modal')).join('');

    refs.screenSelect.addEventListener('change', (event) => setScreen(event.target.value));
    refs.modalSelect.addEventListener('change', (event) => openModal(event.target.value));
    document.getElementById('regenerate-world').addEventListener('click', regenerateWorld);
    document.getElementById('toggle-grid').addEventListener('click', toggleGrid);
    document.getElementById('hide-chrome').addEventListener('click', toggleChrome);
    refs.restoreChrome.addEventListener('click', toggleChrome);
    document.querySelectorAll('[data-viewport]').forEach((button) => button.addEventListener('click', () => setViewport(button.dataset.viewport)));
    refs.screenRail.addEventListener('click', handleRailClick);
    refs.modalRail.addEventListener('click', handleRailClick);
    refs.gameRoot.addEventListener('click', handleGameClick);
    document.addEventListener('keydown', handleKeyboard);

    state.world = generateWorld(state.worldSeed);
    const firstHuman = state.world.units.find((unit) => unit.nationId === state.world.playerNationId && unit.domain === 'land');
    state.selectedUnitId = firstHuman?.id ?? null;
    state.selectedCityId = state.world.cities.find((city) => city.nationId === state.world.playerNationId)?.id ?? null;
    state.selectedHexKey = firstHuman ? hexKey(firstHuman.q, firstHuman.r) : null;
    render();
  }

  function railButton(item, kind) {
    return `<button type="button" class="rail-link" data-${kind}="${item.id}"><span class="rail-icon">${item.icon}</span><span>${item.label}</span></button>`;
  }

  function handleRailClick(event) {
    const screenButton = event.target.closest('[data-screen]');
    const modalButton = event.target.closest('[data-modal]');
    if (screenButton) setScreen(screenButton.dataset.screen);
    if (modalButton) openModal(modalButton.dataset.modal);
  }

  function setScreen(screenId) {
    if (!SCREENS.some((screen) => screen.id === screenId)) return;
    state.screen = screenId;
    if (!['map', 'replay'].includes(screenId)) state.modal = 'none';
    render();
  }

  function openModal(modalId) {
    if (!MODALS.some((modal) => modal.id === modalId)) return;
    state.modal = modalId;
    if (modalId !== 'none' && !['map', 'replay'].includes(state.screen)) state.screen = 'map';
    render();
  }

  function closeModal() {
    state.modal = 'none';
    render();
  }

  function setViewport(viewport) {
    state.viewport = viewport;
    refs.viewportShell.dataset.viewport = viewport;
    document.querySelectorAll('[data-viewport]').forEach((button) => button.classList.toggle('is-active', button.dataset.viewport === viewport));
    showToast(`Viewport: ${viewport}`);
  }

  function toggleGrid() {
    const enabled = refs.viewportShell.classList.toggle('has-grid');
    const button = document.getElementById('toggle-grid');
    button.classList.toggle('is-active', enabled);
    button.setAttribute('aria-pressed', String(enabled));
  }

  function toggleChrome() {
    state.chromeHidden = !state.chromeHidden;
    refs.workbench.style.display = state.chromeHidden ? 'contents' : '';
    if (state.chromeHidden) {
      document.querySelector('.designer-bar').style.display = 'none';
      document.querySelector('.designer-rail').style.display = 'none';
      document.querySelector('.designer-status').style.display = 'none';
      document.querySelector('.designer-stage').style.position = 'fixed';
      document.querySelector('.designer-stage').style.inset = '0';
      document.querySelector('.designer-stage').style.padding = '0';
      refs.viewportShell.style.width = '100vw';
      refs.viewportShell.style.height = '100dvh';
      refs.viewportShell.style.aspectRatio = 'auto';
      refs.restoreChrome.hidden = false;
    } else {
      document.querySelector('.designer-bar').style.display = '';
      document.querySelector('.designer-rail').style.display = '';
      document.querySelector('.designer-status').style.display = '';
      document.querySelector('.designer-stage').style.position = '';
      document.querySelector('.designer-stage').style.inset = '';
      document.querySelector('.designer-stage').style.padding = '';
      refs.viewportShell.style.width = '';
      refs.viewportShell.style.height = '';
      refs.viewportShell.style.aspectRatio = '';
      refs.restoreChrome.hidden = true;
    }
  }

  function handleKeyboard(event) {
    if (event.key === 'Escape' && state.modal !== 'none') closeModal();
    if (event.key.toLowerCase() === 'g' && !isTyping(event.target)) toggleGrid();
    if (event.key.toLowerCase() === 'h' && !isTyping(event.target)) toggleChrome();
  }

  function isTyping(target) {
    return ['INPUT', 'SELECT', 'TEXTAREA'].includes(target?.tagName);
  }

  function regenerateWorld() {
    state.worldSeed = (state.worldSeed + 7919) % 999983;
    state.world = generateWorld(state.worldSeed);
    const firstHuman = state.world.units.find((unit) => unit.nationId === state.world.playerNationId && unit.domain === 'land');
    state.selectedUnitId = firstHuman?.id ?? null;
    state.selectedCityId = state.world.cities.find((city) => city.nationId === state.world.playerNationId)?.id ?? null;
    state.selectedHexKey = firstHuman ? hexKey(firstHuman.q, firstHuman.r) : null;
    state.route = [];
    state.zoom = 0.79;
    state.panX = 8;
    state.panY = 8;
    render();
    showToast('Generated a new deterministic design world.');
  }

  function render() {
    refs.gameRoot.innerHTML = renderScreen(state.screen) + (state.modal !== 'none' ? renderModal(state.modal) : '');
    refs.screenSelect.value = state.screen;
    refs.modalSelect.value = state.modal;
    refs.statusScreen.textContent = `Widok: ${screenLabel(state.screen)}${state.modal !== 'none' ? ` / ${modalLabel(state.modal)}` : ''}`;
    refs.statusWorld.textContent = `Świat: seed ${state.worldSeed} · ${state.world.hexes.length} heksów · ${state.world.cities.length} miast · ${state.world.units.length} jednostek`;
    document.querySelectorAll('[data-screen]').forEach((button) => button.classList.toggle('is-active', button.dataset.screen === state.screen));
    document.querySelectorAll('[data-modal]').forEach((button) => button.classList.toggle('is-active', button.dataset.modal === state.modal));
    bindRenderedControls();
  }

  function renderScreen(screenId) {
    switch (screenId) {
      case 'main-menu': return renderMainMenu();
      case 'new-game': return renderNewGame();
      case 'settings': return renderSettings();
      case 'help': return renderHelp();
      case 'onboarding': return renderOnboarding();
      case 'multiplayer-auth': return renderMultiplayerAuth();
      case 'multiplayer-lobby': return renderMultiplayerLobby();
      case 'multiplayer-match': return renderMultiplayerMatch();
      case 'replay': return renderReplay();
      case 'map':
      default: return renderMapScreen(false);
    }
  }

  function screenClasses(extra = '') {
    return `game-screen ${extra} ${state.highContrast ? 'high-contrast' : ''} ${state.reducedMotion ? 'reduced-motion' : ''}`;
  }

  function renderMainMenu() {
    return `
      <section class="${screenClasses('menu-screen')}" aria-label="Main menu">
        <div class="menu-layout">
          <div class="menu-copy">
            <div class="game-kicker">A turn-based 4X strategy game</div>
            <h1 class="game-title game-title-xl">Age of<br>New Worlds</h1>
            <div class="menu-logo-line"></div>
            <p class="game-subtitle">Explore. Settle. Research. Command.<br>Shape a civilization across the ages.</p>
          </div>
          <div class="menu-panel aonw-panel">
            <div class="aonw-panel-content">
              <div class="game-kicker" style="text-align:center;margin-bottom:8px">Main menu</div>
              <div class="game-button-stack">
                <button class="game-button" data-action="continue"><span class="button-icon">↶</span>Continue</button>
                <button class="game-button secondary" data-screen="new-game"><span class="button-icon">＋</span>New Game</button>
                <button class="game-button secondary" data-screen="multiplayer-auth"><span class="button-icon">◎</span>Multiplayer</button>
                <button class="game-button secondary" data-screen="replay"><span class="button-icon">▶</span>Replay</button>
                <button class="game-button ghost" data-screen="help"><span class="button-icon">?</span>Help</button>
                <button class="game-button ghost" data-screen="settings"><span class="button-icon">⚙</span>Settings</button>
              </div>
              <div class="menu-version">v1.1 · HTML parity workbench</div>
            </div>
          </div>
        </div>
      </section>`;
  }

  function renderNewGame() {
    return appScaffold('New Game', `
      <div class="form-panel aonw-panel">
        <div class="aonw-panel-content">
          <div class="game-kicker">Local match setup</div>
          <h1 class="game-title game-title-lg" style="margin:4px 0 20px">Found a new world</h1>
          <div class="form-grid">
            ${selectField('Scenario', [['starter', 'A New World'], ['islands', 'Broken Archipelago'], ['frontier', 'The Great Frontier']], 'starter', 'wide')}
            ${selectField('Your country', NATIONS.map((nation) => [nation.id, nation.name]), 'poland')}
            ${selectField('AI country', NATIONS.map((nation) => [nation.id, nation.name]), 'japan')}
            ${selectField('AI difficulty', [['easy', 'Easy'], ['normal', 'Normal'], ['hard', 'Hard']], 'normal')}
            ${selectField('AI persona', [['balanced', 'Balanced'], ['expansionist', 'Expansionist'], ['aggressive', 'Aggressive'], ['scientific', 'Scientific']], 'balanced')}
            <div class="wide game-checkbox">
              <span><strong>Fog of war</strong><br><small class="game-muted">Hide unexplored terrain and enemy activity.</small></span>
              <button type="button" class="game-switch ${state.fogEnabled ? 'is-on' : ''}" data-action="toggle-fog" aria-label="Toggle fog of war"></button>
            </div>
            <div class="wide game-button-row" style="justify-content:flex-end;margin-top:8px">
              <button class="game-button ghost" data-screen="main-menu">Cancel</button>
              <button class="game-button gold" data-action="start-game">▶ Start Game</button>
            </div>
          </div>
        </div>
      </div>`);
  }

  function renderSettings() {
    return appScaffold('Settings', `
      <div class="settings-layout">
        <section class="aonw-panel settings-section">
          <h3>Audio</h3>
          <div class="settings-line"><label class="game-label">Master volume · <b id="volume-copy">80%</b><input class="game-slider" id="volume-slider" type="range" min="0" max="100" value="80"></label></div>
        </section>
        <section class="aonw-panel settings-section">
          <h3>Camera</h3>
          <div class="settings-line"><label class="game-label">Camera sensitivity · <b id="sensitivity-copy">1.0×</b><input class="game-slider" id="sensitivity-slider" type="range" min="50" max="200" step="25" value="100"></label></div>
        </section>
        <section class="aonw-panel settings-section">
          <h3>Accessibility</h3>
          ${switchRow('Reduced motion', 'Disables map, menu and modal transitions.', state.reducedMotion, 'toggle-reduced-motion')}
          ${switchRow('High contrast', 'Raises foreground contrast without changing layout.', state.highContrast, 'toggle-high-contrast')}
        </section>
        <button class="game-button secondary" data-action="reset-settings">↶ Reset Settings</button>
      </div>`);
  }

  function renderHelp() {
    return appScaffold('Help', `
      <div class="help-layout aonw-panel">
        <div class="aonw-panel-content">
          <p class="game-subtitle" style="margin:0 0 12px">Build an empire one deliberate turn at a time. Every action remains visible and reversible until the turn is submitted.</p>
          ${helpSection('⚑', 'Objective', 'Explore the map, establish cities, develop technology and outscore or overcome rival civilizations.')}
          ${helpSection('⬡', 'Map', 'Drag to inspect the world. Select a unit and then a valid destination to preview its route and movement cost.')}
          ${helpSection('⚒', 'Development', 'Cities work nearby tiles, build improvements and produce units, buildings and wonders from a queue.')}
          ${helpSection('◷', 'Turns', 'Resolve unit and city decisions, then end the turn. AI players process in sequence before control returns.')}
          ${helpSection('▣', 'Saves and replays', 'Local saves preserve the match. Replays rebuild deterministic turns using the same authoritative data.')}
          <button class="game-button" style="width:100%;margin-top:16px" data-screen="onboarding">◎ Start Onboarding</button>
        </div>
      </div>`);
  }

  function renderOnboarding() {
    const steps = [
      ['⌖', 'Explore the world', 'Move scouts into the unknown. Terrain, resources and rival borders are revealed as visibility expands.'],
      ['⚔', 'Command your units', 'Select a unit, inspect its actions, then choose a destination or target. The white route is a movement preview.'],
      ['♜', 'Develop your cities', 'Assign production, improve nearby tiles and connect settlements with roads and trade.'],
      ['↶', 'Continue every turn', 'Finish required decisions, submit the turn and watch deterministic AI actions resolve.']
    ];
    const step = steps[state.onboardingStep];
    return appScaffold('Onboarding', `
      <div class="onboarding-card aonw-panel">
        <div class="aonw-panel-content">
          <div class="game-progress"><span style="width:${((state.onboardingStep + 1) / steps.length) * 100}%"></span></div>
          <div class="onboarding-icon">${step[0]}</div>
          <div class="game-kicker">Step ${state.onboardingStep + 1} of ${steps.length}</div>
          <h2 class="game-title game-title-lg" style="margin:8px 0 10px">${step[1]}</h2>
          <p class="game-subtitle">${step[2]}</p>
          <div class="onboarding-dots">${steps.map((_, index) => `<span class="${index === state.onboardingStep ? 'is-active' : ''}"></span>`).join('')}</div>
          <div class="game-button-row">
            <button class="game-button secondary" style="flex:1" data-action="onboarding-prev" ${state.onboardingStep === 0 ? 'disabled' : ''}>Previous</button>
            <button class="game-button" style="flex:1" data-action="onboarding-next">${state.onboardingStep === steps.length - 1 ? 'Finish' : 'Next'}</button>
          </div>
        </div>
      </div>`, '<button class="game-button ghost" data-screen="main-menu">Skip</button>');
  }

  function renderMultiplayerAuth() {
    return appScaffold('Multiplayer', `
      <div class="auth-panel aonw-panel">
        <div class="aonw-panel-content">
          <div class="game-kicker">Account</div>
          <h2 class="game-title game-title-lg" style="margin:5px 0 18px">Sign in</h2>
          <div class="game-button-stack">
            <label class="game-label">Email<input class="game-input" type="email" value="explorer@example.com"></label>
            <label class="game-label">Password<input class="game-input" type="password" value="long-password"></label>
            <button class="game-button" data-screen="multiplayer-lobby">Sign In</button>
            <button class="game-button ghost" data-action="create-account">Create New Account</button>
          </div>
        </div>
      </div>`);
  }

  function renderMultiplayerLobby() {
    return appScaffold('Multiplayer', `
      <div class="lobby-layout">
        <section class="aonw-panel">
          <div class="aonw-panel-content">
            <div class="game-kicker">Lobby</div>
            <h2 class="game-title game-title-md" style="margin:5px 0">Welcome, Explorer</h2>
            <p class="game-muted" style="font-size:11px;margin:0 0 16px">Signed in as player-aonw-27</p>
            <button class="game-button" style="width:100%" data-action="create-match">＋ Create Match</button>
            <div class="aonw-divider"></div>
            <label class="game-label">Match ID<input class="game-input" value="AONW-9Q7K"></label>
            <label class="game-label" style="margin-top:10px">Player seat<select class="game-select"><option>Player 2</option><option>Player 1</option><option>Player 3</option><option>Player 4</option></select></label>
            <button class="game-button secondary" style="width:100%;margin-top:12px" data-screen="multiplayer-match">⇥ Join Match</button>
            <div class="game-button-row" style="margin-top:12px"><button class="game-button ghost" style="flex:1">↻ Refresh</button><button class="game-button ghost" style="flex:1" data-screen="multiplayer-auth">Sign Out</button></div>
          </div>
        </section>
        <section class="aonw-panel">
          <div class="aonw-panel-content">
            <div class="game-kicker">Your matches</div>
            <div class="match-list">
              ${matchRow('A New World', 'Turn 31 · waiting for Player 3', 'AONW-9Q7K')}
              ${matchRow('Broken Archipelago', 'Turn 12 · your turn', 'AONW-F4M2')}
              ${matchRow('The Great Frontier', 'Turn 4 · 3/4 submitted', 'AONW-XP8C')}
            </div>
          </div>
        </section>
      </div>`);
  }

  function renderMultiplayerMatch() {
    return appScaffold('Multiplayer Match', `
      <div class="form-panel aonw-panel">
        <div class="aonw-panel-content">
          <div class="game-kicker">Network session · ready</div>
          <h2 class="game-title game-title-lg" style="margin:5px 0 14px">A New World</h2>
          <div class="stat-grid">
            ${stat('31', 'Turn')}${stat('2 / 4', 'Submitted')}${stat('18', 'Visible units')}${stat('42 ms', 'Latency')}
          </div>
          <div class="aonw-divider"></div>
          <div class="list-stack">
            ${playerRow('You · Poland', 'Submitted', '#5a84bd')}
            ${playerRow('Akira · Japan', 'Planning', '#c75955')}
            ${playerRow('Sanne · Netherlands', 'Submitted', '#d38a42')}
            ${playerRow('AI · Egypt', 'Resolved', '#c4ab4c')}
          </div>
          <div class="game-button-row" style="justify-content:flex-end;margin-top:18px">
            <button class="game-button ghost" data-screen="multiplayer-lobby">Back to Lobby</button>
            <button class="game-button" data-action="submit-turn">✓ Submit Turn</button>
          </div>
        </div>
      </div>`);
  }

  function renderReplay() {
    return `
      <section class="${screenClasses('map-screen')}" aria-label="Replay">
        ${renderMapStage(true)}
        <div class="replay-top aonw-panel aonw-panel-flat">
          <button class="game-button icon-only ghost" data-screen="main-menu" aria-label="Back">←</button>
          <strong style="font-family:Georgia,serif;color:#f2e8cd">Replay · Turn 27</strong>
        </div>
        <div class="replay-controls aonw-panel aonw-panel-flat">
          <button class="game-button icon-only" data-action="replay-toggle">${state.replayPlaying ? 'Ⅱ' : '▶'}</button>
          <input class="replay-timeline" id="replay-slider" type="range" min="0" max="120" value="${state.replayPosition}">
          <span class="replay-progress-copy" style="font-size:11px;color:#bbc6cc">${state.replayPosition} / 120</span>
          <button class="game-button secondary" data-action="replay-speed">${state.replaySpeed}×</button>
        </div>
      </section>`;
  }

  function appScaffold(title, content, actions = '') {
    return `
      <section class="${screenClasses('app-screen')}" aria-label="${title}">
        <header class="app-bar">
          <button class="game-button icon-only ghost" data-screen="main-menu" aria-label="Back">←</button>
          <h1 class="game-title game-title-md">${title}</h1>
          ${actions}
        </header>
        <div class="app-content">${content}</div>
      </section>`;
  }

  function renderMapScreen(readOnly) {
    return `
      <section class="${screenClasses('map-screen')}" aria-label="Game map">
        ${renderMapStage(readOnly)}
        ${renderMapHud(readOnly)}
      </section>`;
  }

  function renderMapStage(readOnly) {
    const world = state.world;
    const transform = `translate(${state.panX} ${state.panY}) scale(${state.zoom})`;
    const routePath = state.route.length > 1 ? smoothRoutePath(state.route.map((key) => world.hexByKey.get(key)).filter(Boolean).map((hex) => hexCenter(hex.q, hex.r))) : '';
    return `
      <div class="map-stage">
        <svg class="hex-map" id="hex-map" viewBox="0 0 ${MAP_WIDTH} ${MAP_HEIGHT}" aria-label="Interactive hex map" data-readonly="${readOnly}">
          <defs>
            <linearGradient id="oceanLight" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#4a86a0"/><stop offset="1" stop-color="#28566d"/></linearGradient>
            <filter id="cityGlow"><feGaussianBlur stdDeviation="4" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
          </defs>
          <g id="map-transform" transform="${transform}">
            ${world.hexes.map(renderHex).join('')}
            ${state.territoryEnabled ? world.hexes.filter((hex) => hex.ownerId).map(renderTerritory).join('') : ''}
            ${state.resourcesEnabled ? world.hexes.filter((hex) => hex.resource).map(renderResource).join('') : ''}
            ${state.fogEnabled ? world.hexes.filter((hex) => hex.fogged).map(renderFog).join('') : ''}
            ${routePath ? `<path class="route-shadow" d="${routePath}"></path><path class="route-line" d="${routePath}"></path>${state.route.map((key, index) => index === 0 || index === state.route.length - 1 ? renderRouteNode(world.hexByKey.get(key)) : '').join('')}` : ''}
            ${world.cities.map(renderCity).join('')}
            ${world.units.map(renderUnit).join('')}
          </g>
        </svg>
      </div>`;
  }

  function renderHex(hex) {
    const selected = state.selectedHexKey === hex.key ? 'is-selected' : '';
    const center = hexCenter(hex.q, hex.r);
    const symbol = TERRAIN_SYMBOLS[hex.terrain] ?? '';
    return `<g class="hex terrain-${hex.terrain} ${selected}" data-hex-key="${hex.key}" data-q="${hex.q}" data-r="${hex.r}">
      <polygon points="${hexPolygon(center.x, center.y)}"></polygon>
      ${symbol ? `<text class="terrain-pattern" x="${center.x}" y="${center.y + 2}">${symbol}</text>` : ''}
    </g>`;
  }

  function renderTerritory(hex) {
    const nation = nationById(hex.ownerId);
    if (!nation) return '';
    const center = hexCenter(hex.q, hex.r);
    return `<polygon class="territory-fill" points="${hexPolygon(center.x, center.y)}" fill="${nation.color}" stroke="${nation.colorSoft}" stroke-width="1.4"></polygon>`;
  }

  function renderResource(hex) {
    const center = hexCenter(hex.q, hex.r);
    return `<g title="${hex.resource.name}"><circle cx="${center.x + 18}" cy="${center.y + 19}" r="12" fill="rgba(3,16,24,.76)" stroke="rgba(244,221,150,.72)" stroke-width="1.2"></circle><text class="resource-marker" x="${center.x + 18}" y="${center.y + 20}">${hex.resource.symbol}</text></g>`;
  }

  function renderFog(hex) {
    const center = hexCenter(hex.q, hex.r);
    return `<polygon class="fog-tile" points="${hexPolygon(center.x, center.y)}"></polygon>`;
  }

  function renderCity(city) {
    const center = hexCenter(city.q, city.r);
    const nation = nationById(city.nationId);
    return `<g class="city-marker" data-city-id="${city.id}" transform="translate(${center.x} ${center.y - 4})">
      <circle class="city-core" r="21"></circle>
      <path class="city-roof" d="M-15 -4 L-8 -15 L-1 -8 L6 -19 L16 -4 Z"></path>
      <rect x="-13" y="-3" width="26" height="17" rx="2" fill="${nation.color}"></rect>
      <line class="city-banner" x1="14" y1="-13" x2="14" y2="-37"></line>
      <path d="M14 -36 L36 -29 L14 -22 Z" fill="${nation.colorSoft}" stroke="#f5e5b1" stroke-width="1"></path>
      <rect class="city-label-bg" x="-54" y="27" width="108" height="42" rx="7"></rect>
      <text class="city-name" y="45">${city.name}</text>
      <text class="city-meta" y="61">● ${city.population}   ⚒ ${city.production}</text>
    </g>`;
  }

  function renderUnit(unit) {
    const center = hexCenter(unit.q, unit.r);
    const nation = nationById(unit.nationId);
    const selected = state.selectedUnitId === unit.id ? 'is-selected' : '';
    return `<g class="unit-token ${selected}" data-unit-id="${unit.id}" transform="translate(${center.x + unit.offsetX} ${center.y + unit.offsetY})">
      <circle r="25" fill="${nation.color}"></circle>
      <text y="1">${unit.symbol}</text>
      <rect x="-14" y="25" width="28" height="14" rx="6" fill="rgba(2,14,22,.88)" stroke="${nation.colorSoft}" stroke-width="1"></rect>
      <text class="unit-ap" y="35">${unit.ap}/${unit.movement}</text>
    </g>`;
  }

  function renderRouteNode(hex) {
    if (!hex) return '';
    const center = hexCenter(hex.q, hex.r);
    return `<circle class="route-node" cx="${center.x}" cy="${center.y}" r="7"></circle>`;
  }

  function renderMapHud(readOnly) {
    const selectedUnit = state.world.units.find((unit) => unit.id === state.selectedUnitId);
    const selectedHex = state.world.hexByKey.get(state.selectedHexKey);
    const routeCost = pathCost(state.route, selectedUnit);
    const selectionTitle = selectedUnit ? `${selectedUnit.name} · ${nationById(selectedUnit.nationId).name}` : selectedHex ? TERRAIN_LABELS[selectedHex.terrain] : 'No selection';
    const selectionCopy = selectedUnit ? `${selectedUnit.ap}/${selectedUnit.movement} movement · ${selectedUnit.attack} attack · ${selectedUnit.defense} defense` : selectedHex ? `${selectedHex.q}, ${selectedHex.r}${selectedHex.resource ? ` · ${selectedHex.resource.name}` : ''}` : 'Select a unit or tile';
    if (readOnly) return '';
    return `
      <div class="map-topbar">
        <div class="resource-bar aonw-panel aonw-panel-flat">
          ${resourcePill('●', 'Gold', '284', '+18')}
          ${resourcePill('⚗', 'Science', '37', '+12')}
          ${resourcePill('♜', 'Culture', '21', '+7')}
          ${resourcePill('♨', 'Food', '16', '+5')}
          ${resourcePill('◆', 'Iron', '9', '+2')}
        </div>
        <div class="turn-panel aonw-panel aonw-panel-flat">
          <div class="turn-copy"><strong>Turn 31</strong><small>Classical Era · 560 BC</small></div>
          <button class="game-button gold" data-modal="end-turn">End Turn ✓</button>
        </div>
      </div>
      <div class="map-leftbar">
        ${hudButton('♜', 'Cities', 'city')}
        ${hudButton('⚒', 'Production', 'production')}
        ${hudButton('⚗', 'Research', 'research')}
        ${hudButton('⚑', 'Diplomacy', 'diplomacy')}
        ${hudButton('♟', 'Armies', 'army')}
        ${hudButton('★', 'Objectives', 'objectives')}
        ${hudButton('◆', 'Artifacts', 'artifact')}
        ${hudButton('⇢', 'Logistics', 'logistics')}
        ${hudButton('Ⅱ', 'Pause', 'pause')}
      </div>
      <div class="map-zoom">
        <button class="hud-button" data-action="zoom-in">＋<small>Zoom in</small></button>
        <button class="hud-button" data-action="zoom-out">−<small>Zoom out</small></button>
        <button class="hud-button" data-action="reset-camera">⌖<small>Reset camera</small></button>
        <button class="hud-button ${state.territoryEnabled ? 'is-active' : ''}" data-action="toggle-territory">◈<small>Territories</small></button>
        <button class="hud-button ${state.resourcesEnabled ? 'is-active' : ''}" data-action="toggle-resources">◆<small>Resources</small></button>
        <button class="hud-button ${state.fogEnabled ? 'is-active' : ''}" data-action="toggle-fog">☁<small>Fog of war</small></button>
      </div>
      <div class="map-minimap" aria-label="Minimap">
        <span class="minimap-land" style="left:8%;top:13%;width:37%;height:58%;background:#6c8b59"></span>
        <span class="minimap-land" style="right:7%;top:21%;width:42%;height:69%;background:#867f5d"></span>
        <span class="minimap-land" style="left:38%;top:57%;width:27%;height:26%;background:#789260"></span>
        ${NATIONS.slice(0,5).map((nation, index) => `<span style="position:absolute;width:8px;height:8px;border-radius:50%;background:${nation.color};left:${20 + index * 26}px;top:${26 + (index % 2) * 38}px"></span>`).join('')}
        <span class="minimap-camera"></span>
      </div>
      <div class="map-bottom">
        <div class="selection-panel aonw-panel aonw-panel-flat">
          <div class="game-icon-tile">${selectedUnit?.symbol ?? '⬡'}</div>
          <div style="min-width:0;flex:1"><h4>${selectionTitle}</h4><p>${selectionCopy}</p></div>
          ${selectedUnit ? '<button class="game-button icon-only ghost" data-modal="unit" aria-label="Unit details">›</button>' : ''}
        </div>
        <div class="action-bar aonw-panel aonw-panel-flat">
          ${actionButton('⌖', 'Move')}${actionButton('⚔', 'Attack', 'combat')}${actionButton('⛺', 'Fortify')}${actionButton('⛏', 'Improve', selectedUnit?.typeId === 'worker' ? 'worker' : null)}${actionButton('⇥', 'Join Army', 'army')}${actionButton('◷', 'Wait')}
        </div>
        <div class="route-cost aonw-panel aonw-panel-flat"><strong>${state.route.length > 1 ? `${routeCost} movement` : 'Route preview'}</strong><small>${state.route.length > 1 ? `${state.route.length - 1} tiles · click to confirm` : 'Select unit, then destination'}</small></div>
      </div>`;
  }

  function renderModal(modalId) {
    switch (modalId) {
      case 'city': return renderCityModal();
      case 'production': return renderProductionModal();
      case 'research': return renderResearchModal();
      case 'diplomacy': return renderDiplomacyModal();
      case 'unit': return renderUnitModal();
      case 'army': return renderArmyModal();
      case 'worker': return renderWorkerModal();
      case 'combat': return renderCombatModal();
      case 'objectives': return renderObjectivesModal();
      case 'artifact': return renderArtifactModal();
      case 'logistics': return renderLogisticsModal();
      case 'event': return renderEventModal();
      case 'pause': return renderPauseModal();
      case 'save': return renderSaveModal();
      case 'load': return renderLoadModal();
      case 'end-turn': return renderEndTurnModal();
      case 'tech-unlocked': return renderTechUnlockedModal();
      case 'city-founded': return renderCityFoundedModal();
      case 'turn-processing': return renderTurnProcessingModal();
      case 'declare-war': return renderDeclareWarModal();
      case 'developer': return renderDeveloperModal();
      default: return '';
    }
  }

  function modalShell({ id, icon, title, subtitle = '', size = '', body, footer = '' }) {
    return `<div class="modal-layer" data-modal-layer="${id}">
      <section class="modal-window ${size}" role="dialog" aria-modal="true" aria-labelledby="modal-title-${id}">
        <header class="modal-header"><div class="modal-emblem">${icon}</div><div class="modal-heading"><h2 id="modal-title-${id}">${title}</h2>${subtitle ? `<p>${subtitle}</p>` : ''}</div><button class="modal-close" data-action="close-modal" aria-label="Close">×</button></header>
        <div class="modal-body">${body}</div>
        ${footer ? `<footer class="modal-footer">${footer}</footer>` : ''}
      </section>
    </div>`;
  }

  function renderCityModal() {
    const city = selectedCity();
    const nation = nationById(city.nationId);
    return modalShell({
      id: 'city', icon: '♜', title: city.name, subtitle: `${nation.name} · Population ${city.population} · Loyalty 94%`, size: 'wide',
      body: `<div class="tab-row"><button class="tab is-active">Overview</button><button class="tab" data-modal="production">Production</button><button class="tab">Citizens</button><button class="tab">Buildings</button><button class="tab">Trade</button></div>
        <div class="stat-grid">${stat('+' + city.food, 'Food')}${stat('+' + city.production, 'Production')}${stat('+11', 'Gold')}${stat('+8', 'Science')}</div>
        <div class="modal-grid" style="margin-top:14px">
          <section class="modal-card"><h3>City development</h3><div class="list-stack">${listRow('♟', 'Population', `${city.population} citizens · growth in 4 turns`, '68%')}${listRow('⌂', 'Housing', '8 available / 7 used', '88%')}${listRow('☻', 'Amenities', 'Content · +5% yields', '74%')}</div></section>
          <section class="modal-card"><h3>Current production</h3>${listRow('⚒', 'Library', '3 turns remaining · 74 / 110', '67%')}<button class="game-button secondary" style="width:100%;margin-top:10px" data-modal="production">Change Production</button></section>
          <section class="modal-card"><h3>Worked territory</h3><p>7 tiles worked · 14 controlled · 2 improvements available.</p><div class="game-button-row" style="margin-top:10px"><span class="game-chip">🌾 12</span><span class="game-chip">⚒ 9</span><span class="game-chip">● 11</span><span class="game-chip">⚗ 8</span></div></section>
          <section class="modal-card"><h3>Buildings</h3><div class="game-button-row"><span class="game-chip">Monument</span><span class="game-chip">Granary</span><span class="game-chip">Barracks</span><span class="game-chip">Market</span></div><button class="game-button ghost" style="width:100%;margin-top:10px">Manage Buildings</button></section>
        </div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button><button class="game-button" data-modal="production">Open Production</button>`
    });
  }

  function renderProductionModal() {
    return modalShell({
      id: 'production', icon: '⚒', title: 'Kraków Production', subtitle: 'Choose the next item and arrange the city queue', size: 'wide',
      body: `<div class="production-layout">
        <section class="modal-card"><h3>Production queue</h3><div class="list-stack">
          ${queueRow('1', '▥', 'Library', '74 / 110 · 3 turns', '67%')}
          ${queueRow('2', '♞', 'Scout', '0 / 55 · 5 turns', '0%')}
          ${queueRow('3', '⌂', 'Granary', '0 / 85 · 7 turns', '0%')}
        </div><button class="game-button ghost" style="width:100%;margin-top:10px">＋ Add Queue Slot</button></section>
        <section class="modal-card"><div class="tab-row"><button class="tab is-active">All</button><button class="tab">Units</button><button class="tab">Buildings</button><button class="tab">Wonders</button></div><div class="catalog-grid">
          ${catalogItem('▥', 'Library', '+4 Science', '110', true)}${catalogItem('♞', 'Horseman', 'Fast mounted unit', '95')}${catalogItem('⌂', 'Granary', '+2 Food · +2 Housing', '85')}${catalogItem('⚒', 'Workshop', '+3 Production', '130')}${catalogItem('⚑', 'Walls', '+60 City Defense', '120')}${catalogItem('♜', 'Great Lighthouse', 'World Wonder', '310')}
        </div></section>
      </div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Cancel</button><button class="game-button">Confirm Queue</button>`
    });
  }

  function renderResearchModal() {
    return modalShell({
      id: 'research', icon: '⚗', title: 'Technology Research', subtitle: 'Classical Era · 37 science per turn', size: 'wide',
      body: `<div class="game-row" style="gap:10px;margin-bottom:12px"><span class="game-chip">Current: Engineering</span><div class="game-progress" style="flex:1"><span style="width:62%"></span></div><b style="color:#f0d88f">4 turns</b></div>
        <div class="research-board">
          <svg viewBox="0 0 830 470" preserveAspectRatio="none"><path class="tech-link" d="M120 92 C220 92 190 115 278 115 M120 92 C220 92 190 260 278 260 M410 115 C490 115 490 72 560 72 M410 115 C500 115 485 205 560 205 M410 260 C500 260 485 205 560 205 M410 260 C500 260 490 348 560 348 M692 72 C750 72 735 150 770 150 M692 205 C750 205 735 150 770 150 M692 348 C750 348 735 310 770 310"></path></svg>
          ${techNode(24, 54, 'Writing', 'researched', '✓', 'Libraries & records')}
          ${techNode(278, 77, 'Mathematics', 'researched', '✓', 'Siege calculations')}
          ${techNode(278, 222, 'Construction', 'current', '62%', 'Roads & engineering')}
          ${techNode(560, 34, 'Currency', '', '180', 'Markets & trade')}
          ${techNode(560, 167, 'Engineering', 'current', '240', 'Aqueducts & bridges')}
          ${techNode(560, 310, 'Iron Working', '', '210', 'Swords & ironworks')}
          ${techNode(710, 112, 'Guilds', 'locked', '320', 'Requires Currency')}
          ${techNode(710, 272, 'Machinery', 'locked', '360', 'Requires Engineering')}
        </div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button><button class="game-button">Set Research: Engineering</button>`
    });
  }

  function renderDiplomacyModal() {
    return modalShell({
      id: 'diplomacy', icon: '⚑', title: 'Diplomacy', subtitle: 'Foreign relations and agreements', size: 'wide',
      body: `<div class="diplomacy-grid">
        <div class="civ-list">${civRow(NATIONS[1], 'Neutral', true)}${civRow(NATIONS[2], 'Friendly')}${civRow(NATIONS[3], 'Guarded')}${civRow(NATIONS[4], 'Unknown')}</div>
        <div class="modal-card"><div class="modal-grid"><div class="leader-portrait">侍</div><div><div class="game-kicker">Empress Akiko</div><h3 style="font-size:25px;margin-top:5px">Japan</h3><p>“Our borders remain peaceful, but your scouts travel too close to Kyoto.”</p><div class="aonw-divider"></div><div class="game-label">Relationship · 52 / 100<div class="relation-meter"><span style="width:52%"></span></div></div><div class="game-button-row" style="margin-top:14px"><span class="game-chip">Open Borders</span><span class="game-chip">Trade Route</span><span class="game-chip">No War</span></div></div></div>
          <div class="game-button-row" style="margin-top:14px"><button class="game-button">Propose Deal</button><button class="game-button secondary">Send Gift</button><button class="game-button danger" data-modal="declare-war">Declare War</button></div>
        </div>
      </div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button>`
    });
  }

  function renderUnitModal() {
    const unit = selectedUnit() ?? state.world.units[0];
    const nation = nationById(unit.nationId);
    return modalShell({
      id: 'unit', icon: unit.symbol, title: unit.name, subtitle: `${nation.name} · ${unit.typeName} · Veteran I`, size: 'medium',
      body: `<div class="modal-grid"><div class="combatant"><div class="unit-art">${unit.symbol}</div><div class="game-badge" style="background:${nation.color}">${nation.name}</div></div><div><div class="stat-grid" style="grid-template-columns:repeat(2,1fr)">${stat(unit.attack, 'Attack')}${stat(unit.defense, 'Defense')}${stat(`${unit.ap}/${unit.movement}`, 'Movement')}${stat('84/100', 'Health')}</div><div class="aonw-divider"></div><p class="game-muted" style="font-size:11px;line-height:1.55">A flexible field unit. Movement route respects terrain cost, roads, hostile zones and the unit domain.</p></div></div>
        <div class="game-button-row" style="margin-top:16px"><button class="game-button">⌖ Move</button><button class="game-button secondary" data-modal="combat">⚔ Attack</button><button class="game-button secondary">⛺ Fortify</button><button class="game-button secondary" data-modal="army">⇥ Join Army</button><button class="game-button ghost">◷ Skip</button></div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button>`
    });
  }

  function renderArmyModal() {
    return modalShell({
      id: 'army', icon: '♟', title: 'Northern Army', subtitle: '3 units · 246 / 300 health · Commander: Mieszko', size: 'wide',
      body: `<div class="modal-grid"><section class="modal-card"><h3>Formation</h3><div class="list-stack">${unitArmyRow('⚔', '1st Warriors', '92 / 100 · Front line')}${unitArmyRow('➹', 'Royal Archers', '78 / 100 · Ranged')}${unitArmyRow('♘', 'Winged Cavalry', '76 / 100 · Flank')}</div><button class="game-button ghost" style="width:100%;margin-top:10px">＋ Attach Selected Unit</button></section><section class="modal-card"><h3>Army orders</h3><div class="stat-grid" style="grid-template-columns:repeat(2,1fr)">${stat('46', 'Power')}${stat('31', 'Defense')}${stat('3', 'Movement')}${stat('82%', 'Supply')}</div><div class="aonw-divider"></div><div class="game-button-stack"><button class="game-button">⌖ Set Army Route</button><button class="game-button secondary">⛺ Fortify Army</button><button class="game-button secondary">⇄ Reorder Formation</button><button class="game-button danger">Dissolve Army</button></div></section></div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button><button class="game-button">Apply Formation</button>`
    });
  }

  function renderWorkerModal() {
    return modalShell({
      id: 'worker', icon: '⛏', title: 'Choose Improvement', subtitle: 'Worker · Grassland (12, 8) · 3/3 movement', size: 'medium',
      body: `<div class="catalog-grid">${improvementItem('🌾', 'Farm', '+2 Food', '3 turns', true)}${improvementItem('⚒', 'Mine', '+2 Production', '4 turns')}${improvementItem('⌂', 'Trading Post', '+2 Gold', '4 turns')}${improvementItem('═', 'Road', 'Movement cost ½', '2 turns')}${improvementItem('♜', 'Fort', '+25% Defense', '5 turns')}${improvementItem('✦', 'Harvest Resource', '+20 Food now', '1 turn')}</div><p class="game-muted" style="font-size:10px;margin:12px 0 0">Only valid improvements for the selected adjacent tile are shown. The route is previewed before work begins.</p>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Cancel</button><button class="game-button">Build Farm</button>`
    });
  }

  function renderCombatModal() {
    return modalShell({
      id: 'combat', icon: '⚔', title: 'Combat Preview', subtitle: 'Open terrain · no river crossing · defender fortified', size: 'medium',
      body: `<div class="combat-vs"><div class="combatant"><div class="unit-art">♘</div><h3>Winged Cavalry</h3><div class="health-bar"><span style="width:84%"></span></div><p class="game-muted">84 HP · 18 attack</p></div><div class="vs-mark">VS</div><div class="combatant"><div class="unit-art">➹</div><h3>Japanese Archers</h3><div class="health-bar"><span style="width:67%"></span></div><p class="game-muted">67 HP · 14 defense</p></div></div><div class="aonw-divider"></div><div class="stat-grid">${stat('72%', 'Victory')}${stat('−24', 'Expected HP')}${stat('−49', 'Enemy HP')}${stat('+6', 'Experience')}</div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Cancel</button><button class="game-button danger" data-action="resolve-combat">⚔ Attack</button>`
    });
  }

  function renderObjectivesModal() {
    return modalShell({
      id: 'objectives', icon: '★', title: 'Objectives & Victory', subtitle: 'Track victory pressure, milestones and score', size: 'wide',
      body: `<div class="tab-row"><button class="tab is-active">Objectives</button><button class="tab">Victory</button><button class="tab">Score</button></div><div class="modal-grid three">${objectiveCard('⚑', 'Territorial Presence', 'Control 20% of land', '68%', '13 / 19 regions')}${objectiveCard('⚗', 'Scientific Momentum', 'Research 4 era technologies', '75%', '3 / 4 technologies')}${objectiveCard('◆', 'World Artifacts', 'Return artifacts to a city', '50%', '1 / 2 artifacts')}${objectiveCard('♜', 'Urban Network', 'Connect 5 cities', '60%', '3 / 5 cities')}${objectiveCard('⚔', 'Military Deterrence', 'Maintain army power 100', '82%', '82 / 100 power')}${objectiveCard('●', 'Prosperity', 'Reach 500 treasury', '57%', '284 / 500 gold')}</div><div class="aonw-divider"></div><div class="stat-grid">${stat('642', 'Your score')}${stat('611', 'Japan')}${stat('548', 'Netherlands')}${stat('492', 'Egypt')}</div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button>`
    });
  }

  function renderArtifactModal() {
    return modalShell({
      id: 'artifact', icon: '◆', title: 'The Astral Compass', subtitle: 'World artifact · carried by Royal Scout', size: 'medium',
      body: `<div class="event-art">✥</div><h3 class="game-title game-title-md" style="margin:15px 0 7px;text-align:center">The Astral Compass</h3><p class="game-muted" style="font-size:11px;line-height:1.55;text-align:center">An impossible brass instrument whose needle points toward places not yet charted. Return it to a controlled city to secure its legacy.</p><div class="stat-grid" style="margin-top:14px;grid-template-columns:repeat(3,1fr)">${stat('+8', 'Science')}${stat('+5', 'Culture')}${stat('1 AP', 'Carry cost')}</div>`,
      footer: `<button class="game-button ghost" data-action="drop-artifact">Drop Artifact</button><button class="game-button">Bring to City…</button>`
    });
  }

  function renderLogisticsModal() {
    return modalShell({
      id: 'logistics', icon: '⇢', title: 'Empire Resources & Logistics', subtitle: 'Production, stockpiles, demand and trade', size: 'wide',
      body: `<div class="stat-grid">${stat('9', 'Iron stock')}${stat('+2', 'Iron / turn')}${stat('6', 'Horse stock')}${stat('82%', 'Army supply')}</div><div class="aonw-divider"></div><div class="resource-flow"><div class="flow-node"><b>⛏ Iron Mine</b><small class="game-muted">+3 / turn</small></div><div class="flow-arrow">→</div><div class="flow-node"><b>♜ Kraków</b><small class="game-muted">−1 industry</small></div><div class="flow-arrow">→</div><div class="flow-node"><b>⚔ Northern Army</b><small class="game-muted">−1 upkeep</small></div></div><div class="modal-grid" style="margin-top:14px"><section class="modal-card"><h3>Strategic stockpiles</h3><div class="list-stack">${resourceRow('◆', 'Iron', '9', '+3', '−1')}${resourceRow('♞', 'Horses', '6', '+1', '0')}${resourceRow('♨', 'Coal', '0', '0', '0')}${resourceRow('●', 'Oil', '0', 'Hidden', '—')}</div></section><section class="modal-card"><h3>Connections</h3><div class="list-stack">${listRow('═', 'Kraków ↔ Gdańsk', 'Road · connected · 100% capacity', '100%')}${listRow('≋', 'Gdańsk ↔ Amsterdam', 'Sea trade · 74% capacity', '74%')}${listRow('⚠', 'Northern Army', 'Supply line exposed near Kyoto', '48%')}</div></section></div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button><button class="game-button">Manage Trade</button>`
    });
  }

  function renderEventModal() {
    return modalShell({
      id: 'event', icon: '☀', title: 'A Merchant from the East', subtitle: 'World event · choice required', size: 'medium',
      body: `<div class="event-art">⛵</div><p class="game-muted" style="font-size:12px;line-height:1.6;margin:14px 0 0">A weathered merchant fleet reaches Gdańsk carrying unfamiliar instruments and maps. Its captain offers knowledge in exchange for protection.</p><div class="event-choices"><button class="game-button event-choice"><span class="game-icon-tile">⚗</span><span><b>Fund the expedition</b><br><small>−80 Gold · +120 Science · Japan relation +4</small></span></button><button class="game-button secondary event-choice"><span class="game-icon-tile">●</span><span><b>Purchase the cargo</b><br><small>−45 Gold · +1 Spices · Gdańsk grows</small></span></button><button class="game-button ghost event-choice"><span class="game-icon-tile">↶</span><span><b>Decline politely</b><br><small>No immediate effect</small></span></button></div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Decide Later</button>`
    });
  }

  function renderPauseModal() {
    return modalShell({
      id: 'pause', icon: 'Ⅱ', title: 'Game Paused', subtitle: 'Local match · Turn 31', size: 'small',
      body: `<div class="game-button-stack"><button class="game-button" data-action="close-modal"><span class="button-icon">▶</span>Resume Game</button><button class="game-button secondary" data-modal="save"><span class="button-icon">▣</span>Save Game</button><button class="game-button secondary" data-modal="load"><span class="button-icon">▤</span>Load Game</button><button class="game-button secondary" data-screen="settings"><span class="button-icon">⚙</span>Settings</button><button class="game-button ghost" data-screen="help"><span class="button-icon">?</span>Help</button><button class="game-button danger" data-screen="main-menu"><span class="button-icon">⌂</span>Exit to Main Menu</button></div>`
    });
  }

  function renderSaveModal() {
    return modalShell({
      id: 'save', icon: '▣', title: 'Save Game', subtitle: 'Create or replace a local save', size: 'medium',
      body: `<label class="game-label">Save name<input class="game-input" value="Poland · Turn 31"></label><div class="list-stack" style="margin-top:14px">${saveRow('Autosave', 'Turn 30 · 2 minutes ago', 'Automatic')}${saveRow('Poland · Classical Era', 'Turn 24 · yesterday', 'Manual')}${saveRow('First settlement', 'Turn 7 · 4 days ago', 'Manual')}</div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Cancel</button><button class="game-button" data-action="save-game">Save</button>`
    });
  }

  function renderLoadModal() {
    return modalShell({
      id: 'load', icon: '▤', title: 'Load Game', subtitle: 'Current unsaved progress will be replaced', size: 'medium',
      body: `<div class="list-stack">${saveRow('Autosave', 'Turn 30 · 2 minutes ago', 'Automatic', true)}${saveRow('Poland · Classical Era', 'Turn 24 · yesterday', 'Manual')}${saveRow('First settlement', 'Turn 7 · 4 days ago', 'Manual')}</div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Cancel</button><button class="game-button">Load Selected Save</button>`
    });
  }

  function renderEndTurnModal() {
    return modalShell({
      id: 'end-turn', icon: '✓', title: 'End Turn?', subtitle: 'Turn 31 · Poland', size: 'small',
      body: `<p class="game-muted" style="line-height:1.6;margin-top:0">Two optional decisions remain. You may end the turn now or return to the map.</p><div class="list-stack">${warningRow('♞', 'Scout has movement remaining', '2 / 4 movement')}${warningRow('⚒', 'Kraków can change production', 'Library completes in 3 turns')}</div>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Keep Playing</button><button class="game-button gold" data-action="process-turn">End Turn</button>`
    });
  }

  function renderTechUnlockedModal() {
    return modalShell({
      id: 'tech-unlocked', icon: '✧', title: 'Technology Researched', subtitle: 'The knowledge of Construction spreads through your empire', size: 'medium',
      body: `<div class="event-art">🏛</div><h3 class="game-title game-title-md" style="text-align:center;margin:14px 0 7px">Construction</h3><p class="game-muted" style="text-align:center;line-height:1.55">Unlock stronger city infrastructure and durable connections across difficult terrain.</p><div class="modal-grid" style="margin-top:14px">${unlockCard('═', 'Stone Road', 'Lower movement cost and stronger trade links.')}${unlockCard('⌂', 'Aqueduct', '+3 Housing in cities next to fresh water.')}${unlockCard('⚒', 'Engineering Works', '+2 Production from quarries.')}${unlockCard('⚔', 'Catapult', 'Early siege unit effective against cities.')}</div>`,
      footer: `<button class="game-button" data-modal="research">Choose Next Research</button>`
    });
  }

  function renderCityFoundedModal() {
    return modalShell({
      id: 'city-founded', icon: '⚐', title: 'A New City Is Founded', subtitle: 'The frontier becomes part of Poland', size: 'medium',
      body: `<div class="event-art">♜</div><label class="game-label" style="margin-top:14px">City name<input class="game-input" value="Wrocław"></label><div class="stat-grid" style="margin-top:14px;grid-template-columns:repeat(3,1fr)">${stat('2', 'Population')}${stat('+5', 'Food')}${stat('+4', 'Production')}</div><p class="game-muted" style="font-size:10px;line-height:1.5">The first ring of adjacent land is claimed immediately. Territory will grow with culture and city development.</p>`,
      footer: `<button class="game-button" data-action="close-modal">Found Wrocław</button>`
    });
  }

  function renderTurnProcessingModal() {
    return modalShell({
      id: 'turn-processing', icon: '◌', title: 'Resolving Turn 31', subtitle: 'Input remains blocked until the human turn is ready', size: 'small',
      body: `<div class="loading-ring"></div><div class="list-stack">${processRow('✓', 'Poland submitted', 'Complete')}${processRow('✓', 'Japan resolved', 'Complete')}${processRow('◌', 'Netherlands planning', 'In progress')}${processRow('·', 'Egypt waiting', 'Queued')}</div><div class="game-progress" style="margin-top:16px"><span style="width:63%"></span></div><p class="game-muted" style="font-size:10px;text-align:center">Deterministic engine step 3 of 5</p>`
    });
  }

  function renderDeclareWarModal() {
    return modalShell({
      id: 'declare-war', icon: '!', title: 'Declare War on Japan?', subtitle: 'This diplomatic action cannot be undone this turn', size: 'small',
      body: `<div class="combat-vs"><div class="combatant"><div class="civ-flag" style="width:70px;height:46px;margin:auto;background:${NATIONS[0].flag}"></div><h3>Poland</h3></div><div class="vs-mark">⚔</div><div class="combatant"><div class="civ-flag" style="width:70px;height:46px;margin:auto;background:${NATIONS[1].flag}"></div><h3>Japan</h3></div></div><div class="aonw-divider"></div><div class="list-stack">${warningRow('⚑', 'Open Borders will end', 'Units may be displaced')}${warningRow('⇄', 'Trade route will be cancelled', '−7 Gold per turn')}${warningRow('☹', 'Other leaders will react', 'Warmonger pressure +12')}</div>`,
      footer: `<button class="game-button ghost" data-modal="diplomacy">Cancel</button><button class="game-button danger" data-action="declare-war">Declare War</button>`
    });
  }

  function renderDeveloperModal() {
    const selected = state.world.hexByKey.get(state.selectedHexKey) ?? state.world.hexes[0];
    return modalShell({
      id: 'developer', icon: '⌘', title: 'Map Diagnostics', subtitle: 'Presentation-only design state', size: 'medium',
      body: `<div class="stat-grid">${stat(state.world.hexes.length, 'Hexes')}${stat(state.world.cities.length, 'Cities')}${stat(state.world.units.length, 'Units')}${stat(state.route.length, 'Route nodes')}</div><div class="aonw-divider"></div><div class="modal-grid"><section class="modal-card"><h3>Selected hex</h3><pre style="margin:0;color:#cdd8de;font-size:10px;white-space:pre-wrap">${escapeHtml(JSON.stringify({ key: selected.key, q: selected.q, r: selected.r, terrain: selected.terrain, ownerId: selected.ownerId, resource: selected.resource?.name ?? null, fogged: selected.fogged }, null, 2))}</pre></section><section class="modal-card"><h3>Layer state</h3>${switchRow('Territories', 'Ownership tint and borders', state.territoryEnabled, 'toggle-territory')}${switchRow('Resources', 'Strategic and luxury markers', state.resourcesEnabled, 'toggle-resources')}${switchRow('Fog of war', 'Visibility mask', state.fogEnabled, 'toggle-fog')}</section></div><p class="game-muted" style="font-size:10px">This package intentionally does not mutate authoritative engine state. It models visual states and interactions for design work.</p>`,
      footer: `<button class="game-button ghost" data-action="close-modal">Close</button><button class="game-button" data-action="regenerate-world">Regenerate World</button>`
    });
  }

  function handleGameClick(event) {
    const unitElement = event.target.closest('[data-unit-id]');
    if (unitElement) {
      selectUnit(unitElement.dataset.unitId);
      return;
    }

    const cityElement = event.target.closest('[data-city-id]');
    if (cityElement) {
      state.selectedCityId = cityElement.dataset.cityId;
      state.selectedHexKey = hexKey(selectedCity().q, selectedCity().r);
      state.modal = 'city';
      render();
      return;
    }

    const hexElement = event.target.closest('[data-hex-key]');
    if (hexElement && state.screen === 'map') {
      selectHex(hexElement.dataset.hexKey);
      return;
    }

    const screenButton = event.target.closest('[data-screen]');
    if (screenButton) {
      setScreen(screenButton.dataset.screen);
      return;
    }

    const modalButton = event.target.closest('[data-modal]');
    if (modalButton) {
      openModal(modalButton.dataset.modal);
      return;
    }

    const actionButton = event.target.closest('[data-action]');
    if (actionButton) handleAction(actionButton.dataset.action);
  }

  function handleAction(action) {
    switch (action) {
      case 'close-modal': closeModal(); break;
      case 'continue': setScreen('map'); showToast('Local save restored for design preview.'); break;
      case 'start-game': setScreen('map'); showToast('Local match started.'); break;
      case 'toggle-fog': state.fogEnabled = !state.fogEnabled; render(); break;
      case 'toggle-territory': state.territoryEnabled = !state.territoryEnabled; render(); break;
      case 'toggle-resources': state.resourcesEnabled = !state.resourcesEnabled; render(); break;
      case 'toggle-reduced-motion': state.reducedMotion = !state.reducedMotion; render(); break;
      case 'toggle-high-contrast': state.highContrast = !state.highContrast; render(); break;
      case 'reset-settings': state.reducedMotion = false; state.highContrast = false; render(); showToast('Settings reset.'); break;
      case 'onboarding-prev': state.onboardingStep = Math.max(0, state.onboardingStep - 1); render(); break;
      case 'onboarding-next':
        if (state.onboardingStep >= 3) setScreen('main-menu'); else { state.onboardingStep += 1; render(); }
        break;
      case 'zoom-in': state.zoom = Math.min(1.45, state.zoom + 0.12); render(); break;
      case 'zoom-out': state.zoom = Math.max(0.46, state.zoom - 0.12); render(); break;
      case 'reset-camera': state.zoom = 0.79; state.panX = 8; state.panY = 8; render(); break;
      case 'replay-toggle': state.replayPlaying = !state.replayPlaying; render(); break;
      case 'replay-speed': state.replaySpeed = state.replaySpeed === 1 ? 2 : state.replaySpeed === 2 ? 4 : 1; render(); break;
      case 'process-turn': state.modal = 'turn-processing'; render(); window.setTimeout(() => { if (state.modal === 'turn-processing') { state.modal = 'event'; render(); } }, 1600); break;
      case 'resolve-combat': showToast('Combat command staged in the design state.'); closeModal(); break;
      case 'save-game': showToast('Local save state captured.'); closeModal(); break;
      case 'declare-war': showToast('War declaration staged.'); state.modal = 'diplomacy'; render(); break;
      case 'drop-artifact': showToast('Artifact dropped on the selected hex.'); closeModal(); break;
      case 'create-account': showToast('Create-account form state is represented by the same auth panel.'); break;
      case 'create-match': setScreen('multiplayer-match'); break;
      case 'submit-turn': showToast('Turn submitted: 3 / 4 players ready.'); break;
      case 'regenerate-world': regenerateWorld(); break;
      default: showToast(`${action.replaceAll('-', ' ')} · design interaction`);
    }
  }

  function bindRenderedControls() {
    const volume = document.getElementById('volume-slider');
    if (volume) volume.addEventListener('input', () => { document.getElementById('volume-copy').textContent = `${volume.value}%`; });
    const sensitivity = document.getElementById('sensitivity-slider');
    if (sensitivity) sensitivity.addEventListener('input', () => { document.getElementById('sensitivity-copy').textContent = `${(Number(sensitivity.value) / 100).toFixed(2).replace(/0$/, '')}×`; });
    const replaySlider = document.getElementById('replay-slider');
    if (replaySlider) replaySlider.addEventListener('input', () => { state.replayPosition = Number(replaySlider.value); render(); });
    bindMapGestures();
  }

  function bindMapGestures() {
    const svg = document.getElementById('hex-map');
    if (!svg) return;
    let dragging = false;
    let originX = 0;
    let originY = 0;
    let panStartX = state.panX;
    let panStartY = state.panY;

    svg.addEventListener('wheel', (event) => {
      event.preventDefault();
      state.zoom = clamp(state.zoom + (event.deltaY < 0 ? 0.08 : -0.08), 0.46, 1.45);
      render();
    }, { passive: false });

    svg.addEventListener('pointerdown', (event) => {
      if (event.target.closest('[data-unit-id], [data-city-id]')) return;
      dragging = true;
      originX = event.clientX;
      originY = event.clientY;
      panStartX = state.panX;
      panStartY = state.panY;
      svg.setPointerCapture(event.pointerId);
    });

    svg.addEventListener('pointermove', (event) => {
      if (!dragging) return;
      const scaleX = MAP_WIDTH / svg.getBoundingClientRect().width;
      const scaleY = MAP_HEIGHT / svg.getBoundingClientRect().height;
      state.panX = panStartX + (event.clientX - originX) * scaleX;
      state.panY = panStartY + (event.clientY - originY) * scaleY;
      const group = document.getElementById('map-transform');
      if (group) group.setAttribute('transform', `translate(${state.panX} ${state.panY}) scale(${state.zoom})`);
    });

    const stopDrag = () => { dragging = false; };
    svg.addEventListener('pointerup', stopDrag);
    svg.addEventListener('pointercancel', stopDrag);
  }

  function selectUnit(unitId) {
    const unit = state.world.units.find((candidate) => candidate.id === unitId);
    if (!unit) return;
    state.selectedUnitId = unit.id;
    state.selectedHexKey = hexKey(unit.q, unit.r);
    state.route = [];
    render();
    showToast(`${unit.name} selected. Choose a destination hex.`);
  }

  function selectHex(key) {
    const hex = state.world.hexByKey.get(key);
    if (!hex) return;
    state.selectedHexKey = key;
    const unit = selectedUnit();
    if (!unit) {
      state.route = [];
      render();
      return;
    }
    const path = findPath(hexKey(unit.q, unit.r), key, unit);
    if (!path) {
      state.route = [];
      render();
      showToast(`${TERRAIN_LABELS[hex.terrain]} is not reachable by ${unit.typeName}.`);
      return;
    }
    state.route = path;
    render();
  }

  function findPath(startKey, goalKey, unit) {
    if (startKey === goalKey) return [startKey];
    const open = [{ key: startKey, f: 0 }];
    const cameFrom = new Map();
    const gScore = new Map([[startKey, 0]]);
    const visited = new Set();

    while (open.length) {
      open.sort((a, b) => a.f - b.f);
      const current = open.shift().key;
      if (current === goalKey) return reconstructPath(cameFrom, current);
      if (visited.has(current)) continue;
      visited.add(current);
      const currentHex = state.world.hexByKey.get(current);
      for (const neighbor of hexNeighbors(currentHex.q, currentHex.r)) {
        const next = state.world.hexByKey.get(hexKey(neighbor.q, neighbor.r));
        if (!next) continue;
        const cost = movementCost(next, unit);
        if (!Number.isFinite(cost)) continue;
        const tentative = (gScore.get(current) ?? Infinity) + cost;
        if (tentative >= (gScore.get(next.key) ?? Infinity)) continue;
        cameFrom.set(next.key, current);
        gScore.set(next.key, tentative);
        open.push({ key: next.key, f: tentative + hexDistance(next, state.world.hexByKey.get(goalKey)) });
      }
    }
    return null;
  }

  function movementCost(hex, unit) {
    if (unit.domain === 'naval') return ['ocean', 'coast'].includes(hex.terrain) ? (hex.terrain === 'coast' ? 1 : 1.25) : Infinity;
    if (['ocean', 'coast', 'mountain'].includes(hex.terrain)) return Infinity;
    let cost = TERRAIN_COST[hex.terrain] ?? 1;
    if (hex.road) cost = Math.min(cost, 0.5);
    return cost;
  }

  function pathCost(path, unit) {
    if (!unit || path.length < 2) return 0;
    return path.slice(1).reduce((sum, key) => sum + movementCost(state.world.hexByKey.get(key), unit), 0).toFixed(1).replace('.0', '');
  }

  function reconstructPath(cameFrom, current) {
    const path = [current];
    while (cameFrom.has(current)) {
      current = cameFrom.get(current);
      path.unshift(current);
    }
    return path;
  }

  function generateWorld(seed) {
    const random = seededRandom(seed);
    const nationOrder = shuffle([...NATIONS], random).slice(0, 6);
    const siteOrder = shuffle([...CITY_SITES], random).slice(0, 6);
    const cities = siteOrder.map(([baseQ, baseR], index) => {
      const nation = nationOrder[index];
      const q = clamp(baseQ + randomInt(random, -1, 1), 2, HEX_COLUMNS - 3);
      const r = clamp(baseR + randomInt(random, -1, 1), 2, HEX_ROWS - 3);
      return {
        id: `city-${index + 1}`,
        nationId: nation.id,
        name: nation.names[randomInt(random, 0, nation.names.length - 1)],
        q,
        r,
        population: randomInt(random, 3, 11),
        food: randomInt(random, 5, 16),
        production: randomInt(random, 4, 14),
        territoryRadius: randomInt(random, 3, 5)
      };
    });

    const hexes = [];
    for (let q = 0; q < HEX_COLUMNS; q += 1) {
      for (let r = 0; r < HEX_ROWS; r += 1) {
        const key = hexKey(q, r);
        const nearestCityDistance = Math.min(...cities.map((city) => hexDistance({ q, r }, city)));
        const terrain = generateTerrain(seed, q, r, nearestCityDistance);
        const owner = assignOwner(seed, q, r, terrain, cities);
        const resourceNoise = hash01(seed + 73, q * 7, r * 11);
        const resourceIndex = Math.floor(hash01(seed + 191, q, r) * RESOURCE_SYMBOLS.length);
        const resource = !['ocean', 'mountain'].includes(terrain) && resourceNoise > 0.935 ? { symbol: RESOURCE_SYMBOLS[resourceIndex], name: RESOURCE_NAMES[resourceIndex] } : null;
        const playerCity = cities.find((city) => city.nationId === nationOrder[0].id);
        const visibility = playerCity ? hexDistance({ q, r }, playerCity) : 99;
        const fogged = visibility > 7 + Math.floor(hash01(seed + 313, q, r) * 4);
        hexes.push({ key, q, r, terrain, ownerId: owner?.nationId ?? null, resource, fogged, road: owner && hash01(seed + 811, q, r) > 0.86 });
      }
    }

    const hexByKey = new Map(hexes.map((hex) => [hex.key, hex]));
    for (const city of cities) {
      const cityHex = hexByKey.get(hexKey(city.q, city.r));
      cityHex.terrain = ['desert', 'tundra'].includes(cityHex.terrain) ? cityHex.terrain : 'grassland';
      cityHex.ownerId = city.nationId;
      cityHex.fogged = city.nationId !== nationOrder[0].id && cityHex.fogged;
    }

    const units = [];
    cities.forEach((city, cityIndex) => {
      const count = cityIndex === 0 ? 3 : randomInt(random, 1, 3);
      for (let index = 0; index < count; index += 1) {
        const unitType = UNIT_TYPES[randomInt(random, 0, UNIT_TYPES.length - 2)];
        const position = findUnitPosition(city, hexByKey, units, random, unitType.domain);
        units.push({
          id: `unit-${cityIndex + 1}-${index + 1}`,
          nationId: city.nationId,
          typeId: unitType.id,
          typeName: unitType.name,
          name: `${nationById(city.nationId).name} ${unitType.name}`,
          symbol: unitType.symbol,
          domain: unitType.domain,
          attack: unitType.attack + randomInt(random, 0, 3),
          defense: unitType.defense + randomInt(random, 0, 3),
          movement: unitType.movement,
          ap: randomInt(random, Math.max(1, unitType.movement - 1), unitType.movement),
          q: position.q,
          r: position.r,
          offsetX: index % 2 === 0 ? -12 : 13,
          offsetY: index % 3 === 0 ? -14 : 12
        });
      }
    });

    const coastCity = cities.find((city) => hexNeighbors(city.q, city.r).some((neighbor) => ['ocean', 'coast'].includes(hexByKey.get(hexKey(neighbor.q, neighbor.r))?.terrain)));
    if (coastCity) {
      const water = hexNeighbors(coastCity.q, coastCity.r).map((coord) => hexByKey.get(hexKey(coord.q, coord.r))).find((hex) => hex && ['ocean', 'coast'].includes(hex.terrain));
      if (water) {
        const galley = UNIT_TYPES.find((unit) => unit.id === 'galley');
        units.push({ id: 'unit-galley-1', nationId: coastCity.nationId, typeId: galley.id, typeName: galley.name, name: `${nationById(coastCity.nationId).name} Galley`, symbol: galley.symbol, domain: galley.domain, attack: galley.attack, defense: galley.defense, movement: galley.movement, ap: galley.movement, q: water.q, r: water.r, offsetX: 0, offsetY: 0 });
      }
    }

    return { seed, hexes, hexByKey, cities, units, playerNationId: nationOrder[0].id };
  }

  function generateTerrain(seed, q, r, nearestCityDistance) {
    const edge = Math.min(q, r, HEX_COLUMNS - 1 - q, HEX_ROWS - 1 - r);
    const continental = Math.sin((q + seed % 17) * 0.43) + Math.cos((r - seed % 13) * 0.61) + Math.sin((q + r) * 0.19);
    const detail = hash01(seed, q, r) * 1.6 - 0.8;
    const elevation = continental + detail + Math.min(edge, 4) * 0.22;
    if (nearestCityDistance <= 1) return hash01(seed + 3, q, r) > 0.8 ? 'hills' : 'grassland';
    if (edge === 0 || elevation < -0.38) return 'ocean';
    if (elevation < -0.05) return 'coast';
    const moisture = hash01(seed + 29, q * 3, r * 5) + Math.cos(r * 0.4) * 0.18;
    const height = hash01(seed + 51, q * 5, r * 2) + continental * 0.07;
    if (height > 0.92) return 'mountain';
    if (height > 0.77) return 'hills';
    if (r < 2 || r > HEX_ROWS - 3) return moisture > 0.66 ? 'forest' : 'tundra';
    if (moisture < 0.2) return 'desert';
    if (moisture > 0.84) return 'swamp';
    if (moisture > 0.62) return 'forest';
    return moisture > 0.42 ? 'grassland' : 'plains';
  }

  function assignOwner(seed, q, r, terrain, cities) {
    if (['ocean', 'coast'].includes(terrain)) return null;
    const ranked = cities.map((city) => ({ city, distance: hexDistance({ q, r }, city), distortion: (hash01(seed + city.id.length * 17, q, r) - 0.5) * 1.8 })).sort((a, b) => (a.distance + a.distortion) - (b.distance + b.distortion));
    const candidate = ranked[0];
    return candidate.distance <= candidate.city.territoryRadius + candidate.distortion ? candidate.city : null;
  }

  function findUnitPosition(city, hexByKey, units, random, domain) {
    const candidates = [{ q: city.q, r: city.r }, ...hexNeighbors(city.q, city.r), ...hexNeighbors(city.q, city.r).flatMap((coord) => hexNeighbors(coord.q, coord.r))];
    const shuffled = shuffle(candidates, random);
    return shuffled.find((coord) => {
      const hex = hexByKey.get(hexKey(coord.q, coord.r));
      if (!hex) return false;
      const compatible = domain === 'naval' ? ['ocean', 'coast'].includes(hex.terrain) : !['ocean', 'coast', 'mountain'].includes(hex.terrain);
      return compatible && !units.some((unit) => unit.q === coord.q && unit.r === coord.r);
    }) ?? { q: city.q, r: city.r };
  }

  function hexCenter(q, r) {
    return { x: MAP_MARGIN + HEX_RADIUS + q * HEX_RADIUS * 1.5, y: MAP_MARGIN + HEX_HEIGHT / 2 + (r + (q % 2 ? 0.5 : 0)) * HEX_HEIGHT };
  }

  function hexPolygon(x, y) {
    const points = [];
    for (let index = 0; index < 6; index += 1) {
      const angle = Math.PI / 180 * (60 * index);
      points.push(`${(x + HEX_RADIUS * Math.cos(angle)).toFixed(2)},${(y + HEX_RADIUS * Math.sin(angle)).toFixed(2)}`);
    }
    return points.join(' ');
  }

  function hexNeighbors(q, r) {
    const even = [[1, 0], [0, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]];
    const odd = [[1, 1], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, 0]];
    return (q % 2 ? odd : even).map(([dq, dr]) => ({ q: q + dq, r: r + dr }));
  }

  function hexDistance(a, b) {
    if (!a || !b) return Infinity;
    const ac = oddQToCube(a.q, a.r);
    const bc = oddQToCube(b.q, b.r);
    return Math.max(Math.abs(ac.x - bc.x), Math.abs(ac.y - bc.y), Math.abs(ac.z - bc.z));
  }

  function oddQToCube(q, r) {
    const x = q;
    const z = r - (q - (q & 1)) / 2;
    return { x, z, y: -x - z };
  }

  function smoothRoutePath(points) {
    if (points.length < 2) return '';
    if (points.length === 2) return `M ${points[0].x} ${points[0].y} L ${points[1].x} ${points[1].y}`;
    let path = `M ${points[0].x} ${points[0].y}`;
    for (let index = 1; index < points.length - 1; index += 1) {
      const current = points[index];
      const next = points[index + 1];
      const midpoint = { x: (current.x + next.x) / 2, y: (current.y + next.y) / 2 };
      path += ` Q ${current.x} ${current.y} ${midpoint.x} ${midpoint.y}`;
    }
    const beforeLast = points[points.length - 2];
    const last = points[points.length - 1];
    path += ` Q ${beforeLast.x} ${beforeLast.y} ${last.x} ${last.y}`;
    return path;
  }

  function selectedUnit() { return state.world.units.find((unit) => unit.id === state.selectedUnitId) ?? null; }
  function selectedCity() { return state.world.cities.find((city) => city.id === state.selectedCityId) ?? state.world.cities[0]; }
  function nationById(id) { return NATIONS.find((nation) => nation.id === id); }
  function hexKey(q, r) { return `${q}:${r}`; }
  function screenLabel(id) { return SCREENS.find((screen) => screen.id === id)?.label ?? id; }
  function modalLabel(id) { return MODALS.find((modal) => modal.id === id)?.label ?? id; }
  function clamp(value, minimum, maximum) { return Math.max(minimum, Math.min(maximum, value)); }

  function seededRandom(seed) {
    let value = seed >>> 0;
    return () => {
      value += 0x6D2B79F5;
      let next = value;
      next = Math.imul(next ^ (next >>> 15), next | 1);
      next ^= next + Math.imul(next ^ (next >>> 7), next | 61);
      return ((next ^ (next >>> 14)) >>> 0) / 4294967296;
    };
  }

  function hash01(seed, q, r) {
    let value = Math.imul(q + 374761393, 668265263) ^ Math.imul(r + 1442695041, 2246822519) ^ seed;
    value = Math.imul(value ^ (value >>> 13), 1274126177);
    return ((value ^ (value >>> 16)) >>> 0) / 4294967295;
  }

  function randomInt(random, minimum, maximum) { return minimum + Math.floor(random() * (maximum - minimum + 1)); }
  function shuffle(items, random) {
    for (let index = items.length - 1; index > 0; index -= 1) {
      const other = Math.floor(random() * (index + 1));
      [items[index], items[other]] = [items[other], items[index]];
    }
    return items;
  }

  function showToast(message) {
    window.clearTimeout(state.toastTimer);
    refs.toast.textContent = message;
    refs.toast.classList.add('is-visible');
    state.toastTimer = window.setTimeout(() => refs.toast.classList.remove('is-visible'), 2200);
  }

  function escapeHtml(value) {
    return String(value).replace(/[&<>'"]/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' })[character]);
  }

  function selectField(label, options, selected, extraClass = '') {
    return `<label class="game-label ${extraClass}">${label}<select class="game-select">${options.map(([value, copy]) => `<option value="${value}" ${value === selected ? 'selected' : ''}>${copy}</option>`).join('')}</select></label>`;
  }

  function switchRow(title, copy, enabled, action) {
    return `<div class="game-checkbox"><span><strong>${title}</strong><br><small class="game-muted">${copy}</small></span><button type="button" class="game-switch ${enabled ? 'is-on' : ''}" data-action="${action}" aria-label="${title}"></button></div>`;
  }

  function helpSection(icon, title, body) { return `<section class="help-section"><div class="game-icon-tile">${icon}</div><div><h3>${title}</h3><p>${body}</p></div></section>`; }
  function stat(value, label) { return `<div class="stat"><b>${value}</b><small>${label}</small></div>`; }
  function resourcePill(icon, label, value, delta) { return `<span class="resource-pill"><span>${icon}</span><span>${label}</span><b>${value}</b><small style="color:#8fc18a">${delta}</small></span>`; }
  function hudButton(icon, label, modal) { return `<button class="hud-button" data-modal="${modal}">${icon}<small>${label}</small></button>`; }
  function actionButton(icon, label, modal = null) { return `<button class="action-button" ${modal ? `data-modal="${modal}"` : `data-action="${label.toLowerCase().replaceAll(' ', '-')}"`} title="${label}">${icon}</button>`; }
  function matchRow(title, subtitle, id) { return `<button class="match-row" data-screen="multiplayer-match"><span><strong>${title}</strong><small>${subtitle}</small></span><span class="game-badge">${id} ›</span></button>`; }
  function playerRow(name, status, color) { return `<div class="list-row"><span style="width:12px;height:28px;border-radius:4px;background:${color}"></span><div class="list-copy"><strong>${name}</strong><small>Player slot</small></div><span class="game-badge">${status}</span></div>`; }
  function listRow(icon, title, subtitle, progress) { return `<div class="list-row"><div class="game-icon-tile">${icon}</div><div class="list-copy"><strong>${title}</strong><small>${subtitle}</small>${progress ? `<div class="game-progress" style="margin-top:6px"><span style="width:${progress}"></span></div>` : ''}</div></div>`; }
  function queueRow(position, icon, title, subtitle, progress) { return `<div class="list-row queue-item"><span class="game-badge">${position}</span><div class="game-icon-tile">${icon}</div><div class="list-copy"><strong>${title}</strong><small>${subtitle}</small><div class="game-progress" style="margin-top:5px"><span style="width:${progress}"></span></div></div></div>`; }
  function catalogItem(icon, title, subtitle, cost, selected = false) { return `<button class="modal-card catalog-item ${selected ? 'is-selected' : ''}"><div class="game-row" style="gap:9px"><div class="game-icon-tile">${icon}</div><div class="list-copy"><strong>${title}</strong><small>${subtitle}</small></div><span class="game-badge">⚒ ${cost}</span></div></button>`; }
  function techNode(left, top, title, stateClass, cost, copy) { return `<button class="tech-node is-${stateClass}" style="left:${left}px;top:${top}px"><span>${cost}</span><strong>${title}</strong><small>${copy}</small></button>`; }
  function civRow(nation, relation, active = false) { return `<button class="civ-row ${active ? 'is-active' : ''}"><span class="civ-flag" style="background:${nation.flag}"></span><span class="list-copy"><strong>${nation.name}</strong><small>${relation}</small></span></button>`; }
  function unitArmyRow(icon, title, subtitle) { return `<div class="list-row"><div class="game-icon-tile">${icon}</div><div class="list-copy"><strong>${title}</strong><small>${subtitle}</small></div><button class="game-button icon-only ghost">↕</button></div>`; }
  function improvementItem(icon, title, yieldCopy, duration, selected = false) { return `<button class="modal-card catalog-item ${selected ? 'is-selected' : ''}"><div class="game-icon-tile" style="margin-bottom:8px">${icon}</div><h3>${title}</h3><p>${yieldCopy}<br>${duration}</p></button>`; }
  function objectiveCard(icon, title, copy, progress, meta) { return `<section class="modal-card"><div class="game-icon-tile">${icon}</div><h3 style="margin-top:9px">${title}</h3><p>${copy}</p><div class="game-progress" style="margin-top:10px"><span style="width:${progress}"></span></div><p style="margin-top:5px">${meta}</p></section>`; }
  function resourceRow(icon, name, stock, produced, consumed) { return `<div class="list-row"><div class="game-icon-tile">${icon}</div><div class="list-copy"><strong>${name}</strong><small>Stock ${stock}</small></div><span class="game-badge" style="color:#9fd49b">${produced}</span><span class="game-badge" style="color:#e39b91">${consumed}</span></div>`; }
  function saveRow(title, subtitle, type, selected = false) { return `<button class="list-row ${selected ? 'catalog-item is-selected' : ''}" style="width:100%;text-align:left"><div class="game-icon-tile">▣</div><div class="list-copy"><strong>${title}</strong><small>${subtitle}</small></div><span class="game-badge">${type}</span></button>`; }
  function warningRow(icon, title, subtitle) { return `<div class="list-row"><div class="game-icon-tile">${icon}</div><div class="list-copy"><strong>${title}</strong><small>${subtitle}</small></div></div>`; }
  function unlockCard(icon, title, copy) { return `<section class="modal-card"><div class="game-row" style="gap:9px"><div class="game-icon-tile">${icon}</div><div><h3 style="margin:0 0 3px">${title}</h3><p>${copy}</p></div></div></section>`; }
  function processRow(icon, title, status) { return `<div class="list-row"><span class="game-icon-tile">${icon}</span><div class="list-copy"><strong>${title}</strong></div><span class="game-badge">${status}</span></div>`; }
})();
