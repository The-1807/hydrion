"""Failure and destination regression tests; no Apple tooling required."""
import importlib.util
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    "apple_simulator", Path(__file__).parents[1] / "apple_simulator.py")
apple = importlib.util.module_from_spec(spec)
spec.loader.exec_module(apple)


def fixture():
    data = {"runtimes": [], "devices": {}, "pairs": {
        "pair": {"phone": {"udid": "phone"}, "watch": {"udid": "watch"}, "state": "active"}}}
    for platform, os, name, udid in (("iOS", "18.3", "iPhone-16", "phone"),
                                      ("watchOS", "11.2", "Apple-Watch-Series-10", "watch")):
        rid = f"com.apple.CoreSimulator.SimRuntime.{platform}-{os.replace('.', '-')}"
        data["runtimes"].append({"identifier": rid, "version": os, "isAvailable": True})
        data["devices"][rid] = [{"udid": udid, "name": name, "isAvailable": True,
                                 "deviceTypeIdentifier": name, "state": "Booted"}]
    return data


class DestinationTests(unittest.TestCase):
    def test_pair_is_selected_by_device_type_even_when_renamed(self):
        data = fixture()
        next(iter(data["devices"].values()))[0]["name"] = "Hydrion Certification"
        phone, watch, pair = apple.select_pair(data, "14.0", "10.0")
        self.assertEqual((phone["udid"], watch["udid"], pair), ("phone", "watch", "pair"))

    def test_distinct_missing_runtime_diagnostics(self):
        for index, code in ((0, "NO_IOS_RUNTIME"), (1, "NO_WATCHOS_RUNTIME")):
            data = fixture()
            data["runtimes"][index]["isAvailable"] = False
            with self.subTest(code=code), self.assertRaisesRegex(apple.DestinationError, code):
                apple.select_pair(data, "14.0", "10.0")

    def test_distinct_missing_device_diagnostics(self):
        for index, code in ((0, "NO_IPHONE"), (1, "NO_APPLE_WATCH")):
            data = fixture()
            data["devices"][data["runtimes"][index]["identifier"]] = []
            with self.subTest(code=code), self.assertRaisesRegex(apple.DestinationError, code):
                apple.select_pair(data, "14.0", "10.0")

    def test_deployment_target_is_respected(self):
        with self.assertRaisesRegex(apple.DestinationError, "NO_IOS_RUNTIME"):
            apple.select_pair(fixture(), "19.0", "10.0")

    def test_unpaired_or_unavailable_watch_is_not_selected(self):
        data = fixture()
        data["pairs"]["pair"]["watch"]["udid"] = "unavailable-watch"
        with self.assertRaisesRegex(apple.DestinationError, "NOT_PAIRED"):
            apple.select_pair(data, "14.0", "10.0")

    def test_creation_preserves_existing_pairs(self):
        with patch.object(apple, "run") as run:
            with self.assertRaisesRegex(apple.DestinationError, "existing pairs preserved"):
                apple.create_pair(fixture(), "14.0", "10.0")
            run.assert_not_called()

    def test_command_timeout_is_bounded_and_categorized(self):
        with self.assertRaisesRegex(apple.DestinationError, "PAIR_BOOT_FAILED: timed out"):
            apple.run([sys.executable, "-c", "import time; time.sleep(10)"],
                      "PAIR_BOOT_FAILED", timeout=0.05)

    def test_command_failure_keeps_diagnostic(self):
        with self.assertRaisesRegex(apple.DestinationError, "XCODE_DESTINATION_REJECTED: exit 7"):
            apple.run([sys.executable, "-c", "raise SystemExit(7)"], "XCODE_DESTINATION_REJECTED")

    def test_denied_termination_preserves_timeout_and_stays_bounded(self):
        process = Mock()
        process.communicate.side_effect = apple.subprocess.TimeoutExpired(
            "simctl", 1, output=b"waiting on system app")
        process.send_signal.side_effect = PermissionError("denied")
        with patch.object(apple.subprocess, "Popen", return_value=process), \
                patch.object(apple.os, "killpg", side_effect=PermissionError("denied")):
            with self.assertRaisesRegex(apple.DestinationError,
                                        "(?s)PAIR_BOOT_FAILED: timed out.*waiting on system app.*cleanup failed"):
                apple.run(["simctl"], "PAIR_BOOT_FAILED", timeout=1)
        self.assertEqual([call.kwargs["timeout"] for call in process.communicate.call_args_list],
                         [1, 5, 5])
        process.stdout.close.assert_called_once()
        process.stderr.close.assert_called_once()

    def test_boot_failure_is_distinct(self):
        with patch.object(apple, "inventory", return_value=fixture()), \
                patch.object(apple, "run", side_effect=apple.DestinationError("PAIR_BOOT_FAILED")):
            with self.assertRaisesRegex(apple.DestinationError, "PAIR_BOOT_FAILED"):
                apple.prepare()

    def test_flutter_missing_phone_is_distinct(self):
        with patch.object(apple, "inventory", return_value=fixture()), \
                patch.object(apple, "run", return_value="[]"):
            with self.assertRaisesRegex(apple.DestinationError, "FLUTTER_IPHONE_NOT_EXPOSED"):
                apple.prepare()

    def test_ineligible_xcode_destination_is_rejected(self):
        def run(command, *args):
            if command[0] == "flutter":
                return '[{"id":"phone"}]'
            return "Available destinations:\nIneligible destinations:\nphone"
        with patch.object(apple, "inventory", return_value=fixture()), patch.object(apple, "run", run):
            with self.assertRaisesRegex(apple.DestinationError, "XCODE_DESTINATION_REJECTED"):
                apple.prepare()

    def test_compilation_receives_phone_not_watch_udid(self):
        with patch.object(apple, "run", side_effect=apple.DestinationError("compile")) as run:
            with self.assertRaises(apple.DestinationError):
                apple.build_and_launch({"iphone": {"udid": "phone"}, "watch": {"udid": "watch"}})
            command, category, timeout = run.call_args.args
            self.assertEqual(command[-2:], ["-d", "phone"])
            self.assertEqual(category, "COMPILATION_FAILED_AFTER_DESTINATION_SELECTION")
            self.assertLessEqual(timeout, 1800)


if __name__ == "__main__":
    unittest.main()
