#!/usr/bin/env python3
# data_prep.py - Prepare datasets for Hydrion.ai model training
# Usage:
#   python3 models/training/data_prep.py \
#     --samples 12000 --outdir models/training/data
#
# Outputs:
#   models/training/data/hydration_data.csv
#   models/training/data/sentiment_data.csv
#   models/training/data/feature_schema.json
#   models/training/data/stats.json
#
# Author: Hydrion.ai Team
# Version: 1.1

import os
import sys
import json
import math
import time
import argparse
import logging
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler


def setup_logger(log_path: Path) -> logging.Logger:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("data_prep")
    logger.setLevel(logging.INFO)
    fmt = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.INFO)
    ch.setFormatter(fmt)
    logger.addHandler(ch)

    fh = logging.FileHandler(str(log_path), mode="a")
    fh.setLevel(logging.INFO)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    return logger


def seed_everything(seed: int = 42) -> None:
    np.random.seed(seed)


def clamp(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    return np.minimum(np.maximum(x, lo), hi)


def create_hydration_dataset(samples: int, out_csv: Path, logger: logging.Logger) -> None:
    seed_everything(42)
    logger.info("Generating synthetic hydration dataset with %d samples", samples)

    weight_kg = np.random.uniform(45.0, 130.0, samples)
    activity_min = np.random.uniform(0.0, 180.0, samples)
    temp_c = np.random.uniform(-5.0, 45.0, samples)
    humidity_percent = np.random.uniform(10.0, 95.0, samples)
    is_pregnant = np.random.choice([0, 1], size=samples, p=[0.92, 0.08])
    is_breastfeeding = np.random.choice([0, 1], size=samples, p=[0.96, 0.04])
    altitude_m = np.random.uniform(0.0, 4200.0, samples)

    # Base target: 30 to 35 ml per kg
    base_ml_per_kg = np.random.uniform(30.0, 35.0, samples)
    base_target = weight_kg * base_ml_per_kg

    # Exercise water: 6 to 12 ml per active minute depending on temp
    temp_factor = np.interp(temp_c, [-5, 45], [0.6, 1.2])
    exercise_bonus = activity_min * (10.0 * temp_factor)

    # Temperature adjustment: hotter needs more, colder slightly less
    temp_adjust = (temp_c - 20.0) * 40.0

    # Humidity adjustment: high humidity reduces evaporative cooling
    humidity_adjust = (humidity_percent - 50.0) * 2.0

    # Pregnancy and breastfeeding adjustments
    preg_bonus = is_pregnant * 300.0
    lact_bonus = is_breastfeeding * 700.0

    # Altitude adjustment above 2500 m
    altitude_adjust = np.where(altitude_m > 2500.0, (altitude_m - 2500.0) * 0.04, 0.0)

    target_ml = base_target + exercise_bonus + temp_adjust + humidity_adjust + preg_bonus + lact_bonus + altitude_adjust

    # Reasonable clamp: 1200 ml to 7000 ml
    target_ml = clamp(target_ml, 1200.0, 7000.0)

    df = pd.DataFrame(
        {
            "weight_kg": weight_kg,
            "activity_min": activity_min,
            "temp_c": temp_c,
            "humidity_percent": humidity_percent,
            "is_pregnant": is_pregnant,
            "is_breastfeeding": is_breastfeeding,
            "altitude_m": altitude_m,
            "target_ml": target_ml,
        }
    )

    # Scale only continuous features for model stability; persist scaler for training parity checks
    cont_cols = ["weight_kg", "activity_min", "temp_c", "humidity_percent", "altitude_m"]
    scaler = StandardScaler()
    df[cont_cols] = scaler.fit_transform(df[cont_cols])

    out_csv.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out_csv, index=False)
    logger.info("Hydration dataset saved -> %s", out_csv)


def create_sentiment_dataset(samples: int, out_csv: Path, logger: logging.Logger) -> None:
    seed_everything(123)
    logger.info("Generating synthetic sentiment dataset with %d samples", samples)

    # Acoustic features
    speech_rate = np.random.uniform(90.0, 220.0, samples)  # words per minute
    pitch_hz = np.random.uniform(70.0, 320.0, samples)     # fundamental frequency
    volume_db = np.random.uniform(35.0, 85.0, samples)     # RMS loudness
    hydration_level = np.random.uniform(0.0, 100.0, samples)

    moods = np.random.choice(["happy", "neutral", "sad", "stressed"], size=samples, p=[0.35, 0.35, 0.15, 0.15])

    df = pd.DataFrame(
        {
            "speech_rate": speech_rate,
            "pitch_hz": pitch_hz,
            "volume_db": volume_db,
            "hydration_level": hydration_level,
            "mood": moods,
        }
    )

    cont_cols = ["speech_rate", "pitch_hz", "volume_db", "hydration_level"]
    scaler = StandardScaler()
    df[cont_cols] = scaler.fit_transform(df[cont_cols])

    out_csv.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out_csv, index=False)
    logger.info("Sentiment dataset saved -> %s", out_csv)


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    default_outdir = project_root / "training" / "data"  # models/training/data

    parser = argparse.ArgumentParser(description="Prepare Hydrion.ai training datasets")
    parser.add_argument("--samples", type=int, default=10000, help="number of synthetic rows per dataset")
    parser.add_argument("--outdir", type=str, default=str(default_outdir), help="output directory")
    parser.add_argument("--log", type=str, default=str(project_root / "logs" / "data_prep.log"), help="log file path")
    args = parser.parse_args()

    logger = setup_logger(Path(args.log))
    logger.info("Starting dataset preparation")
    start = time.time()

    outdir = Path(args.outdir)
    hydration_out = outdir / "hydration_data.csv"
    sentiment_out = outdir / "sentiment_data.csv"

    create_hydration_dataset(args.samples, hydration_out, logger)
    create_sentiment_dataset(args.samples, sentiment_out, logger)

    # Schema and stats
    df_h = pd.read_csv(hydration_out)
    df_s = pd.read_csv(sentiment_out)

    schema = {
        "hydration": {
            "features": ["weight_kg", "activity_min", "temp_c", "humidity_percent", "altitude_m"],
            "categorical": ["is_pregnant", "is_breastfeeding"],
            "target": "target_ml",
        },
        "sentiment": {
            "features": ["speech_rate", "pitch_hz", "volume_db", "hydration_level"],
            "target": "mood",
            "classes": sorted(df_s["mood"].unique().tolist()),
        },
    }
    (outdir / "feature_schema.json").write_text(json.dumps(schema, indent=2))

    stats = {
        "hydration_rows": int(df_h.shape[0]),
        "sentiment_rows": int(df_s.shape[0]),
        "gamification_rows": int(df_s.shape[0]),
        "created_at": int(time.time()),
    }
    (outdir / "stats.json").write_text(json.dumps(stats, indent=2))

    dur = time.time() - start
    logger.info("Dataset preparation complete in %.2fs", dur)


if __name__ == "__main__":
    main()
