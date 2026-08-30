(() => {
  "use strict";

  const ui = window.AONW_UI;
  if (!ui) throw new Error("AONW_UI registry was not loaded.");

  const viewportPresets = Object.freeze({
    desktop: { width: 1440, height: 900, label: "1440 × 900" },
    "desktop-small": { width: 1280, height: 720, label: "1280 × 720" },
    tablet: { width: 1024, height: 768, label: "1024 × 768" },
    mobile: { width: 390, height: 844, label: "390 × 844" },
    "mobile-landscape": { width: 844, height: 390, label: "844 × 390" }
  });

  const elements = {
    navigation: document.querySelector("#view-navigation"),
    search: document.querySelector("#view-search"),
    stage: document.querySelector("#viewport-stage"),
    measure: document.querySelector("#viewport-measure"),
    viewport: document.querySelector("#game-viewport"),
    gameRoot: document.querySelector("#game-root"),
    modalRoot: document.querySelector("#modal-root"),
    toastRoot: document.querySelector("#toast-root"),
    viewportSelect: document.querySelector("#viewport-select"),
    viewportSize: document.querySelector("#viewport-size"),
    activeKind: document.querySelector("#active-view-kind"),
    activeTitle: document.querySelector("#active-view-title"),
    coverageCount: document.querySelector("#coverage-count"),
    copyLink: document.querySelector("#copy-link"),
    toggleClean: document.querySelector("#toggle-clean")
  };

  const state = {
    screen: "main-menu",
    modal: null,
    viewport: "desktop",
    clean: false,
    toastTimer: null
  };

  const readLocationState = () => {
    const hash = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const query = new URLSearchParams(window.location.search);
    const requestedScreen = hash.get("screen") || query.get("screen");
    const requestedModal = hash.get("modal") || query.get("modal");
    const requestedViewport = hash.get("viewport") || query.get("viewport");
    const requestedClean = hash.get("clean") || query.get("clean");

    if (ui.screens.some((entry) => entry.id === requestedScreen)) state.screen = requestedScreen;
    if (ui.modals.some((entry) => entry.id === requestedModal)) state.modal = requestedModal;
    if (viewportPresets[requestedViewport]) state.viewport = requestedViewport;
    state.clean = requestedClean === "1" || requestedClean === "true";
  };

  const writeLocationState = () => {
    const hash = new URLSearchParams();
    hash.set("screen", state.screen);
    if (state.modal) hash.set("modal", state.modal);
    hash.set("viewport", state.viewport);
    if (state.clean) hash.set("clean", "1");
    const next = `${window.location.pathname}${window.location.search}#${hash.toString()}`;
    window.history.replaceState(null, "", next);
  };

  const groupBy = (items, key) => items.reduce((groups, item) => {
    const group = item[key] || "Other";
    (groups[group] ||= []).push(item);
    return groups;
  }, {});

  const navItem = (entry, kind) => `<button class="designer-nav-item" type="button" data-nav-kind="${kind}" data-nav-id="${entry.id}" data-filter="${`${entry.title} ${entry.group}`.toLowerCase()}">
    ${ui.icon(entry.icon || (kind === "screen" ? "display" : "info"))}<span>${entry.title}</span>
  </button>`;

  const buildNavigation = () => {
    const sections = [];
    for (const [group, entries] of Object.entries(groupBy(ui.screens, "group"))) {
      sections.push(`<section class="designer-group" data-nav-group><div class="designer-group__title"><span>${group}</span><span>${entries.length}</span></div>${entries.map((entry) => navItem(entry, "screen")).join("")}</section>`);
    }
    for (const [group, entries] of Object.entries(groupBy(ui.modals, "group"))) {
      sections.push(`<section class="designer-group" data-nav-group><div class="designer-group__title"><span>${group}</span><span>${entries.length}</span></div>${entries.map((entry) => navItem(entry, "modal")).join("")}</section>`);
    }
    elements.navigation.innerHTML = sections.join("");
    elements.coverageCount.textContent = `${ui.screens.length} screens · ${ui.modals.length} dialogs`;
  };

  const activeEntry = () => state.modal
    ? { kind: "Dialog", entry: ui.modals.find((item) => item.id === state.modal) }
    : { kind: "Screen", entry: ui.screens.find((item) => item.id === state.screen) };

  const updateActiveNavigation = () => {
    document.querySelectorAll(".designer-nav-item").forEach((button) => {
      const isModal = button.dataset.navKind === "modal";
      const active = isModal ? button.dataset.navId === state.modal : !state.modal && button.dataset.navId === state.screen;
      button.classList.toggle("is-active", active);
      if (active && document.activeElement !== elements.search) button.scrollIntoView({ block: "nearest" });
    });
    const active = activeEntry();
    elements.activeKind.textContent = active.kind;
    elements.activeTitle.textContent = active.entry?.title || "Unknown view";
  };

  const render = ({ screen = true, modal = true, syncLocation = true } = {}) => {
    if (screen) elements.gameRoot.innerHTML = ui.renderScreen(state.screen);
    if (modal) elements.modalRoot.innerHTML = state.modal ? ui.renderModal(state.modal) : "";
    document.body.classList.toggle("clean-mode", state.clean);
    elements.viewport.dataset.viewport = state.viewport;
    elements.viewportSelect.value = state.viewport;
    elements.viewportSize.textContent = viewportPresets[state.viewport].label;
    elements.toggleClean.innerHTML = `${ui.icon(state.clean ? "back" : "expand")} ${state.clean ? "Exit clean preview" : "Clean preview"}`;
    updateActiveNavigation();
    if (syncLocation) writeLocationState();
    requestAnimationFrame(fitViewport);
  };

  const fitViewport = () => {
    const preset = viewportPresets[state.viewport];
    if (!preset) return;

    elements.viewport.style.width = `${preset.width}px`;
    elements.viewport.style.height = `${preset.height}px`;

    const stageRect = elements.stage.getBoundingClientRect();
    const horizontalReserve = state.clean ? 0 : 2;
    const verticalReserve = state.clean ? 0 : 2;
    const scale = Math.max(0.1, Math.min(
      (stageRect.width - horizontalReserve) / preset.width,
      (stageRect.height - verticalReserve) / preset.height,
      state.clean ? 10 : 1
    ));

    elements.viewport.style.transform = `scale(${scale})`;
    elements.measure.style.width = `${Math.round(preset.width * scale)}px`;
    elements.measure.style.height = `${Math.round(preset.height * scale)}px`;
  };

  const setScreen = (id) => {
    if (!ui.screens.some((entry) => entry.id === id)) return;
    state.screen = id;
    state.modal = null;
    render();
  };

  const openModal = (id, { preserveScreen = true } = {}) => {
    if (!ui.modals.some((entry) => entry.id === id)) return;
    if (!preserveScreen) state.screen = ui.preferredScreenForModal(id);
    state.modal = id;
    render({ screen: !preserveScreen, modal: true });
  };

  const closeModal = () => {
    if (!state.modal) return;
    state.modal = null;
    render({ screen: false, modal: true });
  };

  const showToast = (message) => {
    window.clearTimeout(state.toastTimer);
    elements.toastRoot.innerHTML = `<div class="toast">${ui.icon("check")}<span>${String(message)}</span></div>`;
    state.toastTimer = window.setTimeout(() => {
      elements.toastRoot.innerHTML = "";
    }, 2200);
  };

  const toggleSelected = (target) => {
    const parent = target.parentElement;
    if (!parent) return;
    parent.querySelectorAll(":scope > [data-selectable]").forEach((item) => item.classList.remove("is-selected"));
    target.classList.add("is-selected");
  };

  const handleGameAction = (event) => {
    const target = event.target.closest("button, [data-selectable], [data-modal-backdrop], .switch");
    if (!target) return;

    const view = target.closest("[data-view]")?.dataset.view;
    if (view) {
      setScreen(view);
      return;
    }

    const modal = target.closest("[data-modal]")?.dataset.modal;
    if (modal) {
      openModal(modal, { preserveScreen: true });
      return;
    }

    if (target.closest("[data-close-modal]")) {
      closeModal();
      return;
    }

    if (target.matches("[data-modal-backdrop]") && event.target === target) {
      closeModal();
      return;
    }

    const toastSource = target.closest("[data-toast]");
    if (toastSource) {
      showToast(toastSource.dataset.toast);
      return;
    }

    const selectable = target.closest("[data-selectable]");
    if (selectable) {
      toggleSelected(selectable);
      return;
    }

    if (target.classList.contains("switch")) {
      target.classList.toggle("is-on");
      return;
    }

    if (target.matches(".segmented button")) {
      target.parentElement.querySelectorAll("button").forEach((button) => button.classList.toggle("is-active", button === target));
      return;
    }

    if (target.matches(".options-tabs button, .manual-toc button")) {
      target.parentElement.querySelectorAll("button").forEach((button) => button.classList.toggle("is-active", button === target));
    }
  };

  const handleNavigationClick = (event) => {
    const item = event.target.closest("[data-nav-kind][data-nav-id]");
    if (!item) return;
    if (item.dataset.navKind === "screen") {
      setScreen(item.dataset.navId);
    } else {
      state.screen = ui.preferredScreenForModal(item.dataset.navId);
      state.modal = item.dataset.navId;
      render();
    }
  };

  const filterNavigation = () => {
    const query = elements.search.value.trim().toLowerCase();
    elements.navigation.querySelectorAll(".designer-nav-item").forEach((item) => {
      item.hidden = query !== "" && !item.dataset.filter.includes(query);
    });
    elements.navigation.querySelectorAll("[data-nav-group]").forEach((group) => {
      group.hidden = ![...group.querySelectorAll(".designer-nav-item")].some((item) => !item.hidden);
    });
  };

  const toggleClean = () => {
    state.clean = !state.clean;
    render({ screen: false, modal: false });
  };

  const copyDeepLink = async () => {
    writeLocationState();
    try {
      await navigator.clipboard.writeText(window.location.href);
      showToast("Direct link copied");
    } catch {
      const textarea = document.createElement("textarea");
      textarea.value = window.location.href;
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";
      document.body.append(textarea);
      textarea.select();
      document.execCommand("copy");
      textarea.remove();
      showToast("Direct link copied");
    }
  };

  const handleKeyboard = (event) => {
    if (event.key === "Escape") {
      if (state.modal) closeModal();
      else if (state.clean) toggleClean();
      return;
    }
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k" && !state.clean) {
      event.preventDefault();
      elements.search.focus();
    }
  };

  const initialize = () => {
    readLocationState();
    buildNavigation();
    render({ syncLocation: false });
    writeLocationState();

    elements.navigation.addEventListener("click", handleNavigationClick);
    elements.search.addEventListener("input", filterNavigation);
    elements.viewportSelect.addEventListener("change", () => {
      state.viewport = elements.viewportSelect.value;
      render({ screen: false, modal: false });
    });
    elements.copyLink.addEventListener("click", copyDeepLink);
    elements.toggleClean.addEventListener("click", toggleClean);
    elements.gameRoot.addEventListener("click", handleGameAction);
    elements.modalRoot.addEventListener("click", handleGameAction);
    window.addEventListener("resize", fitViewport);
    window.addEventListener("keydown", handleKeyboard);
    window.addEventListener("hashchange", () => {
      readLocationState();
      render({ syncLocation: false });
    });
  };

  initialize();
})();
