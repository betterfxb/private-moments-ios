import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const appRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const projectPath = join(appRoot, "PrivateMoments.xcodeproj", "project.pbxproj");
const schemePath = join(appRoot, "PrivateMoments.xcodeproj", "xcshareddata", "xcschemes", "PrivateMoments.xcscheme");
const errors = [];
const warnings = [];

function fail(message) {
    throw new Error(`${message} (offset ${index})`);
}

function parseOpenStep(text) {
    let index = text.startsWith("// !$*UTF8*$!") ? text.indexOf("\n") + 1 : 0;

    function skipTrivia() {
        while (index < text.length) {
            if (/\s/.test(text[index])) {
                index += 1;
            } else if (text.startsWith("//", index)) {
                const newline = text.indexOf("\n", index + 2);
                index = newline < 0 ? text.length : newline + 1;
            } else if (text.startsWith("/*", index)) {
                const end = text.indexOf("*/", index + 2);
                if (end < 0) fail("Unterminated OpenStep comment");
                index = end + 2;
            } else {
                break;
            }
        }
    }

    function readToken() {
        skipTrivia();
        if (index >= text.length) fail("Unexpected end of OpenStep project");
        if (text[index] === '"') {
            index += 1;
            let value = "";
            while (index < text.length) {
                const char = text[index++];
                if (char === '"') return value;
                if (char === "\\") {
                    if (index >= text.length) fail("Unterminated escape in quoted string");
                    const escaped = text[index++];
                    value += escaped === "n" ? "\n" : escaped === "r" ? "\r" : escaped === "t" ? "\t" : escaped;
                } else {
                    value += char;
                }
            }
            fail("Unterminated quoted string");
        }
        const start = index;
        while (index < text.length && !/[\s{}()=;,]/.test(text[index])) {
            if (text.startsWith("//", index) || text.startsWith("/*", index)) break;
            index += 1;
        }
        if (index === start) fail(`Unexpected token ${JSON.stringify(text[index])}`);
        return text.slice(start, index);
    }

    function parseValue() {
        skipTrivia();
        if (text[index] === "{") return parseDictionary();
        if (text[index] === "(") return parseArray();
        return readToken();
    }

    function parseDictionary() {
        index += 1;
        const result = Object.create(null);
        skipTrivia();
        while (text[index] !== "}") {
            const key = readToken();
            if (Object.hasOwn(result, key)) fail(`Duplicate dictionary key ${key}`);
            skipTrivia();
            if (text[index++] !== "=") fail(`Expected '=' after ${key}`);
            result[key] = parseValue();
            skipTrivia();
            if (text[index++] !== ";") fail(`Expected ';' after ${key}`);
            skipTrivia();
        }
        index += 1;
        return result;
    }

    function parseArray() {
        index += 1;
        const result = [];
        skipTrivia();
        while (text[index] !== ")") {
            result.push(parseValue());
            skipTrivia();
            if (text[index] === ",") {
                index += 1;
                skipTrivia();
            } else if (text[index] !== ")") {
                fail("Expected ',' or ')' in array");
            }
        }
        index += 1;
        return result;
    }

    const parsed = parseValue();
    skipTrivia();
    if (index !== text.length) fail("Unexpected trailing project content");
    return parsed;
}

function projectPathString(path) {
    return path.split(sep).join("/");
}

function listSwiftFiles(directory) {
    if (!existsSync(directory)) return [];
    const files = [];
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
        const path = join(directory, entry.name);
        if (entry.isDirectory()) files.push(...listSwiftFiles(path));
        else if (entry.isFile() && entry.name.endsWith(".swift")) files.push(projectPathString(relative(appRoot, path)));
    }
    return files.sort();
}

function assert(condition, message) {
    if (!condition) errors.push(message);
}

function valuesIn(value, callback) {
    if (typeof value === "string") callback(value);
    else if (Array.isArray(value)) value.forEach((entry) => valuesIn(entry, callback));
    else if (value && typeof value === "object") Object.values(value).forEach((entry) => valuesIn(entry, callback));
}

