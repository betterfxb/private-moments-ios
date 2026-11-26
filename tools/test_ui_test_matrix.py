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
        jobs = matrix("full")["include"]
        groups = {
            "compact-light": {"gallery", "journal", "journal-features", "files", "files-zh", "core"},
            "phone-dark": {"gallery", "journal", "files"},
            "ipad-light": {"gallery", "journal", "files", "rotation"},
            "compact-dark-accessibility": {"gallery", "journal", "journal-features", "files"},
        }
        self.assertEqual({(job["profile"], job["suite"]) for job in jobs},
                         {(profile, suite) for profile, suites in groups.items() for suite in suites})
        self.assertEqual(len(jobs), sum(map(len, groups.values())))
        for job in jobs:
            with self.subTest(job=job):
                self.assertGreaterEqual(job["timeout_minutes"] - job["test_timeout_minutes"], 12)
                if job["suite"] == "gallery":
                    self.assertGreaterEqual(job["test_timeout_minutes"], 75)
                source, = matrix("input", job["profile"])["include"]
                for key in ["family", "appearance", "text_size"]:
                    self.assertEqual(job[key], source[key])

    def test_existing_diagnostics_select_exactly_the_requested_profile(self):
        for profile in ["compact-light", "phone-dark", "ipad-light", "compact-dark-accessibility"]:
            for scope in ["input", "backup"]:
                with self.subTest(profile=profile, scope=scope):
                    selected, = matrix(scope, profile)["include"]
                    self.assertEqual(selected["profile"], profile)
                    self.assertNotIn("suite", selected)

    def test_exact_acceptance_job_can_be_reissued_with_the_same_coverage(self):
        for job in matrix("full")["include"]:
            with self.subTest(profile=job["profile"], suite=job["suite"]):
                self.assertEqual(matrix("full", job["profile"], job["suite"])["include"], [job])
        for scope, profile, suite in [("full", "phone-dark", "core"), ("full", "ipad-light", "unknown"),
                                      ("input", "compact-light", "core"), ("full", "ipad-mini-light", "core")]:
            with self.subTest(scope=scope, profile=profile, suite=suite), self.assertRaises(ValueError):
                matrix(scope, profile, suite)

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

    def test_timeline_tags_can_be_repeated_without_expanding_the_default_matrix(self):
        self.assertFalse(any(job["suite"] == "timeline-tags" for job in matrix("full")["include"]))
        for profile in ["compact-light", "compact-dark-accessibility"]:
            with self.subTest(profile=profile):
                job, = matrix("full", profile, "timeline-tags")["include"]
                self.assertEqual((job["profile"], job["suite"]), (profile, "timeline-tags"))
        with self.assertRaises(ValueError):
            matrix("full", "ipad-light", "timeline-tags")

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
