"""Execute the real Bash scope selection without requiring a macOS build."""
import os
from pathlib import Path
import shutil
import subprocess
import textwrap
import unittest


ROOT = Path(__file__).resolve().parent.parent
SCRIPT = (ROOT / 'scripts/verify-mac.sh').read_text(encoding='utf-8')
SELECTION = SCRIPT[SCRIPT.index('TEST_SCOPE_ARGUMENTS='):SCRIPT.index("else\nprintf '\\nBuilding Debug")]
SELECTION += 'else\n:\nfi\nprintf "%s\\n" "${TEST_SCOPE_ARGUMENTS[@]}"\n'
WORKFLOW = (ROOT / '.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
GUARD = textwrap.dedent(WORKFLOW[WORKFLOW.index('          if [[ "$ROTATION_SMOKE"'):WORKFLOW.index('          python3 -m unittest')])
BASH = shutil.which('bash')
if BASH is None and os.name == 'nt':
    git = shutil.which('git')
    candidate = Path(git).parent.parent / 'bin/bash.exe' if git else None
    if candidate is not None and candidate.is_file():
        BASH = str(candidate)
ENGLISH = 'testIPadColdEnglishRotationContinuity'
CHINESE = 'testIPadColdChineseRotationContinuity'
REFERENCE = 'testIPadRotationContinuity'
PREFIX = 'PrivateMomentsUITests/PrivateMomentsUITests/'


def execute(block, values):
    if BASH is None:
        raise RuntimeError('Bash is required to verify the actual scope selection.')
    # Remove inherited task flags so a developer's shell cannot change the case.
    environment = {k: v for k, v in os.environ.items()
                   if not k.startswith('PRIVATE_MOMENTS_UI_') and k not in {
                       'ROTATION_SMOKE', 'ROTATION_START', 'INPUT_SMOKE', 'BACKUP_SMOKE', 'BACKUP_LANGUAGE'}}
    environment.update(values)
    return subprocess.run([BASH, '-c', 'set -euo pipefail\nfail() { printf "%s\\n" "$1" >&2; exit 1; }\n' + block],
                          env=environment, text=True, capture_output=True, timeout=15)


class VerificationScopeTests(unittest.TestCase):
    def script(self, start='reference', **values):
        return execute(SELECTION, dict(PRIVATE_MOMENTS_UI_ROTATION_START=start, **values))

    def test_each_cold_locale_selects_exactly_one_method(self):
        for start, expected, excluded in [('cold-en', ENGLISH, CHINESE), ('cold-zh-Hans', CHINESE, ENGLISH)]:
            with self.subTest(start=start):
                result = self.script(start, PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
                self.assertEqual(result.returncode, 0, result.stderr)
                lines = result.stdout.splitlines()
                self.assertEqual([s for s in lines if s.startswith('-only-testing:')], ['-only-testing:' + PREFIX + expected])
                self.assertIn('-skip-testing:' + PREFIX + excluded, lines)
                self.assertNotIn('-skip-testing:' + PREFIX + expected, lines)

    def test_default_full_phone_and_ipad_exclude_cold_methods(self):
        for ipad in ['0', '1']:
            result = self.script(PRIVATE_MOMENTS_UI_IPAD_TESTS=ipad)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('-skip-testing:' + PREFIX + ENGLISH, result.stdout.splitlines())
            self.assertIn('-skip-testing:' + PREFIX + CHINESE, result.stdout.splitlines())
            self.assertFalse(any(s.startswith('-only-testing:') for s in result.stdout.splitlines()))

    def test_reference_selection_remains_bilingual_method(self):
        result = self.script(PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('-only-testing:' + PREFIX + REFERENCE, result.stdout.splitlines())

    def test_cold_rejects_missing_rotation_phone_or_conflicting_scopes(self):
        for start in ['cold-en', 'cold-zh-Hans']:
            for flags in [{}, {'PRIVATE_MOMENTS_UI_ROTATION_ONLY': '1'},
                          {'PRIVATE_MOMENTS_UI_ROTATION_ONLY': '1', 'PRIVATE_MOMENTS_UI_IPAD_TESTS': '1', 'PRIVATE_MOMENTS_UI_INPUT_ONLY': '1'},
                          {'PRIVATE_MOMENTS_UI_ROTATION_ONLY': '1', 'PRIVATE_MOMENTS_UI_IPAD_TESTS': '1', 'PRIVATE_MOMENTS_UI_BACKUP_ONLY': '1'}]:
                with self.subTest(start=start, flags=flags):
                    self.assertNotEqual(self.script(start, **flags).returncode, 0)

    def test_unknown_rotation_start_is_rejected(self):
        result = self.script('unknown', PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Rotation start must be', result.stderr)

    def test_gallery_input_and_backup_exclude_cold_methods(self):
        for flags in [{'PRIVATE_MOMENTS_UI_GALLERY_ONLY': '1', 'PRIVATE_MOMENTS_UI_IPAD_TESTS': '1'},
                      {'PRIVATE_MOMENTS_UI_INPUT_ONLY': '1'}, {'PRIVATE_MOMENTS_UI_BACKUP_ONLY': '1'}]:
            result = self.script(**flags)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('-skip-testing:' + PREFIX + ENGLISH, result.stdout.splitlines())
            self.assertIn('-skip-testing:' + PREFIX + CHINESE, result.stdout.splitlines())

    def test_workflow_rejects_cold_without_rotation_before_allocating_macos(self):
        for start in ['reference', 'cold-en', 'cold-zh-Hans', 'unknown']:
            for rotation in ['0', '1']:
                result = execute(GUARD, dict(ROTATION_START=start, ROTATION_SMOKE=rotation,
                                           INPUT_SMOKE='0', BACKUP_SMOKE='0', BACKUP_LANGUAGE='en'))
                expected = start != 'unknown' and (start == 'reference' or rotation == '1')
                self.assertEqual(result.returncode == 0, expected, result.stderr)


if __name__ == '__main__':
    unittest.main()