function configurationSettings(target, objects) {
    if (!target) return [];
    const list = objects[target.buildConfigurationList];
    if (!list || list.isa !== "XCConfigurationList") return [];
    return (list.buildConfigurations ?? []).map((id) => objects[id]).filter(Boolean);
}

function filesForPhase(phase, objects) {
    return (phase?.files ?? []).map((buildFileID) => {
        const buildFile = objects[buildFileID];
        return buildFile ? objects[buildFile.fileRef] : undefined;
    }).filter(Boolean);
}

function compareFileSets(label, expected, actual) {
    const expectedSet = new Set(expected);
    const actualSet = new Set(actual);
    for (const file of expectedSet) if (!actualSet.has(file)) errors.push(`${label} is missing ${file}.`);
    for (const file of actualSet) if (!expectedSet.has(file)) errors.push(`${label} references unexpected file ${file}.`);
}

let project;
try {
    project = parseOpenStep(readFileSync(projectPath, "utf8"));
} catch (error) {
    console.error(`Xcode project audit could not parse project.pbxproj: ${error.message}`);
    process.exit(1);
}

const objects = project.objects ?? Object.create(null);
const objectIDs = Object.keys(objects);
const objectIDSet = new Set(objectIDs);
assert(objectIDs.length > 0, "The Xcode project contains no objects.");
assert(objectIDSet.size === objectIDs.length, "The Xcode project contains duplicate object identifiers.");
for (const id of objectIDs) assert(/^[A-Z0-9]{24}$/.test(id), `Invalid Xcode object identifier: ${id}`);
valuesIn(objects, (value) => {
    if (/^[A-Z0-9]{24}$/.test(value) && !objectIDSet.has(value)) {
        errors.push(`The Xcode project references undefined object identifier ${value}.`);
    }
});

const projectObject = objects[project.rootObject];
assert(projectObject?.isa === "PBXProject", "The project rootObject does not resolve to a PBXProject.");
const targets = (projectObject?.targets ?? []).map((id) => objects[id]).filter(Boolean);
const appTarget = targets.find((target) => target.name === "PrivateMoments");
const testTarget = targets.find((target) => target.name === "PrivateMomentsTests");
const uiTestTarget = targets.find((target) => target.name === "PrivateMomentsUITests");
const appTargetID = appTarget ? Object.keys(objects).find((id) => objects[id] === appTarget) : "";
const testTargetID = testTarget ? Object.keys(objects).find((id) => objects[id] === testTarget) : "";
const uiTestTargetID = uiTestTarget ? Object.keys(objects).find((id) => objects[id] === uiTestTarget) : "";
assert(Boolean(appTarget), "The PrivateMoments app target is missing.");
assert(Boolean(testTarget), "The PrivateMomentsTests target is missing.");
assert(Boolean(uiTestTarget), "The PrivateMomentsUITests target is missing.");
assert(appTarget?.productType === "com.apple.product-type.application", "PrivateMoments must be an application target.");
assert(testTarget?.productType === "com.apple.product-type.bundle.unit-test", "PrivateMomentsTests must be a unit-test bundle target.");
assert(uiTestTarget?.productType === "com.apple.product-type.bundle.ui-testing", "PrivateMomentsUITests must be a UI-testing bundle target.");

const phaseByID = Object.fromEntries(Object.entries(objects).filter(([, object]) => object?.isa?.endsWith("BuildPhase")));
const phaseFor = (target, isa) => (target?.buildPhases ?? []).map((id) => phaseByID[id]).find((phase) => phase?.isa === isa);
const appSourcesPhase = phaseFor(appTarget, "PBXSourcesBuildPhase");
const testSourcesPhase = phaseFor(testTarget, "PBXSourcesBuildPhase");
const uiTestSourcesPhase = phaseFor(uiTestTarget, "PBXSourcesBuildPhase");
const appResourcesPhase = phaseFor(appTarget, "PBXResourcesBuildPhase");
assert(Boolean(appSourcesPhase), "The app target has no Sources build phase.");
assert(Boolean(testSourcesPhase), "The test target has no Sources build phase.");
assert(Boolean(uiTestSourcesPhase), "The UI test target has no Sources build phase.");
assert(Boolean(appResourcesPhase), "The app target has no Resources build phase.");

