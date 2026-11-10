"""Behavioral checks for packaging guards; no Apple account or native signing required."""

import base64
import copy
import datetime as dt
import hashlib
import json
import plistlib
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock

from distribution.archive import archive_application, inspect_archive, validate_app_info, validate_exported_ipa
from distribution.configuration import DistributionError, decode_secret, load_policy, validate_bundle_id, validate_profile, validate_upload_configuration, validate_versions
from distribution.native import choose_simulator, prepare_simulator, run
from distribution.signing import signing_material


TEAM = "ABCDEFGHIJ"
BUNDLE = "org.example.tests.PrivateMoments"
PROFILE_ID = "12345678-1234-1234-1234-123456789012"
CERTIFICATE = b"Synthetic certificate fixture, not a real identity"


def upload_environment():
    return {
        "PM_TESTFLIGHT_UPLOAD_ENABLED": "true", "GITHUB_REF": "refs/heads/main",
        "PM_BUNDLE_ID": BUNDLE, "PM_APPLE_TEAM_ID": TEAM, "PM_ASC_KEY_ID": "12345ABCDE",
        "PM_ASC_ISSUER_ID": PROFILE_ID,
        "PM_DISTRIBUTION_P12_BASE64": base64.b64encode(b"synthetic p12").decode(),
        "PM_DISTRIBUTION_P12_PASSWORD": "synthetic-password",
        "PM_APPSTORE_PROFILE_BASE64": base64.b64encode(b"synthetic profile").decode(),
        "PM_ASC_PRIVATE_KEY_BASE64": base64.b64encode(b"-----BEGIN PRIVATE KEY-----\nsynthetic fixture\n-----END PRIVATE KEY-----").decode(),
    }


def distribution_profile():
    return {
        "UUID": PROFILE_ID, "ExpirationDate": dt.datetime(2090, 1, 1),
        "TeamIdentifier": [TEAM], "ApplicationIdentifierPrefix": [TEAM], "Platform": ["iOS"],
        "DeveloperCertificates": [CERTIFICATE],
        "Entitlements": {"application-identifier": f"{TEAM}.{BUNDLE}", "com.apple.developer.team-identifier": TEAM, "get-task-allow": False},
    }


def app_info():
    return {
        "CFBundleIdentifier": BUNDLE, "CFBundleShortVersionString": "0.1.0", "CFBundleVersion": "7.2",
        "CFBundlePackageType": "APPL", "DTPlatformName": "iphoneos", "DTSDKName": "iphoneos26.2",
        "DTXcode": "2620", "MinimumOSVersion": "17.0", "UIDeviceFamily": [1, 2],
        "CFBundleSupportedPlatforms": ["iPhoneOS"], "CFBundleExecutable": "PrivateMoments",
        "CFBundleDevelopmentRegion": "en",
        "CFBundleIcons": {"CFBundlePrimaryIcon": {"CFBundleIconName": "AppIcon"}},
    }


