#!/usr/bin/env python3
"""Discover a paired Apple simulator destination; never persist a fixed UDID.

Requires installed iOS/watchOS runtimes. --create-pair creates a new watch only
for an unpaired iPhone; it never unpairs, erases, or replaces an existing device.
All subprocesses are bounded, including bootstatus and Flutter/Xcode discovery.
"""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
TRACE_PATH = None


class DestinationError(RuntimeError):
    pass


def run(command, category, timeout=120):
    started = time.monotonic()
    event = {"command": command, "category": category, "timeout_seconds": timeout,
             "started_utc": datetime.now(timezone.utc).isoformat(), "status": "running"}
    try:
        event["capacity_before"] = disk_evidence()
        trace(event)
        output = _run(command, category, timeout)
        event.update(status="success", stdout=output[-16000:])
        return output
    except (DestinationError, OSError) as error:
        event.update(status="failed", error=str(error)[-16000:])
        raise
    finally:
        event["duration_seconds"] = round(time.monotonic() - started, 3)
        trace(event)
        print(f"Command result: {category} {event['status']} "
              f"in {event['duration_seconds']}s", flush=True)


def trace(event):
    # Append before and after each command so outer-job termination does not
    # erase the exact pending command or its last measured host capacity.
    if TRACE_PATH is not None:
        try:
            with TRACE_PATH.open("a", encoding="utf-8") as stream:
                stream.write(json.dumps(event) + "\n")
        except OSError as error:
            print(f"Could not append command evidence: {error}", file=sys.stderr)


