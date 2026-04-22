#!/usr/bin/env node
/**
 * Sorts all app_*.arb files to match app_en.arb:
 * - Alphabetical order by message id (@@locale first)
 * - Each @metadata block immediately follows its message key (from template)
 * - Missing keys in a locale are filled from English (untranslated fallback)
 *
 * Usage: node tool/sync_arb_sort.mjs
 * Run from shubhmilan_frontend/ after adding new keys to app_en.arb
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const arbDir = path.join(__dirname, "../lib/l10n");
const enPath = path.join(arbDir, "app_en.arb");

function sortedArbFromTemplate(template, localeData) {
  const baseKeys = Object.keys(template)
    .filter((k) => !k.startsWith("@"))
    .sort((a, b) => a.localeCompare(b, "en"));

  const out = {};
  if (localeData["@@locale"] !== undefined) {
    out["@@locale"] = localeData["@@locale"];
  } else if (template["@@locale"] !== undefined) {
    out["@@locale"] = template["@@locale"];
  }

  for (const k of baseKeys) {
    if (k === "@@locale") continue;
    const val = Object.prototype.hasOwnProperty.call(localeData, k) && localeData[k] !== undefined
      ? localeData[k]
      : template[k];
    out[k] = val;
    const metaKey = "@" + k;
    if (Object.prototype.hasOwnProperty.call(template, metaKey)) {
      out[metaKey] = template[metaKey];
    } else if (Object.prototype.hasOwnProperty.call(localeData, metaKey)) {
      out[metaKey] = localeData[metaKey];
    }
  }
  return out;
}

const en = JSON.parse(fs.readFileSync(enPath, "utf8"));
fs.writeFileSync(enPath, JSON.stringify(sortedArbFromTemplate(en, en), null, 2) + "\n");

const files = fs.readdirSync(arbDir).filter((f) => f.startsWith("app_") && f.endsWith(".arb") && f !== "app_en.arb");

for (const file of files) {
  const p = path.join(arbDir, file);
  const loc = JSON.parse(fs.readFileSync(p, "utf8"));
  const merged = sortedArbFromTemplate(en, loc);
  fs.writeFileSync(p, JSON.stringify(merged, null, 2) + "\n");
  const n = Object.keys(merged).filter((k) => !k.startsWith("@")).length;
  console.log(`${file}: ${n} message keys`);
}

console.log("Done. Run: flutter gen-l10n");