class DistributionGuardTests(unittest.TestCase):
    def test_simulator_selection_matches_sdk_and_prefers_compact_phone(self):
        inventory = {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [
                {"name": "iPhone 17 Pro", "isAvailable": True},
                {"name": "iPhone SE (3rd generation)", "isAvailable": True},
            ],
            "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [{"name": "iPhone 17", "isAvailable": True}],
        }
        device, runtime = choose_simulator(inventory, "26.2")
        self.assertEqual(device["name"], "iPhone SE (3rd generation)")
        self.assertTrue(runtime.endswith("26-2"))

    def test_missing_sdk_runtime_never_silently_uses_another_runtime(self):
        inventory = {"com.apple.CoreSimulator.SimRuntime.iOS-18-5": [{"name": "iPhone 16", "isAvailable": True}]}
        with self.assertRaises(DistributionError):
            choose_simulator(inventory, "26.2")

    def test_prepare_simulator_retains_xcode_destination_identifier(self):
        identifier = "ABCDEF12-1234-1234-1234-ABCDEF123456"
        inventory = {"devices": {"com.apple.CoreSimulator.SimRuntime.iOS-26-2": [{"name": "iPhone SE (3rd generation)", "isAvailable": True, "udid": identifier}]}}
        with tempfile.TemporaryDirectory() as temporary:
            environment_file = Path(temporary) / "github-env"
            with mock.patch("distribution.native.run", side_effect=[json.dumps(inventory).encode(), b"", b"", b""]) as native:
                prepare_simulator({"GITHUB_ENV": str(environment_file)}, {"iphoneOSSDK": "26.2"})
            self.assertIn(f"id={identifier}\n", environment_file.read_text(encoding="utf-8"))
            self.assertEqual(native.call_args_list[1].args[0], ["xcrun", "simctl", "bootstatus", identifier, "-b"])

    def test_versions_reject_injection_and_invalid_build_shapes(self):
        for version, build in [("0.1.0", "7.2"), ("1.0.1", "9999.99.99")]:
            self.assertEqual(validate_versions(version, build), (version, build))
        for version, build in [("1.0;echo", "1"), ("1.0.0", "$(secret)"), ("1.0.0", "10000"), ("1.0.0", "1.100"), ("1.0.0", "0"), ("1.0", "1")]:
            with self.subTest(version=version, build=build), self.assertRaises(DistributionError):
                validate_versions(version, build)

    def test_placeholder_is_allowed_only_for_unsigned_validation(self):
        self.assertEqual(validate_bundle_id("com.example.PrivateMoments", True), "com.example.PrivateMoments")
        for value in ["com.example.PrivateMoments", "bad bundle", "com.$(secret).app"]:
            with self.subTest(value=value), self.assertRaises(DistributionError):
                validate_bundle_id(value)

    def test_disabled_upload_never_touches_native_signing(self):
        with mock.patch("distribution.signing.run") as native:
            with self.assertRaisesRegex(DistributionError, "disabled"):
                with signing_material({}):
                    self.fail("Disabled uploads must not enter the signing context.")
            native.assert_not_called()

    def test_branch_and_missing_credentials_block_upload(self):
        complete = upload_environment()
        self.assertEqual(validate_upload_configuration(complete), BUNDLE)
        for field in ["PM_DISTRIBUTION_P12_BASE64", "PM_ASC_PRIVATE_KEY_BASE64", "PM_APPLE_TEAM_ID", "PM_ASC_ISSUER_ID"]:
            incomplete = dict(complete)
            incomplete.pop(field)
            with self.subTest(field=field), self.assertRaises(DistributionError):
                validate_upload_configuration(incomplete)
        with self.assertRaises(DistributionError):
            validate_upload_configuration(dict(complete, GITHUB_REF="refs/heads/feature"))

    def test_secret_decode_error_does_not_echo_input(self):
        with self.assertRaises(DistributionError) as caught:
            decode_secret({"SENSITIVE": "not-base64-secret!"}, "SENSITIVE")
        self.assertNotIn("not-base64-secret!", str(caught.exception))

    def test_profile_rejects_expiry_identity_and_distribution_mismatches(self):
        profile = distribution_profile()
        self.assertEqual(validate_profile(profile, BUNDLE, TEAM), {hashlib.sha1(CERTIFICATE).hexdigest().upper()})
        invalid_profiles = []
        for key, value in [("ExpirationDate", dt.datetime(2000, 1, 1)), ("TeamIdentifier", ["OTHERTEAMID"]), ("ProvisionedDevices", ["synthetic-device"]), ("ProvisionsAllDevices", True), ("Platform", ["macOS"]), ("UUID", "-" * 36), ("DeveloperCertificates", [])]:
            invalid = copy.deepcopy(profile)
            invalid[key] = value
            invalid_profiles.append(invalid)
        for key, value in [("application-identifier", TEAM + ".*"), ("get-task-allow", True)]:
            invalid = copy.deepcopy(profile)
            invalid["Entitlements"][key] = value
            invalid_profiles.append(invalid)
        for index, invalid in enumerate(invalid_profiles):
            with self.subTest(index=index), self.assertRaises(DistributionError):
                validate_profile(invalid, BUNDLE, TEAM)

    def test_native_errors_preserve_exit_code_and_redact_password(self):
        result = subprocess.CompletedProcess(["security"], 9, b"", b"wrong synthetic-password")
        with mock.patch("distribution.native.subprocess.run", return_value=result):
            with self.assertRaises(DistributionError) as caught:
                run(["security"], "Import fixture", capture=True, environment=upload_environment())
        self.assertIn("exit 9", str(caught.exception))
        self.assertIn("[redacted]", str(caught.exception))
        self.assertNotIn("synthetic-password", str(caught.exception))


