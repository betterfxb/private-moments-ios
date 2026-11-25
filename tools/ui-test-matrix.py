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
    if scope not in {"full", "backup", "input", "rotation"}:
        raise ValueError("Unknown UI verification scope: " + scope)
    supplements = {
        "ipad-mini-light": dict(profile="ipad-mini-light", family="ipad-mini",
            appearance="light", text_size="large", gallery_only="1", timeout_minutes=75),
        "ipad-dark-accessibility": dict(profile="ipad-dark-accessibility", family="ipad",
            appearance="dark", text_size="accessibility-extra-extra-extra-large",
            gallery_only="1", timeout_minutes=75),
    }
    if smoke_profile in supplements:
        if scope not in {"input", "rotation"}:
            raise ValueError("Supplemental iPad profiles require explicit input or rotation scope.")
        return {"include": [supplements[smoke_profile]]}
    if scope == "rotation" and smoke_profile != "ipad-light":
        raise ValueError("Rotation smoke requires an explicitly supported iPad profile.")
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
    if scope != "full":
        return {"include": selected}

    common_suites = [("gallery", 80), ("journal", 80), ("files", 55)]
    additional_suites = {
        "compact-light": [("core", 100), ("files-zh", 55), ("journal-features", 70)],
        "ipad-light": [("rotation", 55)],
        "compact-dark-accessibility": [("journal-features", 70)],
    }
    return {"include": [
        dict(profile, suite=suite, test_timeout_minutes=minutes, timeout_minutes=minutes + 25)
        for profile in profiles
        for suite, minutes in common_suites + additional_suites.get(profile["profile"], [])
    ]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scope", nargs="?", choices=["full", "backup", "input", "rotation"], default="full")
    parser.add_argument("--smoke-profile", default="compact-light",
                        choices=["compact-light", "phone-dark", "ipad-light", "compact-dark-accessibility",
                                 "ipad-light-accessibility", "ipad-mini-light", "ipad-dark-accessibility"])
    args = parser.parse_args()
    print(json.dumps(matrix(args.scope, args.smoke_profile)))
