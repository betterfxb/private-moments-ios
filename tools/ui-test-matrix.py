"""Select the full UI matrix or an explicitly requested file-flow smoke run."""
import argparse
import json


def matrix(scope: str, smoke_profile: str = "compact-light") -> dict:
    profiles = [
        dict(profile="compact-light", family="compact", appearance="light",
             text_size="large", gallery_only="0"),
        dict(profile="phone-dark", family="phone", appearance="dark",
             text_size="large", gallery_only="1"),
        dict(profile="ipad-light", family="ipad", appearance="light",
             text_size="large", gallery_only="1"),
        dict(profile="compact-dark-accessibility", family="compact", appearance="dark",
             text_size="accessibility-extra-extra-extra-large", gallery_only="1"),
    ]
    if scope not in {"full", "backup"}:
        raise ValueError("Unknown UI verification scope: " + scope)
    selected = [p for p in profiles if p["profile"] == smoke_profile]
    if not selected:
        raise ValueError("Unknown backup smoke profile: " + smoke_profile)
    return {"include": selected if scope == "backup" else profiles}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scope", nargs="?", choices=["full", "backup"], default="full")
    parser.add_argument("--smoke-profile", default="compact-light",
                        choices=["compact-light", "phone-dark", "ipad-light", "compact-dark-accessibility"])
    args = parser.parse_args()
    print(json.dumps(matrix(args.scope, args.smoke_profile)))