def _run(command, category, timeout=120):
    print("+ " + " ".join(command), flush=True)
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True,
                               env={**os.environ, "LANG": "en_US.UTF-8", "LC_ALL": "en_US.UTF-8"},
                               start_new_session=True)
    cleanup_errors = []

    def stop(force=False):
        try:
            if os.name == "nt":
                process.kill() if force else process.terminate()
            else:
                os.killpg(process.pid, signal.SIGKILL if force else signal.SIGTERM)
        except OSError as error:
            # macOS may deny signaling a service-assisted process group. Try
            # the direct child, preserving the original timeout diagnosis.
            try:
                process.kill() if force else process.terminate()
            except OSError as child_error:
                cleanup_errors.append(f"cleanup failed: {error}; {child_error}")

    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        stop()
        try:
            stdout, stderr = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            stop(force=True)
            try:
                stdout, stderr = process.communicate(timeout=5)
            except subprocess.TimeoutExpired as error:
                stdout, stderr = error.stdout or b"", error.stderr or b""
                cleanup_errors.append("child did not exit after termination; inspect host processes")
        if isinstance(stdout, bytes):
            stdout = stdout.decode(errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode(errors="replace")
        raise DestinationError(f"{category}: timed out after {timeout}s\n"
                               f"{stdout[-2000:]}\n{stderr[-2000:]}\n" + "\n".join(cleanup_errors))
    finally:
        # Popen's context manager waits without a bound if termination fails.
        # CI also retains an independent outer step/job deadline.
        process.stdout.close()
        process.stderr.close()
    if process.returncode:
        raise DestinationError(
            f"{category}: exit {process.returncode}\n{stdout}\n{stderr}")
    return stdout


def inventory(timeout=120):
    return json.loads(run(["xcrun", "simctl", "list", "--json"], "SIMCTL_FAILED", timeout))


def wait_for_connection(destination, timeout=300):
    # Booted devices and eligible Xcode destinations do not prove that the
    # paired runtimes have finished establishing their companion connection.
    deadline = time.monotonic() + timeout
    state = "not observed"
    while time.monotonic() < deadline:
        data = inventory(timeout=min(30, max(0.1, deadline - time.monotonic())))
        pair = data.get("pairs", {}).get(destination["pair_id"], {})
        for role, key in (("phone", "iphone"), ("watch", "watch")):
            if pair.get(role, {}).get("udid") != destination[key]["udid"]:
                raise DestinationError("PAIR_CHANGED: selected pairing disappeared or changed")
        state = pair.get("state", "unknown")
        destination["pair_state"] = state
        states = {d["udid"]: d["state"] for devices in data["devices"].values() for d in devices}
        booted = all(states.get(destination[key]["udid"]) == "Booted"
                     for key in ("iphone", "watch"))
        trace({"event": "pair_state", "observed_utc": datetime.now(timezone.utc).isoformat(),
               "pair_id": destination["pair_id"], "state": state, "both_booted": booted})
        tokens = set(re.findall(r"[a-z]+", state.lower()))
        if booted and {"active", "connected"} <= tokens and not tokens & {"inactive", "disconnected"}:
            print(f"Pair ready: {destination['pair_id']} {state}", flush=True)
            return
        remaining = deadline - time.monotonic()
        if remaining > 0:
            print(f"Waiting for paired connection: {state}; both booted={booted}", flush=True)
            time.sleep(min(5, remaining))
    raise DestinationError(f"PAIR_CONNECTION_TIMEOUT: pair {destination['pair_id']} "
                           f"not connected after {timeout}s; last state={state}")


def disk_evidence():
    # Simulator data and the checkout can live on different volumes.
    result = {}
    for path in (ROOT, Path.home()):
        try:
            capacity = shutil.disk_usage(path)._asdict()
            if hasattr(os, "statvfs"):
                stats = os.statvfs(path)
                capacity.update(inodes_total=stats.f_files, inodes_available=stats.f_favail)
        except OSError as error:
            capacity = {"measurement_error": str(error)}
        result[str(path)] = capacity
    return result


def failure_diagnostics(destination):
    commands = {"simulators": ["xcrun", "simctl", "list", "--json"],
                "memory": ["vm_stat"],
                "disk_inodes": ["df", "-ki", str(ROOT), str(Path.home())],
                "coresimulator": ["log", "show", "--last", "5m", "--style", "compact",
                                  "--predicate", 'process == "CoreSimulatorService"']}
    if destination:
        for role in ("iphone", "watch"):
            commands[f"{role}_installer"] = [
                "xcrun", "simctl", "spawn", destination[role]["udid"],
                "log", "show", "--last", "2m", "--style", "compact", "--predicate",
                'process == "installd" OR process == "appinstalld"']
    result = {}
    for key, command in commands.items():
        try:
            result[key] = run(command, "DIAGNOSTIC_FAILED", 15)[-16000:]
        except (DestinationError, OSError) as error:
            result[key] = str(error)[-16000:]
    return result


def version(value):
    return tuple(int(part) for part in value.split("."))


def candidates(data, platform, minimum):
    runtimes = {runtime["identifier"]: runtime for runtime in data["runtimes"]
                if runtime.get("isAvailable") and
                f".SimRuntime.{platform}-" in runtime["identifier"] and
                version(runtime["version"]) >= version(minimum)}
    if not runtimes:
        raise DestinationError(f"NO_{platform.upper()}_RUNTIME: install an available "
                               f"{platform} runtime >= {minimum} compatible with Xcode")
    prefix = "iPhone" if platform == "iOS" else "Apple-Watch"
    devices = []
    for runtime_id, runtime in runtimes.items():
        for device in data["devices"].get(runtime_id, []):
            if device.get("isAvailable") and prefix in device.get("deviceTypeIdentifier", ""):
                devices.append({**device, "runtime": runtime})
    return sorted(devices, key=lambda d: (version(d["runtime"]["version"]),
                                          d["name"], d["udid"]), reverse=True)


def select_pair(data, ios_min, watch_min):
    phones = candidates(data, "iOS", ios_min)
    if not phones:
        raise DestinationError("NO_IPHONE: no available iPhone simulator")
    watches = candidates(data, "watchOS", watch_min)
    if not watches:
        raise DestinationError("NO_APPLE_WATCH: no available Apple Watch simulator")
    for phone in phones:
        for pair_id, pair in sorted(data.get("pairs", {}).items(),
                                    key=lambda item: ("inactive" in item[1].get("state", ""), item[0])):
            if pair.get("phone", {}).get("udid") != phone["udid"]:
                continue
            for watch in watches:
                if pair.get("watch", {}).get("udid") == watch["udid"]:
                    return phone, watch, pair_id
    raise DestinationError("NOT_PAIRED: available simulators have no compatible pair; "
                           "pair them in Xcode or use --create-pair")


def create_pair(data, ios_min, watch_min):
    # simctl, rather than a guessed OS-version matrix, validates compatibility.
    phones = candidates(data, "iOS", ios_min)
    candidates(data, "watchOS", watch_min)  # fail before creating anything
    paired = {pair.get("phone", {}).get("udid") for pair in data.get("pairs", {}).values()}
    phones = [phone for phone in phones if phone["udid"] not in paired]
    if not phones:
        raise DestinationError("NOT_PAIRED: no unpaired iPhone; existing pairs preserved")
    runtimes = sorted((r for r in data["runtimes"] if r.get("isAvailable") and
                       ".watchOS-" in r["identifier"] and
                       version(r["version"]) >= version(watch_min)),
                      key=lambda r: version(r["version"]), reverse=True)
    for runtime in runtimes[:3]:
        # supportedDeviceTypes avoids creating hardware newer than the runtime.
        types = [t for t in runtime.get("supportedDeviceTypes", [])
                 if "Apple-Watch" in t["identifier"]]
        if not types:
            continue
        watch = run(["xcrun", "simctl", "create", "HydrionWatchValidation",
                     types[-1]["identifier"], runtime["identifier"]], "WATCH_CREATE_FAILED").strip()
        for phone in phones[:5]:
            try:
                run(["xcrun", "simctl", "pair", watch, phone["udid"]], "PAIR_REJECTED", 30)
                return
            except DestinationError as error:
                print(error, file=sys.stderr)
        # Preserve created devices for diagnostics; never delete user simulators.
    raise DestinationError("NOT_PAIRED: simctl rejected the bounded pairing attempts")


def prepare(create=False, boot_timeout=900, pair_timeout=300):
    project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text()
    ios_min = max(re.findall(r"IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);", project), key=version)
    watch_min = max(re.findall(r"WATCHOS_DEPLOYMENT_TARGET = ([\d.]+);", project), key=version)
    data = inventory()
    try:
        phone, watch, pair_id = select_pair(data, ios_min, watch_min)
    except DestinationError as error:
        if not create or not str(error).startswith(("NOT_PAIRED:", "NO_APPLE_WATCH:")):
            raise
        create_pair(data, ios_min, watch_min)
        data = inventory()
        phone, watch, pair_id = select_pair(data, ios_min, watch_min)
    if "inactive" in data["pairs"][pair_id].get("state", ""):
        run(["xcrun", "simctl", "pair_activate", pair_id], "PAIR_ACTIVATION_FAILED", 60)
    for role, device in (("iPhone", phone), ("Apple Watch", watch)):
        print(f"Selected {role}: {device['name']} ({device['deviceTypeIdentifier']}), "
              f"OS {device['runtime']['version']}, UDID {device['udid']}; "
              f"pair {pair_id} {data['pairs'][pair_id].get('state')}", flush=True)
    # Finish the smaller watch's first boot before starting the phone. This
    # avoids two simultaneous migrations on memory-constrained development Macs.
    for device in (watch, phone):
        if device["state"] != "Booted":
            run(["xcrun", "simctl", "boot", device["udid"]], "PAIR_BOOT_FAILED", 180)
        run(["xcrun", "simctl", "bootstatus", device["udid"], "-b"], "PAIR_BOOT_FAILED", boot_timeout)
    fresh = inventory()
    states = {d["udid"]: d["state"] for devices in fresh["devices"].values() for d in devices}
    if any(states.get(d["udid"]) != "Booted" for d in (phone, watch)):
        raise DestinationError("PAIR_BOOT_FAILED: both devices must report Booted")
    flutter = json.loads(run(["flutter", "devices", "--machine", "--device-timeout", "30"],
                             "FLUTTER_DEVICE_DISCOVERY_FAILED", 90))
    if not any(d["id"] == phone["udid"] for d in flutter):
        raise DestinationError("FLUTTER_IPHONE_NOT_EXPOSED: booted iPhone is absent from flutter devices")
    for scheme, device in (("Runner", phone), ("HydrionWatch", watch)):
        destinations = run(["xcodebuild", "-workspace", "ios/Runner.xcworkspace", "-scheme", scheme,
                            "-showdestinations", "-destination-timeout", "30"], "XCODE_DESTINATION_REJECTED", 180)
        eligible = destinations.split("Ineligible destinations")[0]
        if device["udid"] not in eligible:
            raise DestinationError(f"XCODE_DESTINATION_REJECTED: {scheme}\n{destinations}")
    result = {"pair_id": pair_id, "pair_state": fresh["pairs"][pair_id].get("state"),
              "iphone": {}, "watch": {}}
    for key, device in (("iphone", phone), ("watch", watch)):
        result[key] = {"name": device["name"], "udid": device["udid"],
                       "model": device["deviceTypeIdentifier"].split(".")[-1],
                       "os": device["runtime"]["version"], "state": states[device["udid"]]}
    wait_for_connection(result, pair_timeout)
    print(json.dumps(result, indent=2), flush=True)
    return result


def build_and_launch(destination, pair_timeout=300):
    phone, watch = destination["iphone"]["udid"], destination["watch"]["udid"]
    print(run(["flutter", "build", "ios", "--simulator", "--debug", "--no-pub", "-d", phone],
              "COMPILATION_FAILED_AFTER_DESTINATION_SELECTION", 1800), flush=True)
    app = ROOT / "build/ios/iphonesimulator/Runner.app"
    watch_app = app / "Watch/HydrionWatch.app"
    if not watch_app.is_dir():
        raise DestinationError("WATCH_NOT_EMBEDDED: Runner.app/Watch/HydrionWatch.app missing")
    for device, product, bundle in ((phone, app, "com.the1807.hydrion"),
                                    (watch, watch_app, "com.the1807.hydrion.watchkitapp")):
        # Compilation and phone installation can take minutes; recheck rather
        # than trusting the earlier discovery snapshot for either install.
        wait_for_connection(destination, pair_timeout)
        run(["xcrun", "simctl", "install", device, str(product)], "APP_INSTALL_FAILED", 120)
        print(run(["xcrun", "simctl", "launch", device, bundle], "APP_LAUNCH_FAILED", 60))
    print("Both launch requests succeeded. UI and communication acceptance require behavioral tests.")


def main():
    global TRACE_PATH
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--create-pair", action="store_true")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--build-and-launch", action="store_true")
    parser.add_argument("--boot-timeout", type=int, default=900,
                        help="Per-device readiness limit in seconds (30..1200; default 900)")
    parser.add_argument("--pair-timeout", type=int, default=300,
                        help="Paired connection readiness limit in seconds (30..600; default 300)")
    args = parser.parse_args()
    if not 30 <= args.boot_timeout <= 1200:
        parser.error("--boot-timeout must be between 30 and 1200 seconds")
    if not 30 <= args.pair_timeout <= 600:
        parser.error("--pair-timeout must be between 30 and 600 seconds")
    destination = None
    evidence = {"validation_status": "failed"}
    try:
        # Never leave stale successful destination evidence after a failed run.
        args.output.unlink(missing_ok=True)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        TRACE_PATH = args.output.with_suffix(".events.jsonl")
        TRACE_PATH.write_text("", encoding="utf-8")
        evidence["disk_before"] = disk_evidence()
        destination = prepare(args.create_pair, args.boot_timeout, args.pair_timeout)
        evidence.update(destination)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        # Keep an explicitly incomplete snapshot if the outer CI deadline
        # terminates the process during a build or install.
        evidence["validation_status"] = "running"
        args.output.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
        if args.build_and_launch:
            build_and_launch(destination, args.pair_timeout)
        evidence.update(destination)
        evidence["validation_status"] = "launched" if args.build_and_launch else "ready"
    except (DestinationError, OSError, ValueError, KeyError) as error:
        evidence["validation_status"] = "failed"
        evidence["error"] = str(error)
        evidence["diagnostics"] = failure_diagnostics(destination)
        print(f"Apple simulator validation failed: {error}", file=sys.stderr)
        return 1
    finally:
        if destination:
            evidence.update(destination)
        try:
            evidence["disk_after"] = disk_evidence()
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
        except OSError as error:
            print(f"Could not write simulator evidence: {error}", file=sys.stderr)
            return 1
        finally:
            TRACE_PATH = None
    return 0


if __name__ == "__main__":
    sys.exit(main())
