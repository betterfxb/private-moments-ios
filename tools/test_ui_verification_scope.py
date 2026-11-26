"""Execute the real Bash scope selection without requiring a macOS build."""
import os
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory
import textwrap
import unittest


ROOT = Path(__file__).resolve().parent.parent
SCRIPT = (ROOT / 'scripts/verify-mac.sh').read_text(encoding='utf-8')
SELECTION = SCRIPT[SCRIPT.index('TEST_SCOPE_ARGUMENTS='):SCRIPT.index("printf '\\nBuilding Debug")]
SELECTION += ':\nfi\nprintf "%s\\n" "${TEST_SCOPE_ARGUMENTS[@]}"\n'
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
                       'ROTATION_SMOKE', 'ROTATION_START', 'INPUT_SMOKE', 'BACKUP_SMOKE', 'BACKUP_LANGUAGE', 'PERFORMANCE_SMOKE',
                       'WEEK_REVIEW_SMOKE', 'READING_SMOKE', 'JOURNAL_FEATURES_SMOKE', 'SMOKE_PROFILE'}}
    environment.update(values)
    # Git Bash on Windows truncates long command arguments. Execute the
    # complete selection with Unix line endings from a temporary script.
    with TemporaryDirectory() as directory:
        script = Path(directory) / 'test-scope.sh'
        script.write_text('set -euo pipefail\nfail() { printf "%s\\n" "$1" >&2; exit 1; }\n' + block,
                          encoding='utf-8', newline='\n')
        return subprocess.run([BASH, script.as_posix()], env=environment, text=True, capture_output=True, timeout=15)


