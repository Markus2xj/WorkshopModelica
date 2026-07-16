"""
cosimulate.py
=============

Co-simulate the exported `Standalone_House` FMU and demonstrate distribution-
grid congestion management by controlling the heat pump's `Force_off` input.

The house is run twice: a baseline (never curtailed) and an "active" run driven
by a controller you choose. The controller can be:

  * forcing_policy  -- a hands-on 0/1 signal you draw by editing forcing_signal
  * dr_policy       -- a window + comfort-guard demand-response controller
  * baseline_policy -- never curtails

Pick one with ACTIVE_POLICY below. Reading internal signals (power, temperature,
discomfort) works even if they aren't promoted, because Modelica tools export
them as `local` variables.
"""

import os
import csv

from helpers import (load_fmu, close_fmu, build_fmu_context,
                     discover_variables, resolve, set_input, to_celsius)

# ---------------------------------------------------------------------------
# Configuration -- adjust to match your exported FMU
# ---------------------------------------------------------------------------

# Path to the FMU exported from Standalone_House (with Force_Off as an input)
FMU_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Standalone_House.fmu")

START_TIME = 0.0
END_TIME = 24 * 3600.0        # one day, matches the model's StopTime
TIMESTEP = 60.0               # 60 s, matches the model's Interval

# Optional init-time parameters (set via helpers.set_fmu_parameters).
# e.g. {"init_Tint": 293.0}
PARAMETERS = {}

# Candidate variable names. The FMU flattens the Modelica hierarchy with dotted
# names; the exact prefix depends on your instance names. The resolver below
# tries each candidate in order and uses the first one present in the FMU.
FORCE_OFF_CANDIDATES = [
    "Force_Off",                                    # top-level FMU input (your name)
    "ForceOff",
    "house.ForceOff",
    "Force_off",
    "house.heatpump.heatpump_control.Force_off",   # internal local (not settable)
]

HP_POWER_CANDIDATES = [
    "house.heatpump.heatpump_control.ElectricPowerConsumption",
    "house.heatpump.loa.P",
    "P_hp",
]

TINDOOR_CANDIDATES = [
    "house.comfort_model.temperatureSensor.T",     # deg C
    "house.building_Envelope.Cinternal.T",         # Kelvin
    "Tint",
]

DISCOMFORT_CANDIDATES = [
    "house.comfort_model.Discomfort_hours",
    "Discomfort_hours",
]

PV_POWER_CANDIDATES = [
    "house.Solar_PV.P",
    "house.Solar_PV.terminal.v",                   # fallback, not power
]

# Congestion windows in hours-of-day where the operator asks for curtailment.
# Typical residential heat-pump peaks: morning ramp + evening peak.
CONGESTION_WINDOWS = [(6.0, 9.0), (17.0, 21.0)]

# Comfort guard: do not curtail if the house is already colder than this (deg C).
# Prevents the DR controller from causing discomfort to the occupants.
COMFORT_FLOOR_C = 19.0

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(OUT_DIR, "cosim_results.csv")
PNG_PATH = os.path.join(OUT_DIR, "cosim_congestion.png")


def in_congestion_window(t_hours):
    return any(lo <= t_hours < hi for lo, hi in CONGESTION_WINDOWS)


# ===========================================================================
#  Controllers -- three ways to drive the heat pump. Each is a
#  policy(t_seconds, tindoor_c) -> truthy, where True/1 forces the pump OFF.
# ===========================================================================

# --- Option 1: hands-on forcing signal  --  EDIT ME ------------------------

def forcing_signal(t_hours, t_indoor_c=None):
    """
    Return 1 to force the heat pump OFF, 0 to let it run. `t_hours` is the time
    of day (0..24). `t_indoor_c` is available if you want to react to Temperature.

    Ideas to try (just replace the body):
        two peaks : return 1 if (6 <= t_hours < 9) or (17 <= t_hours < 21) else 0
    """
    if 17 <= t_hours < 21:
        return 1
    return 0


def forcing_policy(t_seconds, tindoor_c):
    """Adapter so forcing_signal plugs into simulate()'s policy interface."""
    return forcing_signal((t_seconds / 3600.0) % 24.0, tindoor_c)


# --- Option 2: window + comfort-guard demand response ----------------------

