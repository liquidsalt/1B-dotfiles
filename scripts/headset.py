#!/usr/bin/env python3
# dependencies: python3. Prints "<percent> <millivolts> mV", or exits 1 if absent.
# Python, not bash: the charge is a HID feature report, and bash cannot ioctl.

import array, fcntl, glob, os, sys, time

VENDOR = "1532"

# The dongle answers whether the headset is on the charger; 051F is the
# headset's own interface, present only while it is on the cable.
PRODUCTS = ["051E", "051F"]

REPORT_ID = 0xFF
SIZE      = 64                        # 1 id + 63 payload
QUERY     = bytes([0xFF, 0x0A, 0x00, 0xFD, 0x04, 0x12, 0xF1, 0x02, 0x05])

# Voltage is the measurement; percent is this table read backwards.
# Single-cell Li-ion at rest, 4.20 V charged to 3.30 V empty.
CURVE = [
    (4200, 100), (4100, 90), (4000, 80), (3930, 70), (3870, 60),
    (3830,  50), (3790, 40), (3770, 30), (3740, 20), (3680, 10),
    (3500,   5), (3300,  0),
]


def _hid_ioctl(nr):
    return (3 << 30) | (SIZE << 16) | (ord("H") << 8) | nr   # _IOC(rw,'H',nr,SIZE)


HIDIOCSFEATURE = _hid_ioctl(0x06)
HIDIOCGFEATURE = _hid_ioctl(0x07)


def nodes():
    wanted = ["0003:0000%s:0000%s" % (VENDOR, p) for p in PRODUCTS]
    found = {}
    for node in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        try:
            with open(os.path.join(node, "device", "uevent")) as fh:
                uevent = fh.read().upper()
        except OSError:
            continue
        for want in wanted:
            if want in uevent and want not in found:
                found[want] = "/dev/" + os.path.basename(node)
    return [found[w] for w in wanted if w in found]


def exchange(fd):
    out = array.array("B", QUERY + bytes(SIZE - len(QUERY)))
    fcntl.ioctl(fd, HIDIOCSFEATURE, out, True)
    back = array.array("B", bytes([REPORT_ID]) + bytes(SIZE - 1))
    fcntl.ioctl(fd, HIDIOCGFEATURE, back, True)
    frame = bytes(back)
    return (frame[12] << 8) | frame[13]


def millivolts(path):
    # A dongle whose headset is off answers zeroed, and so does one whose
    # headset has only just woken. Retry before calling it absence.
    fd = os.open(path, os.O_RDWR)
    try:
        for attempt in range(3):
            if attempt:
                time.sleep(0.2)
            found = exchange(fd)
            if found:
                return found
    finally:
        os.close(fd)
    return 0


def percent(mv):
    if mv >= CURVE[0][0]:
        return CURVE[0][1]
    for (hi_mv, hi_pc), (lo_mv, lo_pc) in zip(CURVE, CURVE[1:]):
        if mv >= lo_mv:
            span = hi_mv - lo_mv
            return int(round(lo_pc + (mv - lo_mv) * (hi_pc - lo_pc) / span))
    return 0


paths = nodes()
if not paths:
    print("headset: no Nari hidraw node; is the dongle plugged in?", file=sys.stderr)
    sys.exit(1)

for path in paths:
    try:
        mv = millivolts(path)
    except PermissionError:
        # The uaccess rule in nixos/modules/hardware.nix is what grants this.
        print("headset: %s: permission denied, udev rule missing" % path, file=sys.stderr)
        continue
    except OSError as exc:
        print("headset: %s: %s" % (path, exc), file=sys.stderr)
        continue
    if mv:
        print("%d %d mV" % (percent(mv), mv))
        sys.exit(0)

print("headset: device present but no charge reported; headset is off", file=sys.stderr)
sys.exit(1)
