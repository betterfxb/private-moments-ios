"""Select full acceptance or an explicitly requested native UI diagnostic."""
import argparse
import json


def matrix(scope: str, smoke_profile: str = "compact-light") -> dict:
    profiles = [
        dict(profile="compact-light", family="compact", appearance="light",
             text_size="large", gallery_only="0", timeout_minutes=75),
        dict(profile="phone-dark", family="phone", appearance="dark",
             text_size="large", gallery_only="1", timeout_minutes=45),
        dict(profile="ipad-light", family="ipad", appearance="light",
             text_size="large", gallery_only="1", timeout_minutes=60),
        dict(profile="compact-dark-accessibility", family="compact", appearance="dark",
             text_size="accessibility-extra-extra-extra-large", gallery_only="1", timeout_minutes=75),
    ]
    if scope not in {"full", "backup", "input"}:
        raise ValueError("Unknown UI verification scope: " + scope)
    if smoke_profile == "ipad-light-accessibility":
        if scope != "input":
            raise ValueError("iPad accessibility is a supplemental input gallery profile only.")
        return {"include": [dict(
            profile="ipad-light-accessibility", family="ipad", appearance="light",
            text_size="accessibility-extra-extra-extra-large", gallery_only="1",
            timeout_minutes=75,
        )]}
    selected = [p for p in profiles if p["profile"] == smoke_profile]
    if not selected:
        raise ValueError("Unknown diagnostic profile: " + smoke_profile)
    return {"include": profiles if scope == "full" else selected}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scope", nargs="?", choices=["full", "backup", "input"], default="full")
    parser.add_argument("--smoke-profile", default="compact-light",
                        choices=["compact-light", "phone-dark", "ipad-light", "compact-dark-accessibility",
                                 "ipad-light-accessibility"])
    args = parser.parse_args()
    print(json.dumps(matrix(args.scope, args.smoke_profile)))