def dr_policy(t_seconds, tindoor_c):
    """
    Returns True (force off) when the operator has declared congestion AND the
    house is still warm enough (above COMFORT_FLOOR_C) to tolerate a pause.
    """
    t_hours = (t_seconds / 3600.0) % 24.0
    if not in_congestion_window(t_hours):
        return False
    if tindoor_c is not None and tindoor_c <= COMFORT_FLOOR_C:
        return False  # comfort guard overrides curtailment
    return True


# --- Option 3: baseline (never curtails) -----------------------------------

def baseline_policy(t_seconds, tindoor_c):
    return False


# ===========================================================================
#  >>> CHOOSE THE ACTIVE CONTROLLER HERE <<<
#  Swap freely between forcing_policy / dr_policy / baseline_policy.
# ===========================================================================
ACTIVE_POLICY = forcing_policy
ACTIVE_LABEL = "Flexible Scenario"


# ---------------------------------------------------------------------------
# Simulation driver
# ---------------------------------------------------------------------------

def simulate(policy, fmu_context, label=""):
    """
    Run one full-day co-simulation applying `policy(t, tindoor_c) -> bool`
    to the Force_off input each step. Returns a dict of time series.
    """
    fmu, vrs, var_info, unzipdir = load_fmu(
        filepath=FMU_PATH,
        start_time=START_TIME,
        parameters=PARAMETERS or None,
        fmu_context=fmu_context,
    )

    try:
        force_name = resolve(vrs, FORCE_OFF_CANDIDATES, "Force_off", required=True)
        hp_name = resolve(vrs, HP_POWER_CANDIDATES, "heat pump power", required=True)
        t_name = resolve(vrs, TINDOOR_CANDIDATES, "indoor temperature", required=True)
        d_name = resolve(vrs, DISCOMFORT_CANDIDATES, "discomfort", required=False)
        pv_name = resolve(vrs, PV_POWER_CANDIDATES, "PV power", required=False)

        # Warn if Force_off is not actually a settable input.
        if var_info[force_name].causality != "input":
            print(
                f"[{label}] WARNING: '{force_name}' has causality "
                f"'{var_info[force_name].causality}', not 'input'. It cannot be "
                f"set during co-simulation.\n"
                f"  -> Promote Force_off to a top-level BooleanInput on "
                f"Standalone_House and re-export the FMU."
            )

        series = {k: [] for k in
                  ("t_h", "force_off", "p_hp", "t_in_c", "discomfort_h", "p_pv")}

        cur = START_TIME
        while cur < END_TIME:
            step = min(TIMESTEP, END_TIME - cur)

            # --- read state needed by the controller ---
            t_in_c = to_celsius(fmu.getReal([vrs[t_name]])[0])

            # --- controller decides, we inject the command ---
            cmd = policy(cur, t_in_c)
            set_input(fmu, vrs, var_info, force_name, cmd)

            # --- advance ---
            fmu.doStep(currentCommunicationPoint=cur,
                       communicationStepSize=step)

            # --- log ---
            p_hp = fmu.getReal([vrs[hp_name]])[0]
            disc = fmu.getReal([vrs[d_name]])[0] if d_name else float("nan")
            p_pv = fmu.getReal([vrs[pv_name]])[0] if pv_name else float("nan")

            series["t_h"].append(cur / 3600.0)
            series["force_off"].append(1.0 if cmd else 0.0)
            series["p_hp"].append(p_hp)
            series["t_in_c"].append(t_in_c)
            series["discomfort_h"].append(disc)
            series["p_pv"].append(p_pv)

            cur += step
    finally:
        close_fmu(fmu, unzipdir)

    return series


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def summarize(label, s):
    hp = s["p_hp"]
    dt_h = TIMESTEP / 3600.0
    energy_kwh = sum(hp) * dt_h / 1000.0
    peak_w = max(hp) if hp else 0.0
    peak_window_w = max(
        (p for t, p in zip(s["t_h"], hp) if in_congestion_window(t % 24.0)),
        default=0.0,
    )
    window_energy_kwh = sum(
        p for t, p in zip(s["t_h"], hp) if in_congestion_window(t % 24.0)
    ) * dt_h / 1000.0
    final_disc = next((d for d in reversed(s["discomfort_h"]) if d == d), float("nan"))
    print(f"\n--- {label} ---")
    print(f"  Heat pump energy over the day : {energy_kwh:8.2f} kWh")
    print(f"  Energy in congestion windows  : {window_energy_kwh:8.2f} kWh")   # >>> ADD
    print(f"  Peak heat pump power          : {peak_w:8.0f} W")
    print(f"  Peak power in congestion win. : {peak_window_w:8.0f} W")
    print(f"  Final discomfort hours        : {final_disc:8.2f} h")
    return dict(energy_kwh=energy_kwh, window_energy_kwh=window_energy_kwh,   # >>> ADD
                peak_w=peak_w, peak_window_w=peak_window_w, final_disc=final_disc)