class VerificationScopeTests(unittest.TestCase):
    def script(self, start='reference', **values):
        return execute(SELECTION, dict(PRIVATE_MOMENTS_UI_ROTATION_START=start, **values))

    def test_input_performance_and_rotation_diagnostics_stay_out_of_full_concurrency_group(self):
        concurrency = WORKFLOW.split('\nconcurrency:\n', 1)[1].split('\njobs:\n', 1)[0]
        groups = {
            'input_smoke': "format('input-{0}', inputs.backup_smoke_profile)",
            'performance_smoke': "'performance'",
            'rotation_smoke': "format('rotation-{0}-{1}', inputs.backup_smoke_profile, inputs.rotation_start)",
        }
        for flag, group in groups.items():
            with self.subTest(flag=flag):
                self.assertIn(f'inputs.{flag} && {group}', concurrency)
        self.assertIn("|| 'standard'", concurrency)

    def test_acceptance_gallery_runs_only_bilingual_gallery(self):
        result = self.script(PRIVATE_MOMENTS_UI_ACCEPTANCE_PART='gallery')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([line for line in result.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:' + PREFIX + 'testScreenGallery'])

    def test_reading_diagnostic_reuses_the_same_native_sample(self):
        result = self.script(PRIVATE_MOMENTS_UI_ACCEPTANCE_PART='reading')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([line for line in result.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:PrivateMomentsTests/SemanticColorTests',
                          '-only-testing:' + PREFIX + 'testJournalReadingSample',
                          '-only-testing:' + PREFIX + 'testQuickJournalJourney'])
        baseline = dict(ROTATION_START='reference', ROTATION_SMOKE='0', INPUT_SMOKE='0', BACKUP_SMOKE='0',
                        BACKUP_LANGUAGE='en', READING_SMOKE='1', SMOKE_PROFILE='compact-light')
        self.assertEqual(execute(GUARD, baseline).returncode, 0)
        for key in ['INPUT_SMOKE', 'BACKUP_SMOKE', 'WEEK_REVIEW_SMOKE', 'ROTATION_SMOKE', 'PERFORMANCE_SMOKE']:
            with self.subTest(key=key):
                self.assertNotEqual(execute(GUARD, baseline | {key: '1'}).returncode, 0)

    def test_journal_features_are_tested_together_without_extending_older_journal_diagnostics(self):
        result = self.script(PRIVATE_MOMENTS_UI_ACCEPTANCE_PART='journal-features')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([line for line in result.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:PrivateMomentsTests/MomentDateQueryTests',
                          '-only-testing:PrivateMomentsTests/MomentTagTests',
                          '-only-testing:' + PREFIX + 'testTimelineDateAndTagFiltersCombineAndSurviveNavigation',
                          '-only-testing:' + PREFIX + 'testRecordAgainCopiesOnlyTypeAndTags',
                          '-only-testing:' + PREFIX + 'testMonthHighlightsOpenFavoritesAndMatchingFeelings',
                          '-only-testing:' + PREFIX + 'testQuickRecordCanBeCompletedLaterAndReusesCustomTags',
                          '-only-testing:' + PREFIX + 'testMonthCalendarOpensTheDayAndUpdatesAfterDeletion'])
        baseline = dict(ROTATION_START='reference', ROTATION_SMOKE='0', INPUT_SMOKE='0', BACKUP_SMOKE='0',
                        BACKUP_LANGUAGE='en', JOURNAL_FEATURES_SMOKE='1', SMOKE_PROFILE='compact-light')
        self.assertEqual(execute(GUARD, baseline).returncode, 0)
        for key in ['INPUT_SMOKE', 'BACKUP_SMOKE', 'WEEK_REVIEW_SMOKE', 'ROTATION_SMOKE', 'PERFORMANCE_SMOKE', 'READING_SMOKE']:
            with self.subTest(key=key):
                self.assertNotEqual(execute(GUARD, baseline | {key: '1'}).returncode, 0)

    def test_acceptance_core_skips_sharded_methods_and_runs_remaining_tests(self):
        result = self.script(PRIVATE_MOMENTS_UI_ACCEPTANCE_PART='core')
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        self.assertFalse(any(line.startswith('-only-testing:') for line in lines))
        for method in ['testScreenGallery', 'testFavoriteCanBeFoundWithSearchAfterRelaunch',
                       'testTimelineDateAndTagFiltersCombineAndSurviveNavigation',
                       'testRecordAgainCopiesOnlyTypeAndTags', 'testMonthHighlightsOpenFavoritesAndMatchingFeelings',
                       'testQuickRecordCanBeCompletedLaterAndReusesCustomTags',
                       'testMonthCalendarOpensTheDayAndUpdatesAfterDeletion',
                       'testWeekReviewShowsLocalRecords', 'testReviewTabBrowsesPeriodsAndOpensFilteredRecord',
                       'testReviewComparisonOpensRecordsFromPreviousMonth',
                       'testUnfinishedDraftSurvivesTerminationAndCanBeSavedOrDiscarded',
                       'testBackupFileRoundTrip', 'testChineseBackupFileRoundTrip', REFERENCE]:
            self.assertIn('-skip-testing:' + PREFIX + method, lines)
        for method in ['testManualEntryTimingDateFilterAndPersistence', 'testSessionAndRecapDiscardConfirmations',
                       'testEditingFilteringDeletionAndRelaunch', 'testTerminationPreservesOnlyExplicitlySavedRecords',
                       'testLargeJournalInteractionBaseline', 'testTimelineSearchReflectsEditAndDeletion']:
            self.assertNotIn('-skip-testing:' + PREFIX + method, lines)

    def test_acceptance_part_rejects_invalid_or_mixed_scopes(self):
        self.assertNotEqual(self.script(PRIVATE_MOMENTS_UI_ACCEPTANCE_PART='unknown').returncode, 0)
        for part in ['gallery', 'core', 'reading', 'journal-features']:
            for key in ['INPUT_ONLY', 'BACKUP_ONLY', 'PERFORMANCE_ONLY', 'WEEK_REVIEW_ONLY',
                        'ROTATION_ONLY', 'GALLERY_ONLY']:
                with self.subTest(part=part, key=key):
                    self.assertNotEqual(self.script(PRIVATE_MOMENTS_UI_ACCEPTANCE_PART=part,
                                                    PRIVATE_MOMENTS_UI_IPAD_TESTS='1',
                                                    **{f'PRIVATE_MOMENTS_UI_{key}': '1'}).returncode, 0)

    def test_performance_measures_the_real_app_and_checks_mutations(self):
        result = self.script(PRIVATE_MOMENTS_UI_PERFORMANCE_ONLY='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([line for line in result.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:' + PREFIX + 'testLargeJournalInteractionBaseline',
                          '-only-testing:' + PREFIX + 'testTimelineSearchReflectsEditAndDeletion'])
        for flags in [{'PRIVATE_MOMENTS_UI_INPUT_ONLY': '1'}, {'PRIVATE_MOMENTS_UI_BACKUP_ONLY': '1'},
                      {'PRIVATE_MOMENTS_UI_IPAD_TESTS': '1', 'PRIVATE_MOMENTS_UI_ROTATION_ONLY': '1'}]:
            self.assertNotEqual(self.script(PRIVATE_MOMENTS_UI_PERFORMANCE_ONLY='1', **flags).returncode, 0)
        for profile in ['compact-light', 'phone-dark']:
            result = execute(GUARD, dict(ROTATION_START='reference', ROTATION_SMOKE='0', INPUT_SMOKE='0',
                                         BACKUP_SMOKE='0', BACKUP_LANGUAGE='en', PERFORMANCE_SMOKE='1',
                                         SMOKE_PROFILE=profile))
            self.assertEqual(result.returncode == 0, profile == 'compact-light', result.stderr)

    def test_each_cold_locale_selects_exactly_one_method(self):
        for start, expected, excluded in [('cold-en', ENGLISH, CHINESE), ('cold-zh-Hans', CHINESE, ENGLISH)]:
            with self.subTest(start=start):
                result = self.script(start, PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
                self.assertEqual(result.returncode, 0, result.stderr)
                lines = result.stdout.splitlines()
                self.assertEqual([s for s in lines if s.startswith('-only-testing:')], ['-only-testing:' + PREFIX + expected])
                self.assertIn('-skip-testing:' + PREFIX + excluded, lines)
                self.assertNotIn('-skip-testing:' + PREFIX + expected, lines)

    def test_week_review_smoke_checks_journal_queries_and_native_flows(self):
        result = self.script(PRIVATE_MOMENTS_UI_WEEK_REVIEW_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([line for line in result.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:PrivateMomentsTests/MomentDateQueryTests',
                          '-only-testing:PrivateMomentsTests/FavoritePersistenceTests',
                          '-only-testing:PrivateMomentsTests/RecapDraftRecoveryTests',
                          '-only-testing:PrivateMomentsTests/SemanticColorTests',
                          '-only-testing:' + PREFIX + 'testFavoriteCanBeFoundWithSearchAfterRelaunch',
                          '-only-testing:' + PREFIX + 'testWeekReviewShowsLocalRecords',
                          '-only-testing:' + PREFIX + 'testReviewTabBrowsesPeriodsAndOpensFilteredRecord',
                          '-only-testing:' + PREFIX + 'testReviewComparisonOpensRecordsFromPreviousMonth',
                          '-only-testing:' + PREFIX + 'testUnfinishedDraftSurvivesTerminationAndCanBeSavedOrDiscarded'])
        for key in ['INPUT', 'BACKUP', 'PERFORMANCE', 'ROTATION']:
            conflict = self.script(PRIVATE_MOMENTS_UI_WEEK_REVIEW_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1',
                                   **{f'PRIVATE_MOMENTS_UI_{key}_ONLY': '1'})
            self.assertNotEqual(conflict.returncode, 0)
            result = execute(GUARD, dict(ROTATION_START='reference', ROTATION_SMOKE='0', INPUT_SMOKE='0',
                                         BACKUP_SMOKE='0', BACKUP_LANGUAGE='en', PERFORMANCE_SMOKE='0',
                                         SMOKE_PROFILE='ipad-light') | {'WEEK_REVIEW_SMOKE': '1', f'{key}_SMOKE': '1'})
            self.assertNotEqual(result.returncode, 0)
        gallery = self.script(PRIVATE_MOMENTS_UI_GALLERY_ONLY='1')
        self.assertIn('-only-testing:' + PREFIX + 'testWeekReviewShowsLocalRecords', gallery.stdout.splitlines())
        self.assertIn('-only-testing:' + PREFIX + 'testReviewTabBrowsesPeriodsAndOpensFilteredRecord',
                      gallery.stdout.splitlines())

    def test_default_full_phone_and_ipad_exclude_cold_methods(self):
        for ipad in ['0', '1']:
            result = self.script(PRIVATE_MOMENTS_UI_IPAD_TESTS=ipad)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('-skip-testing:' + PREFIX + ENGLISH, result.stdout.splitlines())
            self.assertIn('-skip-testing:' + PREFIX + CHINESE, result.stdout.splitlines())
            self.assertFalse(any(s.startswith('-only-testing:') for s in result.stdout.splitlines()))

    def test_input_scope_runs_gallery_and_independent_bilingual_search(self):
        result = self.script(PRIVATE_MOMENTS_UI_INPUT_ONLY='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        method = PREFIX + 'testTimelineSearchLayoutInBothLanguages'
        self.assertIn('-only-testing:' + PREFIX + 'testScreenGallery', lines)
        self.assertIn('-only-testing:' + method, lines)
        self.assertNotIn('-skip-testing:' + method, lines)
        self.assertIn('-skip-testing:' + method, self.script().stdout.splitlines())

    def test_reference_selection_remains_bilingual_method(self):
        result = self.script(PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('-only-testing:' + PREFIX + REFERENCE, result.stdout.splitlines())

    def test_window_resize_is_an_explicit_ipad_diagnostic(self):
        method = PREFIX + 'testIPadWindowResizeContinuity'
        focused = self.script('window-resize', PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
        self.assertEqual(focused.returncode, 0, focused.stderr)
        self.assertEqual([line for line in focused.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:' + method])
        self.assertIn('-skip-testing:' + method, self.script().stdout.splitlines())
        self.assertNotEqual(self.script('window-resize', PRIVATE_MOMENTS_UI_ROTATION_ONLY='1').returncode, 0)
        self.assertNotEqual(self.script('window-resize', PRIVATE_MOMENTS_UI_IPAD_TESTS='1').returncode, 0)

    def test_window_resize_with_keyboard_uses_the_accessibility_ipad_profile(self):
        method = PREFIX + 'testIPadWindowResizeWithKeyboard'
        focused = self.script('window-resize-keyboard', PRIVATE_MOMENTS_UI_ROTATION_ONLY='1', PRIVATE_MOMENTS_UI_IPAD_TESTS='1')
        self.assertEqual(focused.returncode, 0, focused.stderr)
        self.assertEqual([line for line in focused.stdout.splitlines() if line.startswith('-only-testing:')],
                         ['-only-testing:' + method])
        self.assertIn('-skip-testing:' + method, self.script().stdout.splitlines())
        for profile in ['ipad-dark-accessibility', 'ipad-light', 'compact-dark-accessibility']:
            with self.subTest(profile=profile):
                outcome = execute(GUARD, dict(ROTATION_START='window-resize-keyboard', ROTATION_SMOKE='1',
                                               INPUT_SMOKE='0', BACKUP_SMOKE='0', BACKUP_LANGUAGE='en',
                                               SMOKE_PROFILE=profile))
                self.assertEqual(outcome.returncode == 0, profile == 'ipad-dark-accessibility', outcome.stderr)

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
        for start in ['reference', 'cold-en', 'cold-zh-Hans', 'window-resize', 'unknown']:
            for rotation in ['0', '1']:
                result = execute(GUARD, dict(ROTATION_START=start, ROTATION_SMOKE=rotation,
                                           INPUT_SMOKE='0', BACKUP_SMOKE='0', BACKUP_LANGUAGE='en', SMOKE_PROFILE='ipad-light'))
                expected = start != 'unknown' and (start == 'reference' or rotation == '1')
                self.assertEqual(result.returncode == 0, expected, result.stderr)


if __name__ == '__main__':
    unittest.main()
