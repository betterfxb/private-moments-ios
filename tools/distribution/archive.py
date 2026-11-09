"""Build and inspect real Release iOS-device archives, never a renamed simulator IPA."""

import hashlib
import json
import os
import plistlib
import re
import shutil
import zipfile
from pathlib import Path

from .configuration import DistributionError, ROOT, validate_versions
from .native import run


def read_plist(path, environment=None):
    try:
        return plistlib.loads(Path(path).read_bytes())
    except plistlib.InvalidFileException:
        # Xcode can preserve the OpenStep format of localized .strings files.
        data = run(["plutil", "-convert", "xml1", "-o", "-", str(path)], "Read compiled localized metadata", capture=True, environment=environment)
        return plistlib.loads(data)


def validate_app_info(info, policy, bundle_id, version, build):
    expected = {
        "CFBundleIdentifier": bundle_id,
        "CFBundleShortVersionString": version,
        "CFBundleVersion": build,
        "CFBundlePackageType": "APPL",
        "DTPlatformName": "iphoneos",
    }
    for key, value in expected.items():
        if info.get(key) != value:
            raise DistributionError(f"Archived app metadata does not match expected {key}.")
    if info.get("CFBundleSupportedPlatforms") != ["iPhoneOS"]:
        raise DistributionError("Archive must target a real iOS device, not Simulator.")
    if set(info.get("UIDeviceFamily", [])) != {1, 2}:
        raise DistributionError("Archived app must retain iPhone and iPad support.")
    sdk = re.fullmatch(r"iphoneos(\d+(?:\.\d+)*)", info.get("DTSDKName", ""))
    if not sdk or int(sdk.group(1).split(".")[0]) < policy["minimumIOSSDKMajor"]:
        raise DistributionError("Archived app was built with an unsupported iOS SDK.")
    xcode = info.get("DTXcode", "")
    if not re.fullmatch(r"\d{4,}", xcode) or int(xcode) < 2600:
        raise DistributionError("Archived app must be built with Xcode 26 or newer.")
    if info.get("MinimumOSVersion") != policy["minimumDeploymentTarget"]:
        raise DistributionError("Archive changed the app's minimum supported iOS version.")


def archive_application(archive_path):
    metadata = read_plist(archive_path / "Info.plist")
    relative = metadata.get("ApplicationProperties", {}).get("ApplicationPath", "")
    products = (archive_path / "Products").resolve()
    application = (products / relative).resolve()
    if not relative or not application.is_relative_to(products) or application.suffix != ".app" or not application.is_dir():
        raise DistributionError("Archive has no valid application inside Products.")
    return application


def inspect_resources(application, info, policy, metadata, environment=None):
    if not (application / "Assets.car").is_file() or (application / "Assets.car").stat().st_size == 0:
        raise DistributionError("Compiled asset catalog is missing from the archive.")
    icon = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon", {})
    if icon.get("CFBundleIconName") != "AppIcon":
        raise DistributionError("Archived app does not declare the expected AppIcon.")
    manifest = read_plist(application / "PrivacyInfo.xcprivacy", environment)
    if manifest.get("NSPrivacyTracking") is not False or manifest.get("NSPrivacyCollectedDataTypes") != []:
        raise DistributionError("Archived privacy manifest differs from the local-only product policy.")
    if manifest.get("NSPrivacyTrackingDomains") != []:
        raise DistributionError("Tracking domains are not expected in this archive.")
    reasons = {item["NSPrivacyAccessedAPIType"]: set(item["NSPrivacyAccessedAPITypeReasons"]) for item in manifest.get("NSPrivacyAccessedAPITypes", [])}
    for category, reason in [("NSPrivacyAccessedAPICategoryFileTimestamp", "3B52.1"), ("NSPrivacyAccessedAPICategoryUserDefaults", "CA92.1")]:
        if reason not in reasons.get(category, set()):
            raise DistributionError(f"Archived privacy manifest is missing {category} reason {reason}.")
    for locale in policy["locales"]:
        directory = application / f"{locale}.lproj"
        if not (directory / "Localizable.strings").is_file():
            raise DistributionError(f"Archived UI strings are missing for {locale}.")
        localized = read_plist(directory / "InfoPlist.strings", environment)
        if localized.get("CFBundleDisplayName") != metadata[locale]["name"] or not localized.get("NSFaceIDUsageDescription"):
            raise DistributionError(f"Archived display name / Face ID purpose text is incomplete for {locale}.")
    if list(application.rglob("*.xctest")) or list(application.rglob("*.p8")) or list(application.rglob("*.p12")):
        raise DistributionError("Archive must not contain tests or private signing material.")


