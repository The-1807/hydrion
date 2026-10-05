"""Failure and destination regression tests; no Apple tooling required."""
import ast
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    "apple_simulator", Path(__file__).parents[1] / "apple_simulator.py")
apple = importlib.util.module_from_spec(spec)
spec.loader.exec_module(apple)


def fixture():
    data = {"runtimes": [], "devices": {}, "pairs": {
        "pair": {"phone": {"udid": "phone"}, "watch": {"udid": "watch"},
                 "state": "(active, connected)"}}}
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
        process.terminate.side_effect = PermissionError("denied")
        process.kill.side_effect = PermissionError("denied")
        with patch.object(apple.subprocess, "Popen", return_value=process), \
                patch.object(apple, "disk_evidence", return_value={}), \
                patch.object(apple.os, "name", "posix"), \
                patch.object(apple.signal, "SIGKILL", 9, create=True), \
                patch.object(apple.os, "killpg", side_effect=PermissionError("denied"), create=True):
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

    def test_unbooted_phone_is_rejected_before_destination_discovery(self):
        data = fixture()
        next(iter(data["devices"].values()))[0]["state"] = "Shutdown"
        with patch.object(apple, "inventory", return_value=data), \
                patch.object(apple, "run", return_value="") as run:
            with self.assertRaisesRegex(apple.DestinationError, "PAIR_BOOT_FAILED"):
                apple.prepare()
        self.assertTrue(all(call.args[0][:2] == ["xcrun", "simctl"]
                            for call in run.call_args_list))

    def test_ineligible_xcode_destination_is_rejected(self):
        def run(command, *args):
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

    def test_disconnected_pair_waits_until_connected(self):
        disconnected = fixture()
        disconnected["pairs"]["pair"]["state"] = "(active, disconnected)"
        connected = fixture()
        connected["pairs"]["pair"]["state"] = "(active, connected)"
        destination = self.destination()
        with patch.object(apple, "inventory", side_effect=[disconnected, connected]), \
                patch.object(apple.time, "sleep") as sleep:
            apple.wait_for_connection(destination)
        sleep.assert_called_once()
        self.assertEqual(destination["pair_state"], "(active, connected)")

    def test_unready_pair_has_bounded_distinct_failure(self):
        for state, booted in (("(active, disconnected)", True),
                              ("(inactive, connected)", True),
                              ("(active, connected)", False)):
            with self.subTest(state=state, booted=booted):
                data = fixture()
                data["pairs"]["pair"]["state"] = state
                if not booted:
                    next(iter(data["devices"].values()))[0]["state"] = "Shutdown"
                with patch.object(apple, "inventory", return_value=data) as inventory, \
                        patch.object(apple.time, "monotonic", side_effect=[0, 0, 0, 30, 30]), \
                        patch.object(apple.time, "sleep") as sleep:
                    with self.assertRaisesRegex(apple.DestinationError, "PAIR_CONNECTION_TIMEOUT"):
                        apple.wait_for_connection(self.destination(), timeout=30)
                inventory.assert_called_once_with(timeout=30)
                sleep.assert_not_called()

    def test_changed_pair_is_not_silently_replaced(self):
        data = fixture()
        data["pairs"]["pair"]["watch"]["udid"] = "different-watch"
        with patch.object(apple, "inventory", return_value=data):
            with self.assertRaisesRegex(apple.DestinationError, "PAIR_CHANGED"):
                apple.wait_for_connection(self.destination())

    def test_prepare_requires_connection_before_destination_discovery(self):
        with patch.object(apple, "inventory", return_value=fixture()), \
                patch.object(apple, "run", return_value="") as run, \
                patch.object(apple, "wait_for_connection", side_effect=apple.DestinationError("PAIR_CONNECTION_TIMEOUT")) as ready:
            with self.assertRaisesRegex(apple.DestinationError, "PAIR_CONNECTION_TIMEOUT"):
                apple.prepare(pair_timeout=45)
        self.assertEqual(ready.call_args.args[1], 45)
        self.assertTrue(all(call.args[0][:3] == ["xcrun", "simctl", "bootstatus"]
                            for call in run.call_args_list))

    def test_prepare_uses_selected_simulators_without_global_flutter_discovery(self):
        events = []

        def run(command, *args):
            self.assertNotEqual(command[0], "flutter")
            events.append(command)
            return "Available destinations: phone watch"

        destination = {}
        with patch.object(apple, "inventory", return_value=fixture()), \
                patch.object(apple, "run", side_effect=run), \
                patch.object(apple, "wait_for_connection", side_effect=lambda *args: events.append("ready")):
            result = apple.prepare(destination=destination)
        self.assertIs(result, destination)
        self.assertEqual(result["iphone"]["udid"], "phone")
        self.assertEqual(result["watch"]["udid"], "watch")
        self.assertEqual(events[2], "ready")
        self.assertEqual([event[event.index("-scheme") + 1] for event in events[3:]],
                         ["Runner", "HydrionWatch"])

    def test_watch_ineligible_destination_still_fails(self):
        def run(command, *args):
            if command[0] == "xcodebuild" and "HydrionWatch" in command:
                return "Available destinations: phone\nIneligible destinations: watch"
            return "Available destinations: phone watch"

        with patch.object(apple, "inventory", return_value=fixture()), \
                patch.object(apple, "run", side_effect=run):
            with self.assertRaisesRegex(apple.DestinationError, "XCODE_DESTINATION_REJECTED: HydrionWatch"):
                apple.prepare()

    @staticmethod
    def destination():
        return {"pair_id": "pair", "iphone": {"udid": "phone"}, "watch": {"udid": "watch"}}

    def test_connection_rechecked_before_each_install(self):
        events = []
        with patch.object(apple.Path, "is_dir", return_value=True), \
                patch.object(apple, "wait_for_connection", side_effect=lambda *args: events.append("ready")), \
                patch.object(apple, "run", side_effect=lambda command, *args: events.append(command) or ""):
            apple.build_and_launch(self.destination())
        self.assertEqual(events[1], "ready")
        self.assertEqual(events[2][:4], ["xcrun", "simctl", "install", "phone"])
        self.assertEqual(events[4], "ready")
        self.assertEqual(events[5][:4], ["xcrun", "simctl", "install", "watch"])
        self.assertEqual(events[6][:4], ["xcrun", "simctl", "launch", "watch"])

    def test_no_install_when_connection_is_lost_during_build(self):
        with patch.object(apple.Path, "is_dir", return_value=True), \
                patch.object(apple, "wait_for_connection", side_effect=apple.DestinationError("PAIR_CONNECTION_TIMEOUT")), \
                patch.object(apple, "run", return_value="") as run:
            with self.assertRaisesRegex(apple.DestinationError, "PAIR_CONNECTION_TIMEOUT"):
                apple.build_and_launch(self.destination())
        self.assertEqual(run.call_count, 1)
        self.assertEqual(run.call_args.args[0][:2], ["flutter", "build"])

    def test_watch_install_failure_is_not_retried_or_ignored(self):
        def run(command, *args):
            if command[:4] == ["xcrun", "simctl", "install", "watch"]:
                raise apple.DestinationError("APP_INSTALL_FAILED: timed out after 120s")
            return ""
        with patch.object(apple.Path, "is_dir", return_value=True), \
                patch.object(apple, "wait_for_connection"), \
                patch.object(apple, "run", side_effect=run) as calls:
            with self.assertRaisesRegex(apple.DestinationError, "APP_INSTALL_FAILED"):
                apple.build_and_launch(self.destination())
        commands = [call.args[0] for call in calls.call_args_list]
        self.assertEqual(sum(c[:4] == ["xcrun", "simctl", "install", "watch"] for c in commands), 1)
        self.assertFalse(any(c[:4] == ["xcrun", "simctl", "launch", "watch"] for c in commands))

    def test_each_install_and_launch_failure_is_fatal_without_success_output(self):
        for operation in ("install", "launch"):
            for device in ("phone", "watch"):
                with self.subTest(operation=operation, device=device), tempfile.TemporaryDirectory() as directory:
                    output = Path(directory) / "destination.json"
                    failed_command = ["xcrun", "simctl", operation, device]

                    def run(command, *args):
                        if command[:4] == failed_command:
                            raise apple.DestinationError("TEST_ACCEPTANCE_FAILURE")
                        return ""

                    with patch.object(sys, "argv", ["apple_simulator.py", "--output", str(output), "--build-and-launch"]), \
                            patch.object(apple, "prepare", return_value=self.destination()), \
                            patch.object(apple.Path, "is_dir", return_value=True), \
                            patch.object(apple, "wait_for_connection"), \
                            patch.object(apple, "run", side_effect=run) as commands, \
                            patch.object(apple, "failure_diagnostics", return_value={}), \
                            patch("builtins.print") as messages:
                        self.assertEqual(apple.main(), 1)
                    self.assertEqual(commands.call_args.args[0][:4], failed_command)
                    self.assertEqual(sum(call.args[0][:4] == failed_command
                                         for call in commands.call_args_list), 1)
                    self.assertFalse(any("Both launch requests succeeded" in str(call)
                                         for call in messages.call_args_list))
                    self.assertEqual(json.loads(output.read_text())["validation_status"], "failed")

    def test_failed_run_replaces_stale_success_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "destination.json"
            output.write_text('{"validation_status":"launched"}')
            with patch.object(sys, "argv", ["apple_simulator.py", "--output", str(output), "--build-and-launch"]), \
                    patch.object(apple, "prepare", return_value=self.destination()), \
                    patch.object(apple, "build_and_launch", side_effect=apple.DestinationError("APP_INSTALL_FAILED")), \
                    patch.object(apple, "failure_diagnostics", return_value={"memory": "captured"}), \
                    patch.object(apple, "disk_evidence", return_value={"free": 123}):
                self.assertEqual(apple.main(), 1)
            evidence = json.loads(output.read_text())
            self.assertEqual(evidence["validation_status"], "failed")
            self.assertEqual(evidence["error"], "APP_INSTALL_FAILED")
            self.assertEqual(evidence["diagnostics"]["memory"], "captured")
            self.assertEqual(evidence["disk_after"]["free"], 123)

    def test_success_evidence_distinguishes_readiness_from_launch(self):
        for launch in (False, True):
            with self.subTest(launch=launch), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / "destination.json"
                args = ["apple_simulator.py", "--output", str(output)]
                if launch:
                    args.append("--build-and-launch")
                with patch.object(sys, "argv", args), \
                        patch.object(apple, "prepare", return_value=self.destination()) as prepare, \
                        patch.object(apple, "build_and_launch") as build, \
                        patch.object(apple, "disk_evidence", return_value={}):
                    self.assertEqual(apple.main(), 0)
                prepare.assert_called_once_with(False, 900, 300, {})
                self.assertEqual(build.call_count, int(launch))
                self.assertEqual(json.loads(output.read_text())["validation_status"],
                                 "launched" if launch else "ready")

    def test_failed_diagnostics_remain_bounded(self):
        with patch.object(apple, "run", side_effect=apple.DestinationError("DIAGNOSTIC_FAILED")) as run:
            result = apple.failure_diagnostics(self.destination())
        self.assertEqual(len(result), 6)
        self.assertTrue(all(call.args[2] == 15 for call in run.call_args_list))
        self.assertTrue(all(value == "DIAGNOSTIC_FAILED" for value in result.values()))

    def test_prepare_failure_preserves_selected_devices_for_diagnostics(self):
        for stage in ("bootstatus", "xcodebuild"):
            with self.subTest(stage=stage), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / "destination.json"

                def run(command, *args):
                    if stage in command:
                        raise apple.DestinationError("TEST_FAILURE: timed out")
                    return "Available destinations: phone watch"

                with patch.object(sys, "argv", ["apple_simulator.py", "--output", str(output)]), \
                        patch.object(apple, "inventory", return_value=fixture()), \
                        patch.object(apple, "run", side_effect=run), \
                        patch.object(apple, "failure_diagnostics", return_value={}) as diagnostics:
                    self.assertEqual(apple.main(), 1)
                selected = diagnostics.call_args.args[0]
                self.assertEqual(selected["iphone"]["udid"], "phone")
                self.assertEqual(selected["watch"]["udid"], "watch")
                evidence = json.loads(output.read_text())
                self.assertEqual(evidence["validation_status"], "failed")
                self.assertEqual(evidence["pair_id"], "pair")
                journal = [json.loads(line) for line in output.with_suffix(".events.jsonl").read_text().splitlines()]
                self.assertEqual(journal[0]["event"], "pair_selected")

    def test_evidence_write_failure_returns_failure_and_resets_trace(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "destination.json"
            with patch.object(sys, "argv", ["apple_simulator.py", "--output", str(output)]), \
                    patch.object(apple, "prepare", return_value=self.destination()), \
                    patch.object(apple.Path, "write_text", side_effect=OSError("disk full")), \
                    patch.object(apple, "failure_diagnostics", return_value={}):
                self.assertEqual(apple.main(), 1)
            self.assertIsNone(apple.TRACE_PATH)

    def test_evidence_failure_does_not_swallow_keyboard_interrupt(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "destination.json"
            with patch.object(sys, "argv", ["apple_simulator.py", "--output", str(output)]), \
                    patch.object(apple, "prepare", side_effect=KeyboardInterrupt), \
                    patch.object(apple.Path, "write_text", side_effect=[None, OSError("disk full")]):
                with self.assertRaises(KeyboardInterrupt):
                    apple.main()
            self.assertIsNone(apple.TRACE_PATH)

    def test_final_evidence_write_failure_does_not_report_success(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "destination.json"
            with patch.object(sys, "argv", ["apple_simulator.py", "--output", str(output)]), \
                    patch.object(apple, "prepare", return_value=self.destination()), \
                    patch.object(apple.Path, "write_text", side_effect=[None, None, OSError("disk full")]):
                self.assertEqual(apple.main(), 1)
            self.assertIsNone(apple.TRACE_PATH)

    def test_no_return_exits_a_finally_block(self):
        source = Path(apple.__file__).read_text(encoding="utf-8")
        for node in ast.walk(ast.parse(source)):
            if isinstance(node, ast.Try):
                for statement in node.finalbody:
                    self.assertFalse(any(isinstance(child, ast.Return)
                                         for child in ast.walk(statement)))

    def test_success_log_does_not_report_a_failure_category(self):
        with patch.object(apple, "_run", return_value=""), patch("builtins.print") as output:
            apple.run(["simctl", "list"], "SIMCTL_FAILED")
        message = output.call_args.args[0]
        self.assertIn("Command result: success", message)
        self.assertNotIn("SIMCTL_FAILED", message)

    def test_command_journal_records_exact_command_duration_and_capacity(self):
        with tempfile.TemporaryDirectory() as directory:
            journal = Path(directory) / "events.jsonl"
            with patch.object(apple, "TRACE_PATH", journal), \
                    patch.object(apple, "disk_evidence", return_value={"free": 123}), \
                    patch.object(apple, "_run", return_value="installed"):
                apple.run(["simctl", "install", "watch", "app"], "APP_INSTALL_FAILED")
            start, end = [json.loads(line) for line in journal.read_text().splitlines()]
            self.assertEqual(start["status"], "running")
            self.assertEqual(start["command"], ["simctl", "install", "watch", "app"])
            self.assertEqual(end["status"], "success")
            self.assertEqual(end["capacity_before"]["free"], 123)
            self.assertGreaterEqual(end["duration_seconds"], 0)

    def test_command_journal_preserves_failed_command_and_diagnostic(self):
        with tempfile.TemporaryDirectory() as directory:
            journal = Path(directory) / "events.jsonl"
            with patch.object(apple, "TRACE_PATH", journal), \
                    patch.object(apple, "_run", side_effect=apple.DestinationError("APP_LAUNCH_FAILED: exit 3")):
                with self.assertRaisesRegex(apple.DestinationError, "APP_LAUNCH_FAILED"):
                    apple.run(["simctl", "launch", "watch", "bundle"], "APP_LAUNCH_FAILED")
            end = json.loads(journal.read_text().splitlines()[-1])
            self.assertEqual(end["status"], "failed")
            self.assertEqual(end["error"], "APP_LAUNCH_FAILED: exit 3")

    def test_capacity_includes_available_inodes_on_posix(self):
        stats = Mock(f_files=1000, f_favail=800)
        usage = Mock()
        usage._asdict.return_value = {"free": 123, "total": 456, "used": 333}
        with patch.object(apple.os, "statvfs", return_value=stats, create=True), \
                patch.object(apple.shutil, "disk_usage", return_value=usage):
            result = apple.disk_evidence()
        self.assertTrue(all(value["inodes_available"] == 800 for value in result.values()))
        self.assertTrue(all(value["free"] >= 0 for value in result.values()))

    def test_unavailable_capacity_is_explicit_not_fabricated(self):
        with patch.object(apple.shutil, "disk_usage", side_effect=PermissionError("denied")):
            result = apple.disk_evidence()
        self.assertTrue(all(value == {"measurement_error": "denied"} for value in result.values()))

    def test_launch_failure_still_fails_build_and_launch(self):
        def run(command, *args):
            if command[:3] == ["xcrun", "simctl", "launch"]:
                raise apple.DestinationError("APP_LAUNCH_FAILED")
            return ""
        with patch.object(apple.Path, "is_dir", return_value=True), \
                patch.object(apple, "wait_for_connection"), \
                patch.object(apple, "run", side_effect=run):
            with self.assertRaisesRegex(apple.DestinationError, "APP_LAUNCH_FAILED"):
                apple.build_and_launch(self.destination())


if __name__ == "__main__":
    unittest.main()