const filePaths = new Map();
const visitedGroups = new Set();
function walkGroup(groupID, parentPath = "") {
    const group = objects[groupID];
    if (!group || visitedGroups.has(groupID)) return;
    visitedGroups.add(groupID);
    const sourceTree = group.sourceTree ?? "<group>";
    if (sourceTree === "BUILT_PRODUCTS_DIR" || sourceTree === "SDKROOT") return;
    const groupPath = group.isa === "PBXGroup" && group.path ? join(parentPath, group.path) : parentPath;
    if (group.isa === "PBXFileReference") {
        const path = group.path ?? group.name;
        if (path) filePaths.set(groupID, projectPathString(join(parentPath, path)));
        return;
    }
    if (group.isa === "PBXVariantGroup") {
        filePaths.set(groupID, projectPathString(join(parentPath, group.name ?? "")));
        for (const childID of group.children ?? []) walkGroup(childID, parentPath);
        return;
    }
    if (group.isa !== "PBXGroup") return;
    for (const childID of group.children ?? []) walkGroup(childID, groupPath);
}
walkGroup(projectObject?.mainGroup);

const appSourcePaths = filesForPhase(appSourcesPhase, objects).map((file) => filePaths.get(Object.keys(objects).find((id) => objects[id] === file)) ?? "");
const testSourcePaths = filesForPhase(testSourcesPhase, objects).map((file) => filePaths.get(Object.keys(objects).find((id) => objects[id] === file)) ?? "");
const uiTestSourcePaths = filesForPhase(uiTestSourcesPhase, objects).map((file) => filePaths.get(Object.keys(objects).find((id) => objects[id] === file)) ?? "");
compareFileSets("App Sources build phase", listSwiftFiles(join(appRoot, "Sources")), appSourcePaths);
compareFileSets("Test Sources build phase", listSwiftFiles(join(appRoot, "Tests")), testSourcePaths);
compareFileSets("UI Test Sources build phase", listSwiftFiles(join(appRoot, "UITests")), uiTestSourcePaths);

const appDependencies = (testTarget?.dependencies ?? []).map((id) => objects[id]).filter(Boolean);
assert(appDependencies.some((dependency) => dependency.target === appTargetID && dependency.targetProxy), "The test target does not depend on the app target.");
const uiTestDependencies = (uiTestTarget?.dependencies ?? []).map((id) => objects[id]).filter(Boolean);
assert(uiTestDependencies.some((dependency) => dependency.target === appTargetID && dependency.targetProxy), "The UI test target does not depend on the app target.");

for (const config of configurationSettings(projectObject, objects)) {
    const conditions = String(config.buildSettings?.SWIFT_ACTIVE_COMPILATION_CONDITIONS ?? "").split(/\s+/);
    if (config.name === "Debug") assert(conditions.includes("DEBUG"), "Debug must enable the isolated UI-test store support.");
    if (config.name === "Release") assert(!conditions.includes("DEBUG"), "Release must exclude Debug-only UI-test store support.");
}

for (const config of configurationSettings(appTarget, objects)) {
    if (!["Debug", "Release"].includes(config.name)) continue;
    const settings = config.buildSettings ?? {};
    const label = `App ${config.name} configuration`;
    assert(Number.parseFloat(settings.IPHONEOS_DEPLOYMENT_TARGET) >= 17, `${label} must target iOS 17 or later.`);
    const platforms = String(settings.SUPPORTED_PLATFORMS ?? "").split(/\s+/);
    assert(platforms.includes("iphoneos") && platforms.includes("iphonesimulator"), `${label} must support device and simulator platforms.`);
    const deviceFamilies = String(settings.TARGETED_DEVICE_FAMILY ?? "").split(",");
    assert(deviceFamilies.includes("1") && deviceFamilies.includes("2"), `${label} must include iPhone and iPad device families.`);
    assert(settings.GENERATE_INFOPLIST_FILE === "YES", `${label} must generate an Info.plist.`);
    assert(settings.SWIFT_EMIT_LOC_STRINGS === "YES", `${label} must emit localization strings.`);
    assert(settings.ASSETCATALOG_COMPILER_APPICON_NAME === "AppIcon", `${label} must select the AppIcon asset catalog set.`);
    if (String(settings.PRODUCT_BUNDLE_IDENTIFIER ?? "").startsWith("com.example.")) {
        warnings.push(`${label} still uses placeholder bundle identifier ${settings.PRODUCT_BUNDLE_IDENTIFIER}.`);
    }
}

