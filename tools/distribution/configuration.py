"""Validate build identity and explicit opt-in before touching signing material."""

import base64
import binascii
import datetime as dt
import hashlib
import json
import re
from pathlib import Path


class DistributionError(RuntimeError):
    """A configuration, native-tool or artifact validation failure."""


ROOT = Path(__file__).resolve().parents[2]
POLICY_PATH = ROOT / "release" / "distribution-config.json"
SIGNING_SECRETS = (
    "PM_DISTRIBUTION_P12_BASE64",
    "PM_DISTRIBUTION_P12_PASSWORD",
    "PM_APPSTORE_PROFILE_BASE64",
    "PM_ASC_PRIVATE_KEY_BASE64",
)


def load_policy():
    policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    if policy.get("schemaVersion") != 1:
        raise DistributionError("Unsupported distribution policy schema.")
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", policy.get("xcodeVersion", "")):
        raise DistributionError("Policy xcodeVersion must be a stable numeric version.")
    if not isinstance(policy.get("minimumIOSSDKMajor"), int) or policy["minimumIOSSDKMajor"] < 26:
        raise DistributionError("Distribution policy must require iOS SDK 26 or newer.")
    if int(policy["xcodeVersion"].split(".")[0]) < 26:
        raise DistributionError("Distribution policy must select Xcode 26 or newer.")
    for key in ("scheme", "product"):
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", policy.get(key, "")):
            raise DistributionError(f"Invalid distribution policy field: {key}.")
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", policy.get("minimumDeploymentTarget", "")):
        raise DistributionError("Policy minimumDeploymentTarget is invalid.")
    if policy.get("locales") != ["en", "zh-Hans"]:
        raise DistributionError("Distribution policy must inspect both current app locales.")
    validate_bundle_id(policy.get("unsignedBundleIdentifier", ""), allow_placeholder=True)
    return policy


def validate_versions(version, build):
    if not re.fullmatch(r"\d{1,4}\.\d{1,4}\.\d{1,4}", version):
        raise DistributionError("Version must contain three numeric components (for example 0.1.0).")
    # CFBundleVersion: up to 4 digits in the first component and 2 in the others.
    if not re.fullmatch(r"[1-9]\d{0,3}(?:\.(?:0|[1-9]\d?)){0,2}", build):
        raise DistributionError("Build must be a positive 1–4 digit component followed by at most two 0–99 components.")
    return version, build


def validate_bundle_id(bundle_id, allow_placeholder=False):
    if not re.fullmatch(r"[A-Za-z0-9]+(?:\.[A-Za-z0-9-]+){2,}", bundle_id):
        raise DistributionError("Bundle ID must be a reverse-domain identifier without whitespace or build substitutions.")
    if not allow_placeholder and bundle_id.lower().startswith(("com.example.", "com.yourcompany.")):
        raise DistributionError("A registered non-placeholder Bundle ID is required for TestFlight.")
    return bundle_id


def validate_upload_configuration(environment, require_secrets=True):
    if environment.get("PM_TESTFLIGHT_UPLOAD_ENABLED") != "true":
        raise DistributionError("TestFlight upload is disabled. Development-only users should run iOS development archive.")
    if environment.get("GITHUB_REF") != "refs/heads/main":
        raise DistributionError("TestFlight uploads are limited to the main branch.")
    bundle_id = validate_bundle_id(environment.get("PM_BUNDLE_ID", ""))
    for name in ("PM_APPLE_TEAM_ID", "PM_ASC_KEY_ID"):
        if not re.fullmatch(r"[A-Z0-9]{10}", environment.get(name, "")):
            raise DistributionError(f"Configure a valid 10-character {name}.")
    if not re.fullmatch(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", environment.get("PM_ASC_ISSUER_ID", "")):
        raise DistributionError("Configure PM_ASC_ISSUER_ID as the team API key's issuer UUID.")
    if require_secrets:
        missing = [name for name in SIGNING_SECRETS if not environment.get(name)]
        if missing:
            raise DistributionError("Missing signing secrets: " + ", ".join(missing))
    return bundle_id


def decode_secret(environment, name):
    value = environment.get(name, "")
    try:
        decoded = base64.b64decode("".join(value.split()), validate=True)
    except (ValueError, binascii.Error):
        raise DistributionError(f"{name} is not valid Base64.") from None
    if not decoded or len(decoded) > 10 * 1024 * 1024:
        raise DistributionError(f"{name} must decode to a nonempty file of at most 10 MiB.")
    return decoded


def validate_profile(profile, bundle_id, team_id, now=None):
    now = now or dt.datetime.now(dt.timezone.utc)
    expiry = profile.get("ExpirationDate")
    if not isinstance(expiry, dt.datetime):
        raise DistributionError("Provisioning profile has no expiration date.")
    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=dt.timezone.utc)
    if expiry <= now:
        raise DistributionError("Provisioning profile has expired.")
    entitlements = profile.get("Entitlements", {})
    if team_id not in profile.get("TeamIdentifier", []) or entitlements.get("com.apple.developer.team-identifier") != team_id:
        raise DistributionError("Provisioning profile does not match PM_APPLE_TEAM_ID.")
    prefixes = profile.get("ApplicationIdentifierPrefix", [])
    expected_ids = {f"{prefix}.{bundle_id}" for prefix in prefixes}
    if not prefixes or entitlements.get("application-identifier") not in expected_ids:
        raise DistributionError("Provisioning profile must match the explicit Bundle ID; wildcard profiles are not accepted.")
    if "iOS" not in profile.get("Platform", []):
        raise DistributionError("An iOS provisioning profile is required.")
    if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices") or entitlements.get("get-task-allow", True):
        raise DistributionError("Use an App Store distribution profile, not development, ad hoc or enterprise.")
    identifier = profile.get("UUID", "")
    if not re.fullmatch(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", identifier):
        raise DistributionError("Provisioning profile UUID is invalid.")
    certificates = profile.get("DeveloperCertificates", [])
    if not certificates or any(not isinstance(item, bytes) or not item for item in certificates):
        raise DistributionError("Provisioning profile contains no usable distribution certificate.")
    return {hashlib.sha1(item).hexdigest().upper() for item in certificates}
