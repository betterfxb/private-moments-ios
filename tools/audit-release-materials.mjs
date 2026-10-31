import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const appRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];
const warnings = [];

function read(path, label) {
    try {
        return readFileSync(path, "utf8");
    } catch (error) {
        errors.push(`Cannot read ${label}: ${error.message}`);
        return "";
    }
}

function characterCount(value) {
    return Array.from(value).length;
}

function assert(condition, message) {
    if (!condition) errors.push(message);
}

function localizedDisplayName(locale) {
    const path = join(appRoot, "Resources", `${locale}.lproj`, "InfoPlist.strings");
    const content = read(path, `${locale}.lproj/InfoPlist.strings`);
    const match = content.match(/"CFBundleDisplayName"\s*=\s*"((?:\\.|[^"\\])*)"\s*;/);
    return match?.[1]?.replace(/\\"/g, '"').replace(/\\\\/g, "\\") ?? "";
}

const metadataPath = join(appRoot, "release", "APP-STORE-METADATA.json");
let metadata = {};
try {
    metadata = JSON.parse(read(metadataPath, "release/APP-STORE-METADATA.json"));
} catch (error) {
    errors.push(`APP-STORE-METADATA.json is not valid JSON: ${error.message}`);
}

const requiredLocales = ["en", "zh-Hans"];
assert(requiredLocales.every((locale) => metadata[locale]), "Store metadata must include en and zh-Hans.");
for (const locale of requiredLocales) {
    const listing = metadata[locale];
    if (!listing) continue;
    for (const field of ["name", "subtitle", "promotionalText", "description", "keywords"]) {
        assert(typeof listing[field] === "string" && listing[field].trim().length > 0, `${locale} metadata is missing ${field}.`);
    }
    if (typeof listing.name === "string") {
        const count = characterCount(listing.name);
        assert(count >= 2 && count <= 30, `${locale} app name must contain 2–30 characters; found ${count}.`);
        assert(listing.name === localizedDisplayName(locale), `${locale} store name does not match the app display name in InfoPlist.strings.`);
    }
    for (const [field, limit] of [["subtitle", 30], ["promotionalText", 170], ["description", 4000], ["keywords", 100]]) {
        if (typeof listing[field] !== "string") continue;
        const count = characterCount(listing[field]);
        assert(count <= limit, `${locale} ${field} exceeds ${limit} characters (${count}).`);
    }
    if (typeof listing.keywords === "string") {
        const keywords = listing.keywords.split(",");
        assert(keywords.every((keyword) => keyword.trim() === keyword && keyword.length > 0), `${locale} keywords must be non-empty comma-separated terms without surrounding spaces.`);
        const normalized = keywords.map((keyword) => keyword.toLocaleLowerCase(locale));
        assert(new Set(normalized).size === normalized.length, `${locale} keyword list contains duplicates.`);
    }
}

const policy = read(join(appRoot, "release", "PRIVACY-POLICY-DRAFT.md"), "release/PRIVACY-POLICY-DRAFT.md");
const reviewNotes = read(join(appRoot, "release", "APP-REVIEW-NOTES.md"), "release/APP-REVIEW-NOTES.md");
const releaseChecklist = read(join(appRoot, "release", "RELEASE-CHECKLIST.md"), "release/RELEASE-CHECKLIST.md");
const settingsSource = read(join(appRoot, "Sources", "Features", "Settings", "SettingsView.swift"), "SettingsView.swift");
const privacyViewPath = join(appRoot, "Sources", "Features", "Settings", "PrivacyInformationView.swift");

assert(existsSync(privacyViewPath), "The in-app localized privacy information screen is missing.");
assert(settingsSource.includes("PrivacyInformationView()"), "Settings does not link to the in-app privacy information screen.");
for (const field of ["Publisher/legal name", "Privacy contact", "Public HTTPS policy URL", "Effective date"]) {
    assert(policy.includes(field), `Privacy policy draft is missing the ${field} field.`);
}
if (/\[(?:Developer|Privacy|URL|Date|隐私|填写|Host)[^\]]*\]/i.test(policy)) {
    warnings.push("The privacy policy still contains publisher-supplied fields; it is not ready to publish.");
}
if (/\[(?:Host|Developer|Age|Build|App Review|Check)[^\]]*\]/i.test(reviewNotes)) {
    warnings.push("App Review Notes still contain build, contact, URL, or account-dependent fields.");
}
if (!/privacy-policy URL|privacy policy URL/i.test(releaseChecklist) || !/in-app privacy entry/i.test(releaseChecklist)) {
    errors.push("The release checklist must keep the public privacy-policy URL and in-app policy link as explicit gates.");
}

if (errors.length) {
    console.error(`Release materials audit failed (${errors.length} issue${errors.length === 1 ? "" : "s"}):`);
    for (const error of errors) console.error(`- ${error}`);
    for (const warning of warnings) console.warn(`Warning: ${warning}`);
    process.exitCode = 1;
} else {
    console.log("Release materials audit passed for en + zh-Hans:");
    for (const locale of requiredLocales) {
        const listing = metadata[locale];
        console.log(`- ${locale}: name ${characterCount(listing.name)}/30; subtitle ${characterCount(listing.subtitle)}/30; promo ${characterCount(listing.promotionalText)}/170; description ${characterCount(listing.description)}/4000; keywords ${characterCount(listing.keywords)}/100.`);
    }
    for (const warning of warnings) console.warn(`Warning: ${warning}`);
}
