import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
KEY = 'com.apple.security.automation.apple-events'


class AutomationEntitlementTests(unittest.TestCase):
    def test_signed_entitlement_validation(self):
        # Exercise the real verifier against codesign output without signing identities.
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory)
            codesign = tmp / 'codesign'
            codesign.write_text('#!/bin/sh\ncat "$TEST_ENTITLEMENTS"\n')
            codesign.chmod(0o755)
            for value, expected in [(True, 0), (False, 1), (None, 1)]:
                with self.subTest(value=value):
                    source = tmp / 'entitlements.plist'
                    source.write_bytes(plistlib.dumps({KEY: value} if value is not None else {}))
                    env = dict(os.environ, PATH=f'{tmp}:' + os.environ['PATH'], TEST_ENTITLEMENTS=str(source))
                    result = subprocess.run(['bash', str(ROOT / 'scripts/verify-automation-entitlement.sh'), 'Test.app'], env=env, capture_output=True)
                    self.assertEqual(result.returncode, expected, result.stderr)

    def test_host_only_signing(self):
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory)
            codesign = tmp / 'codesign'
            codesign.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ['TEST_CALLS'], 'a') as out:
    out.write(json.dumps(args) + '\\n')
if '--display' in args:
    sys.stdout.buffer.write(Path(os.environ['TEST_ENTITLEMENTS']).read_bytes())
''')
            codesign.chmod(0o755)
            calls = tmp / 'calls.jsonl'
            env = dict(os.environ, PATH=f'{tmp}:' + os.environ['PATH'], TEST_CALLS=str(calls), TEST_ENTITLEMENTS=str(ROOT / 'Corral/FinderOne.entitlements'), KEYCHAIN_PATH='test.keychain', SIGNING_IDENTITY='Test Identity', APPLE_TEAM_ID='TEST')
            subprocess.run(['bash', str(ROOT / 'scripts/sign-app.sh'), 'Test.app'], env=env, check=True)
            import json
            signed = [json.loads(line) for line in calls.read_text().splitlines() if '--force' in json.loads(line)]
            self.assertEqual(len(signed), 6)
            self.assertEqual(signed[-1][-1], 'Test.app')
            self.assertIn('--entitlements', signed[-1])
            for call in signed[:-1]:
                self.assertNotIn('--entitlements', call)


if __name__ == '__main__':
    unittest.main()