def inspect_archive(archive_path, policy, bundle_id, version, build, environment, signed=False):
    application = archive_application(archive_path)
    info = read_plist(application / "Info.plist")
    validate_app_info(info, policy, bundle_id, version, build)
    store_metadata = json.loads((ROOT / "release" / "APP-STORE-METADATA.json").read_text(encoding="utf-8"))
    inspect_resources(application, info, policy, store_metadata, environment)
    executable_name = info.get("CFBundleExecutable", "")
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", executable_name):
        raise DistributionError("Archived executable name is invalid.")
    executable = application / executable_name
    contents = executable.read_bytes()
    if any(marker in contents for marker in (b"-pm-ui-test-store", b"PrivateMoments-UITests")):
        raise DistributionError("A Debug-only UI-test store hook leaked into the Release executable.")
    architectures = run(["xcrun", "lipo", "-archs", str(executable)], "Inspect device architectures", capture=True, environment=environment).decode().split()
    platform = run(["xcrun", "vtool", "-show-build", str(executable)], "Inspect Mach-O platform", capture=True, environment=environment).decode()
    if "arm64" not in architectures or any(item in architectures for item in ("x86_64", "i386")) or not re.search(r"platform\s+IOS\s", platform):
        raise DistributionError("Archived executable is not an arm64 iOS-device build.")
    profile_present = (application / "embedded.mobileprovision").is_file()
    if profile_present != signed:
        raise DistributionError("Archive provisioning state does not match the requested build mode.")
    symbols = archive_path / "dSYMs" / f"{policy['product']}.app.dSYM"
    if not symbols.is_dir():
        raise DistributionError("Release archive is missing the app dSYM.")
    if signed:
        run(["codesign", "--verify", "--deep", "--strict", str(application)], "Verify signed application", capture=True, environment=environment)
        entitlements = plistlib.loads(run(["codesign", "-d", "--entitlements", ":-", str(application)], "Inspect signed application entitlements", capture=True, environment=environment))
        if entitlements.get("get-task-allow", False) or not entitlements.get("application-identifier", "").endswith("." + bundle_id):
            raise DistributionError("Signed archive has unexpected development entitlements or application identity.")
    return {
        "bundleIdentifier": bundle_id, "version": version, "build": build,
        "devicePlatform": info["DTPlatformName"], "sdk": info["DTSDKName"],
        "minimumOSVersion": info["MinimumOSVersion"], "architectures": architectures,
        "locales": policy["locales"], "privacyManifestVerified": True,
        "appIconVerified": True, "debugTestStoreHookAbsent": True,
        "dSYMPresent": True, "provisioningProfilePresent": profile_present,
    }


def build_archive(output, policy, bundle_id, version, build, environment, signing_settings=()):
    validate_versions(version, build)
    if output.exists() and any(output.iterdir()):
        raise DistributionError("Output directory is not empty; choose a new directory to preserve prior artifacts.")
    output.mkdir(parents=True, exist_ok=True)
    archive_path = output / f"{policy['product']}.xcarchive"
    arguments = [
        "xcodebuild", "-project", str(ROOT / "PrivateMoments.xcodeproj"),
        "-scheme", policy["scheme"], "-configuration", "Release",
        "-destination", "generic/platform=iOS", "-archivePath", str(archive_path),
        "-derivedDataPath", str(output / "DerivedData"),
        f"MARKETING_VERSION={version}", f"CURRENT_PROJECT_VERSION={build}",
        f"PRODUCT_BUNDLE_IDENTIFIER={bundle_id}", "SKIP_INSTALL=NO",
        "DEBUG_INFORMATION_FORMAT=dwarf-with-dsym",
    ]
    arguments.extend(signing_settings or ["CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY="])
    run(arguments + ["archive"], "Create Release iOS-device archive", environment=environment)
    return archive_path


