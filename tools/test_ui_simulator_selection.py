"""Exercise the workflow's actual simulator selector without requiring Xcode."""
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
import os
from pathlib import Path
import unittest
from unittest.mock import patch


workflow = (Path(__file__).resolve().parent.parent / '.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
selector = workflow.split('destination="$(xcrun simctl list devices available --json | python3 -c \'', 1)[1].split("\n          ')", 1)[0]
# The source has YAML block indentation, not Python module indentation.
selector = '\n'.join(line[10:] if line.startswith('          ') else line for line in selector.splitlines())


def choose(family, devices_by_runtime):
    output = StringIO()
    with patch.dict(os.environ, {'SIMULATOR_FAMILY': family}), \
         patch('sys.stdin', StringIO(json.dumps({'devices': devices_by_runtime}))), \
         patch('subprocess.check_output', return_value='26.2\n'), \
         redirect_stdout(output), redirect_stderr(StringIO()):
        try:
            exec(compile(selector, 'ios-ci-simulator-selector', 'exec'), {})
        except SystemExit as result:
            return result.code, output.getvalue().strip()
    raise AssertionError('Selector must either select one device or fail explicitly.')


def device(name, available=True):
    return dict(name=name, udid=name.replace(' ', '-'), isAvailable=available)


runtime = 'com.apple.CoreSimulator.SimRuntime.iOS-26-2'


class SimulatorSelectionTests(unittest.TestCase):
    def test_mini_selects_a_real_mini_instead_of_first_ipad(self):
        code, target = choose('ipad-mini', {runtime: [device('iPad Pro'), device('iPad mini (A17 Pro)')]})
        self.assertEqual(code, 0)
        self.assertEqual(target, 'platform=iOS Simulator,id=iPad-mini-(A17-Pro)')

    def test_missing_or_unavailable_mini_fails_without_fallback(self):
        for devices in [[device('iPad Pro')], [device('iPad mini (A17 Pro)', False), device('iPad Air')]]:
            with self.subTest(devices=devices):
                code, target = choose('ipad-mini', {runtime: devices})
                self.assertNotEqual(code, 0)
                self.assertEqual(target, '')

    def test_other_runtime_does_not_substitute_for_pinned_sdk(self):
        code, target = choose('ipad-mini', {'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [device('iPad mini')]})
        self.assertNotEqual(code, 0)
        self.assertEqual(target, '')

    def test_existing_phone_and_ipad_selection_is_preserved(self):
        devices = [device('iPad Pro'), device('iPad mini'), device('iPhone 17'), device('iPhone SE (3rd generation)')]
        for family, expected in [('ipad', 'iPad-Pro'), ('phone', 'iPhone-17'), ('compact', 'iPhone-SE-(3rd-generation)')]:
            with self.subTest(family=family):
                self.assertEqual(choose(family, {runtime: devices}), (0, 'platform=iOS Simulator,id=' + expected))

    def test_unavailable_devices_are_excluded_before_selection(self):
        self.assertEqual(choose('ipad', {runtime: [device('iPad Pro', False), device('iPad Air')]}),
            (0, 'platform=iOS Simulator,id=iPad-Air'))


if __name__ == '__main__':
    unittest.main()
