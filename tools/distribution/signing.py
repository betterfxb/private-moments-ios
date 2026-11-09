"""Temporary manual signing state; never used by the unsigned development job."""

import plistlib
import re
import secrets
import shlex
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

from .configuration import DistributionError, decode_secret, validate_profile, validate_upload_configuration
from .native import require_macos, run


def write_private(path, data):
    path.write_bytes(data)
    path.chmod(0o600)


@contextmanager
def signing_material(environment):
    bundle_id = validate_upload_configuration(environment)
    require_macos()
    original_keychains = shlex.split(run(["security", "list-keychains", "-d", "user"], "Read keychain search list", capture=True, environment=environment).decode())
    with tempfile.TemporaryDirectory(prefix="private-moments-signing-", dir=environment.get("RUNNER_TEMP")) as temporary:
        directory = Path(temporary)
        certificate = directory / "distribution.p12"
        profile_file = directory / "distribution.mobileprovision"
        write_private(certificate, decode_secret(environment, "PM_DISTRIBUTION_P12_BASE64"))
        profile_data = decode_secret(environment, "PM_APPSTORE_PROFILE_BASE64")
        write_private(profile_file, profile_data)
        private_key = decode_secret(environment, "PM_ASC_PRIVATE_KEY_BASE64")
        if not private_key.strip().startswith(b"-----BEGIN PRIVATE KEY-----"):
            raise DistributionError("PM_ASC_PRIVATE_KEY_BASE64 must encode the team's App Store Connect .p8 key.")
        keys_directory = directory / "private_keys"
        keys_directory.mkdir(mode=0o700)
        write_private(keys_directory / f"AuthKey_{environment['PM_ASC_KEY_ID']}.p8", private_key)
        profile = plistlib.loads(run(["security", "cms", "-D", "-i", str(profile_file)], "Decode provisioning profile", capture=True, environment=environment))
        allowed_certificates = validate_profile(profile, bundle_id, environment["PM_APPLE_TEAM_ID"])
        keychain = directory / "signing.keychain-db"
        password = secrets.token_urlsafe(32)
        created = False
        search_changed = False
        owned_profiles = []
        try:
            run(["security", "create-keychain", "-p", password, str(keychain)], "Create temporary signing keychain", capture=True, environment=environment)
            created = True
            run(["security", "set-keychain-settings", "-lut", "21600", str(keychain)], "Configure temporary keychain", capture=True, environment=environment)
            run(["security", "unlock-keychain", "-p", password, str(keychain)], "Unlock temporary keychain", capture=True, environment=environment)
            run(["security", "import", str(certificate), "-P", environment["PM_DISTRIBUTION_P12_PASSWORD"], "-t", "cert", "-f", "pkcs12", "-k", str(keychain), "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"], "Import distribution identity", capture=True, environment=environment)
            run(["security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", password, str(keychain)], "Allow native code signing", capture=True, environment=environment)
            identities = run(["security", "find-identity", "-v", "-p", "codesigning", str(keychain)], "Validate imported signing identity", capture=True, environment=environment).decode()
            matching = allowed_certificates.intersection(re.findall(r"\b[A-F0-9]{40}\b", identities))
            if not matching:
                raise DistributionError("No valid private-key identity matches a certificate in the provisioning profile.")
            run(["security", "list-keychains", "-d", "user", "-s", str(keychain), *original_keychains], "Install temporary keychain in search list", capture=True, environment=environment)
            search_changed = True
            # Support both traditional and current Xcode profile directories.
            signing_user_directory = Path.home() / "Library"
            profile_directories = [
                signing_user_directory / "MobileDevice" / "Provisioning Profiles",
                signing_user_directory / "Developer" / "Xcode" / "UserData" / "Provisioning Profiles",
            ]
            for profile_directory in profile_directories:
                profile_directory.mkdir(parents=True, exist_ok=True)
                installed = profile_directory / f"{profile['UUID']}.mobileprovision"
                if installed.exists():
                    if installed.read_bytes() != profile_data:
                        raise DistributionError("An existing provisioning profile has the same UUID but different content; it will not be overwritten.")
                else:
                    write_private(installed, profile_data)
                    owned_profiles.append(installed)
            yield {
                "bundleID": bundle_id, "teamID": environment["PM_APPLE_TEAM_ID"],
                "profileUUID": profile["UUID"], "workingDirectory": directory,
                "archiveSettings": [
                    "CODE_SIGN_STYLE=Manual", "CODE_SIGNING_ALLOWED=YES",
                    f"DEVELOPMENT_TEAM={environment['PM_APPLE_TEAM_ID']}",
                    f"PROVISIONING_PROFILE_SPECIFIER={profile['UUID']}",
                    f"CODE_SIGN_IDENTITY={sorted(matching)[0]}",
                ],
            }
        finally:
            primary_failure = sys.exc_info()[0] is not None
            cleanup_errors = []
            if search_changed:
                try:
                    run(["security", "list-keychains", "-d", "user", "-s", *original_keychains], "Restore original keychain search list", capture=True, environment=environment)
                except DistributionError as error:
                    cleanup_errors.append(str(error))
            if created:
                try:
                    run(["security", "delete-keychain", str(keychain)], "Delete temporary signing keychain", capture=True, environment=environment)
                except DistributionError as error:
                    cleanup_errors.append(str(error))
            for installed in owned_profiles:
                try:
                    installed.unlink(missing_ok=True)
                except OSError as error:
                    cleanup_errors.append(f"Could not remove temporary profile: {error.strerror}")
            if cleanup_errors:
                message = "Signing cleanup failed: " + "; ".join(cleanup_errors)
                if primary_failure:
                    print(message, file=sys.stderr)
                else:
                    raise DistributionError(message)