def write_csv(base, active):
    with open(CSV_PATH, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["t_h",
                    "p_hp_baseline_W", "t_in_baseline_C", "discomfort_baseline_h",
                    "force_off_active", "p_hp_active_W", "t_in_active_C",
                    "discomfort_active_h"])
        for i in range(len(base["t_h"])):
            w.writerow([f"{base['t_h'][i]:.4f}",
                        f"{base['p_hp'][i]:.2f}", f"{base['t_in_c'][i]:.3f}",
                        f"{base['discomfort_h'][i]:.4f}",
                        f"{active['force_off'][i]:.0f}", f"{active['p_hp'][i]:.2f}",
                        f"{active['t_in_c'][i]:.3f}", f"{active['discomfort_h'][i]:.4f}"])
    print(f"\nWrote time series -> {CSV_PATH}")


def make_plot(base, active, active_label=ACTIVE_LABEL):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed; skipping plot (CSV still written).")
        return

    fig, ax = plt.subplots(3, 1, figsize=(11, 9), sharex=True)

    ax[0].plot(base["t_h"], base["p_hp"], label="Baseline", color="tab:red")
    ax[0].plot(active["t_h"], active["p_hp"], label=active_label, color="tab:blue")
    ax[0].set_ylabel("Heat pump power [W]")
    ax[0].legend(loc="upper left")
    ax[0].set_title("Congestion management via heat pump curtailment")

    ax[1].plot(base["t_h"], base["t_in_c"], label="Baseline", color="tab:red")
    ax[1].plot(active["t_h"], active["t_in_c"], label=active_label, color="tab:blue")
    ax[1].axhline(COMFORT_FLOOR_C, ls=":", color="gray", label="Comfort floor")
    ax[1].set_ylabel("Indoor temp [degC]")
    ax[1].legend(loc="upper left")

    ax[2].plot(base["t_h"], base["discomfort_h"], label="Baseline", color="tab:red")
    ax[2].plot(active["t_h"], active["discomfort_h"], label=active_label, color="tab:blue")
    ax[2].set_ylabel("Cumulative discomfort [h]")
    ax[2].set_xlabel("Time [h]")
    ax[2].legend(loc="upper left")

    # # shade every congestion window defined in CONGESTION_WINDOWS
    # for a in ax:
    #     for lo, hi in CONGESTION_WINDOWS:
    #         a.axvspan(lo, hi, color="orange", alpha=0.12)

    # optional: also mark when the active controller forced the pump off
    for a in ax:
        a.fill_between(active["t_h"], *a.get_ylim(),
                       where=[x == 1.0 for x in active["force_off"]],
                       color="tab:blue", alpha=0.10, step="post")

    fig.tight_layout()
    fig.savefig(PNG_PATH, dpi=130)
    print(f"Wrote figure     -> {PNG_PATH}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if not os.path.isfile(FMU_PATH):
        raise FileNotFoundError(
            f"FMU not found at {FMU_PATH}. Export Standalone_House as a "
            f"co-simulation FMU and update FMU_PATH."
        )

    # One-time metadata read so both runs skip repeated XML validation.
    discover_variables(FMU_PATH)
    ctx = build_fmu_context(FMU_PATH, validate=True)

    print("\nRunning baseline (no curtailment)...")
    base = simulate(baseline_policy, ctx, label="baseline")

    print(f"Running active controller ({ACTIVE_LABEL})...")
    active = simulate(ACTIVE_POLICY, ctx, label=ACTIVE_LABEL)

    b = summarize("Baseline", base)
    a = summarize(ACTIVE_LABEL, active)

    if b["peak_window_w"] > 0:
        cut = 100.0 * (1 - a["peak_window_w"] / b["peak_window_w"])
        print(f"\nPeak-window power reduced by {cut:.1f}% "
              f"for {a['final_disc'] - b['final_disc']:+.2f} h extra discomfort.")

    write_csv(base, active)
    make_plot(base, active)


if __name__ == "__main__":
    main()