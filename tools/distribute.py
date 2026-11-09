#!/usr/bin/env python3
"""CLI for account-free development archives and explicitly configured future uploads."""

import argparse
import json
import os
import plistlib
import sys
from pathlib import Path

from distribution.archive import package_testflight, package_unsigned
from distribution.configuration import DistributionError, load_policy, validate_upload_configuration, validate_versions
from distribution.native import prepare_simulator, toolchain
from distribution.signing import signing_material


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["check-policy", "select-toolchain", "prepare-simulator", "check-upload", "unsigned", "testflight"])
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--build", default="1.1")
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    try:
        policy = load_policy()
        validate_versions(arguments.version, arguments.build)
        if arguments.operation == "check-policy":
            print("Distribution policy and version/build inputs are valid; no signing or upload performed.")
            return 0
        if arguments.operation == "check-upload":
            validate_upload_configuration(os.environ, require_secrets=False)
            print("Upload opt-in and public identifiers are configured. Signing credentials still require native validation.")
            return 0
        if arguments.operation == "testflight":
            # Reject disabled/missing configuration before creating files or native state.
            validate_upload_configuration(os.environ)
        environment, toolchain_info = toolchain(policy, select=arguments.operation == "select-toolchain")
        if arguments.operation == "select-toolchain":
            print(json.dumps(toolchain_info))
            return 0
        if arguments.operation == "prepare-simulator":
            print(json.dumps(prepare_simulator(environment, toolchain_info)))
            return 0
        if arguments.output is None:
            raise DistributionError("--output must name a new archive output directory.")
        if arguments.operation == "unsigned":
            report = package_unsigned(arguments.output, policy, arguments.version, arguments.build, environment, toolchain_info)
        else:
            with signing_material(environment) as material:
                report = package_testflight(arguments.output, policy, arguments.version, arguments.build, environment, toolchain_info, material)
        print(json.dumps(report, indent=2))
        return 0
    except (DistributionError, OSError, ValueError, plistlib.InvalidFileException) as error:
        print(f"Distribution failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