class ArchiveValidationTests(unittest.TestCase):
    def setUp(self):
        self.policy = load_policy()
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.archive = self.root / "PrivateMoments.xcarchive"
        self.app = self.archive / "Products" / "Applications" / "PrivateMoments.app"
        self.app.mkdir(parents=True)
        (self.archive / "Info.plist").write_bytes(plistlib.dumps({"ApplicationProperties": {"ApplicationPath": "Applications/PrivateMoments.app"}}))
        (self.app / "Info.plist").write_bytes(plistlib.dumps(app_info()))
        (self.app / "PrivateMoments").write_bytes(b"synthetic binary")
        (self.app / "Assets.car").write_bytes(b"synthetic asset catalog")
        source = Path(__file__).resolve().parents[1]
        (self.app / "PrivacyInfo.xcprivacy").write_bytes((source / "Resources" / "PrivacyInfo.xcprivacy").read_bytes())
        metadata = json.loads((source / "release" / "APP-STORE-METADATA.json").read_text(encoding="utf-8"))
        for locale in self.policy["locales"]:
            directory = self.app / f"{locale}.lproj"
            directory.mkdir()
            (directory / "Localizable.strings").write_bytes(plistlib.dumps({"Done": "Synthetic translation"}))
            (directory / "InfoPlist.strings").write_bytes(plistlib.dumps({"CFBundleDisplayName": metadata[locale]["name"], "NSFaceIDUsageDescription": "Synthetic purpose"}))
        (self.archive / "dSYMs" / "PrivateMoments.app.dSYM").mkdir(parents=True)

    def native_metadata(self, arguments, *unused, **keywords):
        return b"arm64\n" if "lipo" in arguments else b"platform IOS\n"

    def inspect(self):
        with mock.patch("distribution.archive.run", side_effect=self.native_metadata):
            return inspect_archive(self.archive, self.policy, BUNDLE, "0.1.0", "7.2", {})

    def test_complete_device_archive_is_inspected(self):
        report = self.inspect()
        self.assertTrue(report["debugTestStoreHookAbsent"])
        self.assertEqual(report["architectures"], ["arm64"])

    def test_metadata_rejects_simulator_old_sdk_and_changed_identity(self):
        for key, value in [("DTPlatformName", "iphonesimulator"), ("DTSDKName", "iphoneos18.5"), ("DTXcode", "1640"), ("CFBundleVersion", "7.1"), ("UIDeviceFamily", [1]), ("MinimumOSVersion", "18.0")]:
            invalid = dict(app_info(), **{key: value})
            with self.subTest(key=key), self.assertRaises(DistributionError):
                validate_app_info(invalid, self.policy, BUNDLE, "0.1.0", "7.2")

    def test_archive_application_cannot_escape_products_directory(self):
        (self.root / "outside.app").mkdir()
        (self.archive / "Info.plist").write_bytes(plistlib.dumps({"ApplicationProperties": {"ApplicationPath": "../../outside.app"}}))
        with self.assertRaises(DistributionError):
            archive_application(self.archive)

    def test_missing_translation_blocks_archive(self):
        (self.app / "zh-Hans.lproj" / "Localizable.strings").unlink()
        with self.assertRaises(DistributionError):
            self.inspect()

    def test_source_language_can_use_development_keys_without_redundant_table(self):
        (self.app / "en.lproj" / "Localizable.strings").unlink()
        report = self.inspect()
        self.assertEqual(report["localizedUIResources"], {
            "en": "development-language-keys", "zh-Hans": "compiled-localizable-table",
        })

    def test_source_fallback_requires_matching_archive_development_language(self):
        (self.app / "en.lproj" / "Localizable.strings").unlink()
        info = dict(app_info(), CFBundleDevelopmentRegion="fr")
        (self.app / "Info.plist").write_bytes(plistlib.dumps(info))
        with self.assertRaises(DistributionError):
            self.inspect()

    def test_debug_store_hook_cannot_ship_in_release(self):
        for marker in [b"-pm-ui-test-store", b"PrivateMoments-UITests", b"-pm-ui-test-fail-save-once"]:
            with self.subTest(marker=marker):
                (self.app / "PrivateMoments").write_bytes(b"synthetic " + marker + b" binary")
                with self.assertRaises(DistributionError):
                    self.inspect()

    def test_private_signing_key_cannot_enter_app_bundle(self):
        (self.app / "private.p8").write_text("Synthetic fixture", encoding="utf-8")
        with self.assertRaises(DistributionError):
            self.inspect()

    def test_arm64_simulator_binary_is_rejected(self):
        with mock.patch("distribution.archive.run", side_effect=[b"arm64\n", b"platform IOSSIMULATOR\n"]):
            with self.assertRaises(DistributionError):
                inspect_archive(self.archive, self.policy, BUNDLE, "0.1.0", "7.2", {})

    def test_signed_profile_is_not_mislabelled_as_unsigned(self):
        (self.app / "embedded.mobileprovision").write_bytes(b"synthetic profile")
        with self.assertRaises(DistributionError):
            self.inspect()

    def test_exported_ipa_must_match_validated_archive(self):
        ipa = self.root / "PrivateMoments.ipa"
        with zipfile.ZipFile(ipa, "w") as package:
            package.writestr("Payload/PrivateMoments.app/Info.plist", plistlib.dumps(app_info()))
            package.writestr("Payload/PrivateMoments.app/embedded.mobileprovision", b"synthetic profile")
        validate_exported_ipa(ipa, BUNDLE, "0.1.0", "7.2")
        with self.assertRaises(DistributionError):
            validate_exported_ipa(ipa, BUNDLE, "0.1.0", "8.1")


class SigningCleanupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.runner = self.root / "runner"
        self.runner.mkdir()
        self.environment = dict(upload_environment(), RUNNER_TEMP=str(self.runner))
        self.calls = []
        self.patches = [
            mock.patch("distribution.signing.require_macos"),
            mock.patch("distribution.signing.Path.home", return_value=self.home),
            mock.patch("distribution.signing.run", side_effect=self.native),
        ]
        for patch in self.patches:
            patch.start()
            self.addCleanup(patch.stop)

    def native(self, arguments, *unused, **keywords):
        self.calls.append(arguments)
        if arguments == ["security", "list-keychains", "-d", "user"]:
            return b'"/synthetic/login.keychain-db"\n'
        if arguments[1] == "cms":
            return plistlib.dumps(distribution_profile())
        if arguments[1] == "find-identity":
            fingerprint = hashlib.sha1(CERTIFICATE).hexdigest().upper()
            return f'1) {fingerprint} "Synthetic distribution identity"\n'.encode()
        return b""

    def assert_cleaned(self):
        self.assertTrue(any(command[1] == "delete-keychain" for command in self.calls))
        self.assertEqual(list(self.home.rglob("*.mobileprovision")), [])
        self.assertEqual(list(self.runner.iterdir()), [])

    def test_build_failure_restores_search_list_and_removes_owned_files(self):
        with self.assertRaisesRegex(DistributionError, "Synthetic build failure"):
            with signing_material(self.environment) as material:
                self.assertEqual(material["bundleID"], BUNDLE)
                self.assertTrue(list(self.home.rglob("*.mobileprovision")))
                raise DistributionError("Synthetic build failure")
        self.assertIn(["security", "list-keychains", "-d", "user", "-s", "/synthetic/login.keychain-db"], self.calls)
        self.assert_cleaned()

    def test_import_failure_still_deletes_created_keychain(self):
        original = self.native

        def failing(arguments, *positional, **keywords):
            if arguments[1] == "import":
                raise DistributionError("Synthetic import failure")
            return original(arguments, *positional, **keywords)

        with mock.patch("distribution.signing.run", side_effect=failing):
            with self.assertRaisesRegex(DistributionError, "Synthetic import failure"):
                with signing_material(self.environment):
                    self.fail("Import failure must not yield signing state.")
        self.assert_cleaned()

    def test_existing_matching_profile_is_preserved(self):
        location = self.home / "Library" / "MobileDevice" / "Provisioning Profiles" / f"{PROFILE_ID}.mobileprovision"
        location.parent.mkdir(parents=True)
        location.write_bytes(b"synthetic profile")
        with signing_material(self.environment):
            self.assertTrue(location.exists())
        self.assertEqual(location.read_bytes(), b"synthetic profile")
        self.assertEqual(list(self.runner.iterdir()), [])

    def test_cleanup_failure_is_reported_after_other_cleanup_attempts(self):
        original = self.native

        def failing(arguments, *positional, **keywords):
            if arguments == ["security", "list-keychains", "-d", "user", "-s", "/synthetic/login.keychain-db"]:
                raise DistributionError("Synthetic restore failure")
            return original(arguments, *positional, **keywords)

        with mock.patch("distribution.signing.run", side_effect=failing):
            with self.assertRaisesRegex(DistributionError, "Signing cleanup failed"):
                with signing_material(self.environment):
                    pass
        self.assert_cleaned()


if __name__ == "__main__":
    unittest.main()
