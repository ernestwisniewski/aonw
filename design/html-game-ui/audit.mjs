import fs from "node:fs";
import vm from "node:vm";

const viewModules = [
  "views-core.js",
  "views-screens.js",
  "views-modals-city-diplomacy.js",
  "views-modals-tech-selection.js",
  "views-modals-economy-system.js",
  "views-registry.js",
];
const source = viewModules
  .map((name) => fs.readFileSync(new URL(`./scripts/${name}`, import.meta.url), "utf8"))
  .join("\n");
const sandbox = { window: {} };
vm.createContext(sandbox);
vm.runInContext(source, sandbox, { filename: "views-bundle.js" });

const ui = sandbox.window.AONW_UI;
const manifest = JSON.parse(fs.readFileSync(new URL("./view-manifest.json", import.meta.url), "utf8"));
const failures = [];

const auditCollection = (name, collection, render) => {
  const ids = new Set();
  for (const entry of collection) {
    if (ids.has(entry.id)) failures.push(`${name}: duplicate id ${entry.id}`);
    ids.add(entry.id);
    if (!Array.isArray(entry.source) || entry.source.length === 0) {
      failures.push(`${name}: ${entry.id} has no source mapping`);
    }
    let html = "";
    try {
      html = render(entry.id);
    } catch (error) {
      failures.push(`${name}: ${entry.id} threw ${error instanceof Error ? error.message : error}`);
      continue;
    }
    if (typeof html !== "string" || html.trim().length < 40) {
      failures.push(`${name}: ${entry.id} rendered empty or incomplete markup`);
    }
    if (/\b(?:undefined|null)\b/.test(html)) {
      failures.push(`${name}: ${entry.id} rendered an undefined/null token`);
    }
  }
};

auditCollection("screen", ui.screens, ui.renderScreen);
auditCollection("dialog", ui.modals, ui.renderModal);

if (manifest.coverage.screens !== ui.screens.length) {
  failures.push(`manifest screen count ${manifest.coverage.screens} != ${ui.screens.length}`);
}
if (manifest.coverage.dialogsAndOverlays !== ui.modals.length) {
  failures.push(`manifest dialog count ${manifest.coverage.dialogsAndOverlays} != ${ui.modals.length}`);
}
if (manifest.coverage.total !== ui.screens.length + ui.modals.length) {
  failures.push("manifest total count is inconsistent");
}

if (failures.length) {
  console.error("HTML UI audit failed:\n");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exitCode = 1;
} else {
  console.log(`HTML UI audit passed: ${ui.screens.length} screens, ${ui.modals.length} dialogs/overlays.`);
}
