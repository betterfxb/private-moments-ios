"""Native command execution and toolchain selection, without logging credentials."""

import os
import platform
import re
import subprocess
from pathlib import Path

from .configuration import DistributionError, SIGNING_SECRETS


def run(arguments, label, *, capture=False, environment=None, cwd=None):
    print(label, flush=True)
    try:
        result = subprocess.run(arguments, env=environment, cwd=cwd, capture_output=capture, check=False)
    except OSError as error:
        raise DistributionError(f"{label}: cannot start native tool ({error.strerror}).") from None
    if result.returncode:
        detail = (result.stderr or b"").decode("utf-8", errors="replace")[-2000:] if capture else "See the native tool output above."
        for name in SIGNING_SECRETS:
            value = (environment or os.environ).get(name)
            if value:
                detail = detail.replace(value, "[redacted]")
        raise DistributionError(f"{label} failed (exit {result.returncode}). {detail}")
    return result.stdout or b""


def require_macos():
    if platform.system() != "Darwin":
        raise DistributionError("Native distribution commands require macOS with full Xcode; use the GitHub workflow from Windows.")


def toolchain(policy, select=False):
    require_macos()
    developer_directory = Path("/Applications") / f"Xcode_{policy['xcodeVersion']}.app" / "Contents" / "Developer"
    if not developer_directory.is_dir():
        raise DistributionError(f"Required Xcode is not installed: {developer_directory}. No fallback to the runner default is allowed.")
    environment = dict(os.environ, DEVELOPER_DIR=str(developer_directory))
    version_output = run(["xcodebuild", "-version"], "Verify selected Xcode", capture=True, environment=environment).decode()
    match = re.search(r"^Xcode (\d+(?:\.\d+)+)$", version_output, re.MULTILINE)
    if not match or match.group(1).split(".")[:2] != policy["xcodeVersion"].split(".")[:2]:
        raise DistributionError("Selected Xcode version does not match the pinned stable policy.")
    sdk = run(["xcrun", "--sdk", "iphoneos", "--show-sdk-version"], "Verify iOS device SDK", capture=True, environment=environment).decode().strip()
    if not re.fullmatch(r"\d+(?:\.\d+)*", sdk) or int(sdk.split(".")[0]) < policy["minimumIOSSDKMajor"]:
        raise DistributionError("Selected iOS device SDK is below the distribution minimum.")
    if select:
        if not os.environ.get("GITHUB_ENV"):
            raise DistributionError("select-toolchain requires GITHUB_ENV in a GitHub macOS job.")
        with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as destination:
            destination.write(f"DEVELOPER_DIR={developer_directory}\n")
    return environment, {"xcode": match.group(1), "iphoneOSSDK": sdk, "developerDirectory": str(developer_directory)}
