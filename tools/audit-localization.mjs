import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const appRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = join(appRoot, "Sources");
const resourceRoot = join(appRoot, "Resources");
const projectPath = join(appRoot, "PrivateMoments.xcodeproj", "project.pbxproj");
const catalogPath = join(resourceRoot, "Localizable.xcstrings");
const errors = [];

function read(path) {
    try {
        return readFileSync(path, "utf8");
    } catch (error) {
        errors.push(`Cannot read ${relative(appRoot, path)}: ${error.message}`);
        return "";
    }
}

function decodeSwiftString(raw) {
    return raw
        .replace(/\\\([^)]*\)/g, "%lld")
        .replace(/\\n/g, "\n")
        .replace(/\\t/g, "\t")
        .replace(/\\"/g, '"')
        .replace(/\\\\/g, "\\");
}

function formatTokens(value) {
    return (value.match(/%(?:\d+\$)?(?:lld|ld|d|@|f)/g) ?? []).sort().join("|");
}

const catalogText = read(catalogPath);
let catalog;
try {
    catalog = JSON.parse(catalogText);
} catch (error) {
    errors.push(`Localizable.xcstrings is not valid JSON: ${error.message}`);
}

if (catalog) {
    if (catalog.sourceLanguage !== "en") errors.push("The string catalog source language must remain en.");
    const duplicateKeys = new Map();
    for (const match of catalogText.matchAll(/^ {4}("(?:\\.|[^"\\])*")\s*:/gm)) {
        const key = JSON.parse(match[1]);
        duplicateKeys.set(key, (duplicateKeys.get(key) ?? 0) + 1);
    }
    for (const [key, count] of duplicateKeys) {
        if (count > 1) errors.push(`Duplicate string-catalog key: ${key}`);
    }

    for (const [key, entry] of Object.entries(catalog.strings ?? {})) {
        const translation = entry.localizations?.["zh-Hans"]?.stringUnit;
        if (translation?.state !== "translated" || typeof translation.value !== "string") {
            errors.push(`Missing Simplified Chinese translation: ${key}`);
        } else if (formatTokens(key) !== formatTokens(translation.value)) {
            errors.push(`Format placeholders differ between source and translation: ${key}`);
        }
    }
}