def save_report(output, report):
    artifacts = output / "artifacts"
    artifacts.mkdir(exist_ok=True)
    (artifacts / "distribution-report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as destination:
            destination.write(f"### {report['mode']}\n\nSDK: {report['sdk']} · version {report['version']} ({report['build']})\n\n")
            destination.write("Unsigned archive verified; **not installable, not TestFlight-ready, no upload performed.**\n" if report["mode"] == "unsigned-development" else "Upload accepted by the native tool; Apple processing and tester availability still require confirmation.\n")


def package_unsigned(output, policy, version, build, environment, toolchain_info):
    bundle_id = policy["unsignedBundleIdentifier"]
    archive_path = build_archive(output, policy, bundle_id, version, build, environment)
    report = inspect_archive(archive_path, policy, bundle_id, version, build, environment)
    artifacts = output / "artifacts"
    artifacts.mkdir()
    destination = artifacts / f"{policy['product']}-UNSIGNED.xcarchive.zip"
    run(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(archive_path), str(destination)], "Package unsigned development archive", environment=environment)
    report.update({
        "schemaVersion": 1, "mode": "unsigned-development", "archiveValidationPassed": True,
        "testflightReady": False, "uploaded": False, "signingPathEndToEndVerified": False,
        "sourceCommit": os.environ.get("GITHUB_SHA", "local"), "toolchain": toolchain_info,
        "archiveFile": destination.name, "archiveSHA256": hashlib.sha256(destination.read_bytes()).hexdigest(),
    })
    save_report(output, report)
    return report


def validate_exported_ipa(ipa, bundle_id, version, build):
    with zipfile.ZipFile(ipa) as package:
        candidates = [name for name in package.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info.plist", name)]
        if len(candidates) != 1:
            raise DistributionError("Exported IPA does not contain exactly one main application.")
        info = plistlib.loads(package.read(candidates[0]))
        if (info.get("CFBundleIdentifier"), info.get("CFBundleShortVersionString"), info.get("CFBundleVersion")) != (bundle_id, version, build):
            raise DistributionError("Exported IPA identity differs from the validated archive.")
        profile = candidates[0].removesuffix("Info.plist") + "embedded.mobileprovision"
        if profile not in package.namelist():
            raise DistributionError("Exported IPA has no distribution provisioning profile.")


def package_testflight(output, policy, version, build, environment, toolchain_info, material):
    bundle_id = material["bundleID"]
    archive_path = build_archive(output, policy, bundle_id, version, build, environment, material["archiveSettings"])
    report = inspect_archive(archive_path, policy, bundle_id, version, build, environment, signed=True)
    export_options = {
        "method": "app-store-connect", "destination": "export", "signingStyle": "manual",
        "teamID": material["teamID"], "signingCertificate": "Apple Distribution",
        "provisioningProfiles": {bundle_id: material["profileUUID"]},
        "manageAppVersionAndBuildNumber": False, "uploadSymbols": True,
    }
    options_file = material["workingDirectory"] / "ExportOptions.plist"
    options_file.write_bytes(plistlib.dumps(export_options))
    exported = output / "ExportedIPA"
    run(["xcodebuild", "-exportArchive", "-archivePath", str(archive_path), "-exportPath", str(exported), "-exportOptionsPlist", str(options_file)], "Export distribution-signed IPA", environment=environment)
    packages = list(exported.glob("*.ipa"))
    if len(packages) != 1:
        raise DistributionError("Expected exactly one exported IPA.")
    ipa = packages[0]
    validate_exported_ipa(ipa, bundle_id, version, build)
    authentication = ["--apiKey", environment["PM_ASC_KEY_ID"], "--apiIssuer", environment["PM_ASC_ISSUER_ID"]]
    for operation, label in [("--validate-app", "Validate IPA with App Store Connect"), ("--upload-app", "Upload build to App Store Connect")]:
        run(["xcrun", "altool", operation, "--file", str(ipa), "--type", "ios", *authentication], label, environment=environment, cwd=material["workingDirectory"])
    artifacts = output / "artifacts"
    artifacts.mkdir()
    shutil.copyfile(ipa, artifacts / ipa.name)
    run(["ditto", "-c", "-k", "--keepParent", str(archive_path / "dSYMs"), str(artifacts / "dSYMs.zip")], "Preserve symbol files", environment=environment)
    report.update({
        "schemaVersion": 1, "mode": "testflight-upload", "archiveValidationPassed": True,
        "uploaded": True, "uploadAccepted": True, "appleProcessingVerified": False,
        "testerAvailabilityVerified": False, "sourceCommit": os.environ.get("GITHUB_SHA", "local"),
        "toolchain": toolchain_info, "ipaSHA256": hashlib.sha256(ipa.read_bytes()).hexdigest(),
    })
    save_report(output, report)
    return report