for (const config of configurationSettings(testTarget ?? {}, objects)) {
    if (!["Debug", "Release"].includes(config.name)) continue;
    const settings = config.buildSettings ?? {};
    assert(String(settings.TEST_HOST ?? "").includes("PrivateMoments.app/PrivateMoments"), `Tests ${config.name} configuration has an unexpected TEST_HOST.`);
}

for (const config of configurationSettings(uiTestTarget ?? {}, objects)) {
    if (!["Debug", "Release"].includes(config.name)) continue;
    const settings = config.buildSettings ?? {};
    assert(settings.TEST_TARGET_NAME === "PrivateMoments", `UI tests ${config.name} configuration must target the PrivateMoments app.`);
}

const projectRegions = projectObject?.knownRegions ?? [];
assert(projectRegions.includes("en"), "The Xcode project is missing the en localization region.");
assert(projectRegions.includes("zh-Hans"), "The Xcode project is missing the zh-Hans localization region.");
const appResourceFiles = filesForPhase(appResourcesPhase, objects);
const appResourcePaths = appResourceFiles.map((file) => {
    const id = Object.keys(objects).find((objectID) => objects[objectID] === file);
    return filePaths.get(id) ?? "";
});
assert(appResourcePaths.some((path) => path.endsWith("Resources/Localizable.xcstrings")), "The app Resources build phase is missing Localizable.xcstrings.");
assert(appResourcePaths.some((path) => path.endsWith("Resources/InfoPlist.strings")), "The app Resources build phase is missing the InfoPlist.strings variant group.");
assert(appResourcePaths.some((path) => path.endsWith("Resources/PrivacyInfo.xcprivacy")), "The app Resources build phase is missing PrivacyInfo.xcprivacy.");
assert(appResourcePaths.some((path) => path.endsWith("Resources/Assets.xcassets")), "The app Resources build phase is missing Assets.xcassets.");
for (const locale of ["en", "zh-Hans"]) {
    const localizedPath = join(appRoot, "Resources", `${locale}.lproj`, "InfoPlist.strings");
    assert(existsSync(localizedPath) && statSync(localizedPath).isFile(), `Missing ${locale}.lproj/InfoPlist.strings.`);
}

const privacyManifestPath = join(appRoot, "Resources", "PrivacyInfo.xcprivacy");
let privacyManifest = "";
try {
    privacyManifest = readFileSync(privacyManifestPath, "utf8");
} catch (error) {
    errors.push(`Cannot read Resources/PrivacyInfo.xcprivacy: ${error.message}`);
}
for (const [apiType, reason] of [
    ["NSPrivacyAccessedAPICategoryFileTimestamp", "3B52.1"],
    ["NSPrivacyAccessedAPICategoryUserDefaults", "CA92.1"],
]) {
    const escapedType = apiType.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const escapedReason = reason.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const declaration = new RegExp(`<dict>\\s*<key>NSPrivacyAccessedAPIType</key>\\s*<string>${escapedType}</string>\\s*<key>NSPrivacyAccessedAPITypeReasons</key>\\s*<array>[\\s\\S]*?<string>${escapedReason}</string>[\\s\\S]*?</array>\\s*</dict>`);
    assert(declaration.test(privacyManifest), `PrivacyInfo.xcprivacy is missing the ${apiType} reason ${reason}.`);
}
assert(/<key>NSPrivacyTracking<\/key>\s*<false\s*\/>/.test(privacyManifest), "PrivacyInfo.xcprivacy must declare that the app does not track users.");
assert(/<key>NSPrivacyCollectedDataTypes<\/key>\s*<array\s*\/>/.test(privacyManifest), "PrivacyInfo.xcprivacy must declare no app-collected data types for the local-only build.");
assert(/<key>NSPrivacyTrackingDomains<\/key>\s*<array\s*\/>/.test(privacyManifest), "PrivacyInfo.xcprivacy should contain no tracking domains when tracking is disabled.");

