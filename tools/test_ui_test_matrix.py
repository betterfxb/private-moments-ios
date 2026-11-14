"""Protect full acceptance and explicit supplemental diagnostic boundaries."""
import importlib.util
from pathlib import Path
import unittest


spec = importlib.util.spec_from_file_location("ui_test_matrix", Path(__file__).with_name("ui-test-matrix.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
matrix = module.matrix


class UITestMatrixTests(unittest.TestCase):
    def test_full_acceptance_keeps_original_profiles_and_scopes(self):
        profiles = matrix("full")["include"]
        self.assertEqual([p["profile"] for p in profiles], [
            "compact-light", "phone-dark", "ipad-light", "compact-dark-accessibility",
        ])
        self.assertEqual([p["gallery_only"] for p in profiles], ["0", "1", "1", "1"])
        self.assertEqual([p["timeout_minutes"] for p in profiles], [75, 45, 60, 75])
        self.assertEqual([p["text_size"] for p in profiles], [
            "large", "large", "large", "accessibility-extra-extra-extra-large",
        ])

    def test_existing_diagnostics_select_exactly_the_requested_profile(self):
        for profile in matrix("full")["include"]:
            for scope in ["input", "backup"]:
                with self.subTest(profile=profile["profile"], scope=scope):
                    self.assertEqual(matrix(scope, profile["profile"])["include"], [profile])

    def test_ipad_accessibility_requires_explicit_input_scope(self):
        profile = matrix("input", "ipad-light-accessibility")["include"]
        self.assertEqual(len(profile), 1)
        self.assertEqual(profile[0]["family"], "ipad")
        self.assertEqual(profile[0]["appearance"], "light")
        self.assertEqual(profile[0]["text_size"], "accessibility-extra-extra-extra-large")
        self.assertEqual(profile[0]["gallery_only"], "1")
        for scope in ["full", "backup"]:
            with self.subTest(scope=scope), self.assertRaises(ValueError):
                matrix(scope, "ipad-light-accessibility")

    def test_unknown_scope_or_profile_fails_closed(self):
        for scope, profile in [("unknown", "compact-light"), ("input", "unknown"), ("full", "unknown")]:
            with self.subTest(scope=scope, profile=profile), self.assertRaises(ValueError):
                matrix(scope, profile)

    def test_rotation_requires_ipad_light_profile(self):
        self.assertEqual(matrix("rotation", "ipad-light"), matrix("input", "ipad-light"))
        for profile in ["compact-light", "phone-dark", "compact-dark-accessibility", "ipad-light-accessibility", "unknown"]:
            with self.subTest(profile=profile), self.assertRaises(ValueError):
                matrix("rotation", profile)

    def test_supplemental_ipads_require_explicit_input_or_rotation(self):
        for name, family, appearance, size in [
            ("ipad-mini-light", "ipad-mini", "light", "large"),
            ("ipad-dark-accessibility", "ipad", "dark", "accessibility-extra-extra-extra-large"),
        ]:
            for scope in ["input", "rotation"]:
                with self.subTest(profile=name, scope=scope):
                    self.assertEqual(matrix(scope, name)["include"], [dict(
                        profile=name, family=family, appearance=appearance,
                        text_size=size, gallery_only="1", timeout_minutes=75)])
            for scope in ["full", "backup"]:
                with self.subTest(profile=name, scope=scope), self.assertRaises(ValueError):
                    matrix(scope, name)


if __name__ == "__main__":
    unittest.main()
