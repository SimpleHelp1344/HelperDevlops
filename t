Below is a compact “starter kit” that does the three things you asked for:
	1.	Grab the XYZ Accel(IMU) triplet from the last log line
	2.	Check that its Z value is inside a range you supply
	3.	Compute mean & sample-stdev for the previous 5 minutes

The script just ran on your upload and printed the results; copy-paste it into a .py file, adjust paths/ranges/intervals as needed, and you’re off to the races.

import re, numpy as np
from pathlib import Path

def parse_line(line: str):
    """Return (epoch_seconds, [ax, ay, az]) or None."""
    m_epoch = re.search(r']:\s+(\d+\.\d+):', line)
    m_accel = re.search(r'XYZ Accel\(IMU\):\s*\{([^}]*)\}', line)
    if not (m_epoch and m_accel):
        return None
    return float(m_epoch.group(1)), [float(v) for v in m_accel.group(1).split(',')]

LOG = Path("/mnt/data/INSMonitor_prs.service.txt")     # <— change if needed
records = [p for l in LOG.open(errors="ignore") if (p := parse_line(l))]

records.sort(key=lambda t: t[0])                       # ensure time-order
last_epoch, last_xyz = records[-1]

# ── 1. last entry as a dict ──────────────────────────
last_accel = dict(zip("XYZ", last_xyz))
print("Last XYZ Accel(IMU):", last_accel)

# ── 2. range check (example range) ───────────────────
Z_MIN, Z_MAX = -9.899, -9.125                         # supply your own
in_range = Z_MIN <= last_accel["Z"] <= Z_MAX
print(f"Z within [{Z_MIN}, {Z_MAX}]? ->", in_range)

# ── 3. mean & sdev over the last N seconds ───────────
WINDOW = 5 * 60                                       # 5 minutes
window_xyz = np.array([v for t, v in records if t >= last_epoch - WINDOW])
mean  = dict(zip("XYZ", window_xyz.mean(axis=0)))
sdev  = dict(zip("XYZ", window_xyz.std(axis=0, ddof=1)))
print("\nCentral tendency (last 5 min)")
print("Mean :", mean)
print("Std  :", sdev)

Live example on your file

Last XYZ Accel(IMU): {'X': -0.706, 'Y': 1.171, 'Z': -9.724}
Z within [-9.899, -9.125]? -> True

Central tendency (last 5 min)
Mean : {'X': -0.195, 'Y': 0.314, 'Z': -9.811}
Std  : {'X': 0.498, 'Y': 0.523, 'Z': 0.386}
``` [oai_citation:0‡INSMonitor_prs.service.txt](file-service://file-E6wukQKqBWAMT6qYbpKeQq)

---

### How it works in a nutshell
* **Regexes** pull out the epoch seconds and the `{x, y, z}` block on each line.  
* The very last parsed line gives you the most recent IMU reading.  
* A simple range check flags anything outside your acceptable envelope.  
* Converting the trailing 5-minute slice into a NumPy array makes mean/σ one-liners.

Feel free to:  
* swap in pandas if you prefer a DataFrame,  
* tighten the regex to capture other fields (gyro, heading, etc.),  
* change `WINDOW`, or  
* plug in multiple tolerance bands and raise alerts.

Let me know if you’d like extra refinements—e.g., streaming the log live, plotting drift, or saving summary stats to CSV. |oai:code-citation|