const appIconSetPath = join(appRoot, "Resources", "Assets.xcassets", "AppIcon.appiconset");
let assetCatalogContents;
try {
    assetCatalogContents = JSON.parse(readFileSync(join(appRoot, "Resources", "Assets.xcassets", "Contents.json"), "utf8"));
} catch (error) {
    errors.push(`Assets.xcassets/Contents.json is not valid JSON: ${error.message}`);
}
assert(assetCatalogContents?.info?.author === "xcode" && assetCatalogContents?.info?.version === 1, "Assets.xcassets/Contents.json is missing valid catalog metadata.");
const appIconContentsPath = join(appIconSetPath, "Contents.json");
let appIconContents;
try {
    appIconContents = JSON.parse(readFileSync(appIconContentsPath, "utf8"));
} catch (error) {
    errors.push(`AppIcon.appiconset/Contents.json is not valid JSON: ${error.message}`);
}
const appIconImage = appIconContents?.images?.find((image) => image.idiom === "universal" && image.platform === "ios" && image.size === "1024x1024");
assert(Boolean(appIconImage?.filename), "The AppIcon asset set must contain a universal 1024x1024 iOS image.");
if (appIconImage?.filename) {
    const appIconPath = join(appIconSetPath, appIconImage.filename);
    try {
        const png = readFileSync(appIconPath);
        const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
        assert(png.subarray(0, 8).equals(signature), "The AppIcon image is not a PNG file.");
        assert(png.subarray(12, 16).toString("ascii") === "IHDR", "The AppIcon PNG is missing its IHDR header.");
        if (png.subarray(12, 16).toString("ascii") === "IHDR") {
            assert(png.readUInt32BE(16) === 1024 && png.readUInt32BE(20) === 1024, "The AppIcon PNG must be exactly 1024x1024 pixels.");
            assert(png[25] === 2, "The AppIcon PNG must use opaque RGB color without an alpha channel.");
        }
    } catch (error) {
        errors.push(`Cannot read AppIcon PNG: ${error.message}`);
    }
}

let scheme = "";
try {
    scheme = readFileSync(schemePath, "utf8");
} catch (error) {
    errors.push(`Cannot read shared Xcode scheme: ${error.message}`);
}
const schemeIDs = [...scheme.matchAll(/BlueprintIdentifier\s*=\s*"([A-Z0-9]{24})"/g)].map((match) => match[1]);
assert(schemeIDs.includes(appTargetID), "The shared scheme does not reference the app target.");
assert(schemeIDs.includes(testTargetID), "The shared scheme does not reference the test target.");
assert(schemeIDs.includes(uiTestTargetID), "The shared scheme does not reference the UI test target.");
assert(/<TestAction\b/.test(scheme) && /<Testables>/.test(scheme), "The shared scheme does not expose a test action.");
assert(/<LaunchAction\b/.test(scheme), "The shared scheme does not expose a launch action.");

if (errors.length) {
    console.error(`Xcode project audit failed (${errors.length} issue${errors.length === 1 ? "" : "s"}):`);
    for (const error of errors) console.error(`- ${error}`);
    if (warnings.length) for (const warning of warnings) console.warn(`Warning: ${warning}`);
    process.exitCode = 1;
} else {
    console.log(`Xcode project audit passed: ${objectIDs.length} objects; app/test targets, source membership, resources, configurations, privacy declarations, app icon, and shared scheme are consistent.`);
    for (const warning of warnings) console.warn(`Warning: ${warning}`);
}