const project = read(projectPath);
const definedIDs = [...project.matchAll(/^\s*([A-Z0-9]{24})(?:\s*\/\*.*?\*\/)?\s*=\s*\{/gm)]
    .filter((match) => {
        const close = project.indexOf("}", match.index);
        return /\bisa\s*=/.test(project.slice(match.index, close < 0 ? match.index + 500 : close));
    })
    .map((match) => match[1]);
const definedSet = new Set(definedIDs);
if (definedSet.size !== definedIDs.length) errors.push("The Xcode project contains duplicate object identifiers.");
for (const id of new Set(project.match(/\b[A-Z0-9]{24}\b/g) ?? [])) {
    if (!definedSet.has(id)) errors.push(`The Xcode project references an undefined object identifier: ${id}`);
}
for (const [description, pattern] of [
    ["Simplified Chinese project region", /knownRegions\s*=\s*\([^;]*"zh-Hans"/s],
    ["English InfoPlist localization path", /path = en\.lproj\/InfoPlist\.strings/],
    ["Simplified Chinese InfoPlist localization path", /path = "zh-Hans\.lproj\/InfoPlist\.strings"/],
]) {
    if (!pattern.test(project)) errors.push(`Xcode project is missing the ${description}.`);
}
for (const [phaseID, buildFileID, description] of [
    ["600000000000000000000001", "B00000000000000000000022", "AppLocalization.swift source build phase entry"],
    ["700000000000000000000001", "B00000000000000000000023", "Localizable.xcstrings resource build phase entry"],
    ["700000000000000000000001", "B00000000000000000000024", "InfoPlist.strings resource build phase entry"],
]) {
    const phase = project.match(new RegExp(`${phaseID}[^=]*=\\s*\\{[\\s\\S]*?files\\s*=\\s*\\(([\\s\\S]*?)\\);`));
    if (!phase?.[1]?.includes(buildFileID)) errors.push(`Xcode app target is missing the ${description}.`);
}

for (const locale of ["en", "zh-Hans"]) {
    const path = join(resourceRoot, `${locale}.lproj`, "InfoPlist.strings");
    const text = read(path);
    const entries = [...text.matchAll(/^\s*"([^"\n]+)"\s*=\s*"((?:\\.|[^"\\])*)";\s*$/gm)];
    const keys = entries.map((match) => match[1]).sort();
    const nonemptyLines = text.split(/\r?\n/).filter((line) => line.trim().length > 0);
    if (entries.length !== 3 || entries.length !== nonemptyLines.length) errors.push(`${locale}.lproj/InfoPlist.strings must contain exactly three valid entries.`);
    if (new Set(keys).size !== keys.length) errors.push(`${locale}.lproj/InfoPlist.strings contains duplicate keys.`);
    if (keys.join("|") !== ["CFBundleDisplayName", "CFBundleName", "NSFaceIDUsageDescription"].sort().join("|")) {
        errors.push(`${locale}.lproj/InfoPlist.strings is missing a required metadata key.`);
    }
}

const localizedSourceKeys = new Set();
// The project is hand-managed, so scan Swift string literals directly rather than relying on Xcode extraction.
function scanSwiftFiles(directory) {
    for (const name of readdirSync(directory)) {
        const path = join(directory, name);
        if (statSync(path).isDirectory()) {
            scanSwiftFiles(path);
            continue;
        }
        if (!name.endsWith(".swift")) continue;
        const text = read(path);
        for (const match of text.matchAll(/"((?:\\.|[^"\\])*)"/g)) {
            const key = decodeSwiftString(match[1]);
            const prefix = text.slice(Math.max(0, match.index - 180), match.index);
            const lineStart = text.lastIndexOf("\n", match.index) + 1;
            const lineEnd = text.indexOf("\n", match.index);
            const line = text.slice(lineStart, lineEnd < 0 ? text.length : lineEnd);
            // Stable automation identifiers are never presented or translated.
            if (/\.accessibilityIdentifier\s*\(\s*$/.test(prefix)) continue;
            if (/logger\.|Logger\(/.test(line) || /return\s+String\(format:/.test(line)) continue;
            if (key.length < 2 || key === "[]" || key.trim() === "·" || key === "99+" || key === "—") continue;
            if (/^\\\([^)]*\)$/.test(match[1])) continue;
            if (/^[a-z]+(?:\.[a-z0-9]+)*$/.test(key) && /(?:systemImage|systemName|symbol)\s*:\s*[^,)]*$/.test(text.slice(Math.max(0, match.index - 100), match.index))) continue;
            const directLocalization = /AppLocalization\.(?:string|format)\s*\(/.test(prefix);
            const swiftUIContext = /(?:Text|Label|Button|Picker|Toggle|ContentUnavailableView|EmptyStateCard|sectionTitle|settingsCard|infoCard|summaryTile)\s*\([^)]*$/.test(prefix)
                || /\.(?:navigationTitle|confirmationDialog|alert|searchable|accessibilityLabel|accessibilityHint)\s*\([^)]*$/.test(prefix);
            const enumRawValue = /^\s*case\s+\w+\s*=/.test(line);
            const builtInDisplayValue = /builtInTags/.test(line);
            if (!key.includes(" ") && !directLocalization && !swiftUIContext && !enumRawValue && !builtInDisplayValue) continue;
            if (/^[a-z]+(?:\.[a-z0-9]+)+$/.test(key)) continue;
            if (catalog?.strings?.[key]) localizedSourceKeys.add(key);
            else errors.push(`Untranslated source string in ${relative(appRoot, path)}: ${key}`);
        }
    }
}

scanSwiftFiles(sourceRoot);

if (catalog) {
    for (const key of Object.keys(catalog.strings ?? {})) {
        if (!localizedSourceKeys.has(key)) errors.push(`Unused string-catalog entry: ${key}`);
    }
}

if (errors.length) {
    console.error(`Localization audit failed (${errors.length} issue${errors.length === 1 ? "" : "s"}):`);
    for (const error of errors) console.error(`- ${error}`);
    process.exitCode = 1;
} else {
    console.log(`Localization audit passed: ${localizedSourceKeys.size} source keys, en + zh-Hans metadata, and Xcode resource references.`);
}
