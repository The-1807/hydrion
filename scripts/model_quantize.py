#!/usr/bin/env python3
# model_quantize.py - Quantize and validate TFLite models for Hydrion on-device inference
# Usage examples:
#   python3 scripts/model_quantize.py --task hydration \
#     --source keras --model models/training/artifacts/hydration_model.keras \
#     --features models/training/artifacts/hydration_feature_order.json \
#     --scaler models/training/artifacts/hydration_scaler.pkl \
#     --repdata models/training/data/hydration_data.csv \
#     --outdir models/tflite
#
#   python3 scripts/model_quantize.py --task sentiment \
#     --source keras --model models/training/artifacts/sentiment_model.keras \
#     --features models/training/artifacts/sentiment_feature_order.json \
#     --scaler models/training/artifacts/sentiment_scaler.pkl \
#     --repdata models/training/data/sentiment_data.csv \
#     --outdir models/tflite
#
# Notes:
# - TFLite cannot be quantized from an existing .tflite file. You must convert
#   from a Keras model or a SavedModel. This tool exports fp32, float16, and int8.
# - For int8 full-integer quantization, provide a representative dataset via --repdata.
#
# Author: Hydrion.ai Team
# Version: 2.0

import os
import sys
import json
import argparse
import logging
from pathlib import Path
from typing import Callable, Iterable, Optional, Tuple

import numpy as np
import pandas as pd
import joblib

import tensorflow as tf
from tensorflow import keras

# ---------------------------- logging --------------------------------
def setup_logger(log_path: Path) -> logging.Logger:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("model_quantize")
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


# -------------------------- io helpers -------------------------------
def load_feature_order(path: Path) -> list:
    try:
        return json.loads(Path(path).read_text())
    except Exception as e:
        raise RuntimeError(f"Failed to read feature order {path}: {e}")


def load_scaler(path: Optional[Path]):
    if path is None:
        return None
    try:
        return joblib.load(path)
    except Exception as e:
        raise RuntimeError(f"Failed to read scaler {path}: {e}")


def load_representative_matrix(
    csv_path: Optional[Path],
    feature_order: Optional[list],
    scaler,
    limit: int = 5000,
) -> Optional[np.ndarray]:
    if csv_path is None or feature_order is None:
        return None
    df = pd.read_csv(csv_path)
    missing = [c for c in feature_order if c not in df.columns]
    if missing:
        raise RuntimeError(f"Representative CSV missing columns: {missing}")
    X = df[feature_order].head(limit).to_numpy(dtype=np.float32)
    if scaler is not None:
        X = scaler.transform(X).astype(np.float32)
    return X


def representative_dataset_gen(x: np.ndarray, step: int = 1) -> Callable[[], Iterable[list]]:
    def gen():
        if x is None or len(x) == 0:
            return
        for i in range(0, min(len(x), 1000), max(1, step)):
            yield [x[i : i + 1].astype(np.float32)]
    return gen


# -------------------------- conversion -------------------------------
def build_converter_from_source(
    source: str,
    model_path: Path,
    logger: logging.Logger,
) -> tf.lite.TFLiteConverter:
    if source == "keras":
        try:
            # Prefer full Keras model if available
            model = None
            # Try loading full model first
            try:
                model = keras.models.load_model(str(model_path))
            except Exception:
                # Fallback: if path points to weights-only, raise
                raise
            logger.info("Loaded Keras model from %s", model_path)
            return tf.lite.TFLiteConverter.from_keras_model(model)
        except Exception as e:
            raise RuntimeError(f"Failed to load Keras model at {model_path}: {e}")

    if source == "savedmodel":
        if not model_path.exists():
            raise RuntimeError(f"SavedModel directory not found: {model_path}")
        logger.info("Using SavedModel at %s", model_path)
        return tf.lite.TFLiteConverter.from_saved_model(str(model_path))

    raise ValueError("source must be 'keras' or 'savedmodel'")


def export_variants(
    base_name: str,
    outdir: Path,
    base_converter: tf.lite.TFLiteConverter,
    rep_gen: Optional[Callable[[], Iterable[list]]],
    logger: logging.Logger,
) -> Tuple[Path, Path, Path]:
    outdir.mkdir(parents=True, exist_ok=True)

    # fp32
    conv = base_converter
    tflite_fp32 = conv.convert()
    fp32_path = outdir / f"{base_name}_fp32.tflite"
    fp32_path.write_bytes(tflite_fp32)
    logger.info("Wrote %s (%.2f MB)", fp32_path, fp32_path.stat().st_size / 1e6)

    # float16
    conv = build_converter_clone(base_converter)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    conv.target_spec.supported_types = [tf.float16]
    f16_bytes = conv.convert()
    f16_path = outdir / f"{base_name}_float16.tflite"
    f16_path.write_bytes(f16_bytes)
    logger.info("Wrote %s (%.2f MB)", f16_path, f16_path.stat().st_size / 1e6)

    # int8 (full integer if rep_gen provided, else dynamic range)
    conv = build_converter_clone(base_converter)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    if rep_gen is not None:
        conv.representative_dataset = rep_gen
        try:
            conv.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
            conv.inference_input_type = tf.int8
            conv.inference_output_type = tf.int8
        except Exception:
            # some models require fallback to builtin ops auto select
            pass
    int8_bytes = conv.convert()
    int8_path = outdir / f"{base_name}_int8.tflite"
    int8_path.write_bytes(int8_bytes)
    logger.info("Wrote %s (%.2f MB)", int8_path, int8_path.stat().st_size / 1e6)

    # size diff summary
    sz_fp32 = fp32_path.stat().st_size
    sz_f16 = f16_path.stat().st_size
    sz_i8 = int8_path.stat().st_size
    logger.info(
        "Size reduction vs fp32 -> float16: -%.1f%%, int8: -%.1f%%",
        (1 - sz_f16 / sz_fp32) * 100,
        (1 - sz_i8 / sz_fp32) * 100,
    )

    return fp32_path, f16_path, int8_path


def build_converter_clone(conv: tf.lite.TFLiteConverter) -> tf.lite.TFLiteConverter:
    # There is no public clone. Re-create using the same source config.
    # We detect based on attributes present.
    if getattr(conv, "_saved_model_dir", None):
        return tf.lite.TFLiteConverter.from_saved_model(conv._saved_model_dir)  # type: ignore[attr-defined]
    if getattr(conv, "_keras_model", None):
        return tf.lite.TFLiteConverter.from_keras_model(conv._keras_model)  # type: ignore[attr-defined]
    # Fallback: raise clear error
    raise RuntimeError("Cannot clone converter. Please run export in one pass or use savedmodel/keras source again.")


# -------------------------- validation -------------------------------
def quick_infer(tflite_path: Path, input_dim: int, logger: logging.Logger) -> None:
    try:
        interp = tf.lite.Interpreter(model_path=str(tflite_path))
        interp.allocate_tensors()
        input_details = interp.get_input_details()
        output_details = interp.get_output_details()

        # Best effort: create a dummy input matching first tensor
        idx = input_details[0]["index"]
        shape = input_details[0]["shape"]
        dtype = input_details[0]["dtype"]

        # If model expects int8, center at zero-point
        if dtype == np.int8:
            zp = input_details[0].get("quantization_parameters", {}).get("zero_points", [0])[0]
            scale = input_details[0].get("quantization_parameters", {}).get("scales", [1.0])[0]
            sample = (np.random.randn(*shape).astype(np.float32) * 0.1 / max(scale, 1e-8) + zp).astype(np.int8)
        else:
            sample = np.random.randn(*shape).astype(dtype)

        interp.set_tensor(idx, sample)
        interp.invoke()
        out = interp.get_tensor(output_details[0]["index"])
        logger.info("Validated %s | input %s %s -> output %s %s",
                    tflite_path.name, shape, dtype, out.shape, out.dtype)
    except Exception as e:
        raise RuntimeError(f"Validation failed for {tflite_path}: {e}")


# ------------------------------ cli ----------------------------------
def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    default_outdir = project_root.parent / "tflite"
    logs_dir = project_root.parent / "logs"

    parser = argparse.ArgumentParser(description="Hydrion TFLite quantization exporter")
    parser.add_argument("--task", required=True, choices=["hydration", "sentiment"], help="model task")
    parser.add_argument("--source", required=True, choices=["keras", "savedmodel"], help="source model type")
    parser.add_argument("--model", required=True, help="path to Keras model (.keras) or SavedModel dir")
    parser.add_argument("--features", required=False, help="feature order json for representative data")
    parser.add_argument("--scaler", required=False, help="sklearn scaler pickle for representative data")
    parser.add_argument("--repdata", required=False, help="csv file with raw features for calibration")
    parser.add_argument("--outdir", default=str(default_outdir), help="output directory for tflite files")
    parser.add_argument("--log", default=str(logs_dir / "model_quantize.log"), help="log file path")
    args = parser.parse_args()

    logger = setup_logger(Path(args.log))
    logger.info("Starting quantization for task=%s source=%s", args.task, args.source)

    model_path = Path(args.model)
    if args.source == "keras" and model_path.suffix not in {".keras", ".h5"}:
        logger.warning("Keras source usually ends with .keras or .h5, got %s", model_path.name)

    # Representative dataset (optional but recommended for int8)
    feature_order = load_feature_order(Path(args.features)) if args.features else None
    scaler = load_scaler(Path(args.scaler)) if args.scaler else None
    rep_matrix = load_representative_matrix(
        Path(args.repdata) if args.repdata else None,
        feature_order,
        scaler,
        limit=5000,
    )
    rep_gen = representative_dataset_gen(rep_matrix) if rep_matrix is not None else None
    if rep_gen is None:
        logger.warning("No representative dataset provided. int8 will use dynamic range fallback where needed.")

    # Build base converter
    converter = build_converter_from_source(args.source, model_path, logger)

    # Decide base name
    base_name = "hydration_predictor" if args.task == "hydration" else "sentiment_analyzer"

    # Export variants
    outdir = Path(args.outdir)
    fp32, f16, i8 = export_variants(base_name, outdir, converter, rep_gen, logger)

    # Quick runtime validation
    # Try to infer input dim from representative matrix or default to 5/4
    input_dim = rep_matrix.shape[1] if rep_matrix is not None else (5 if args.task == "hydration" else 4)
    for p in (fp32, f16, i8):
        quick_infer(p, input_dim, logger)

    logger.info("Quantization complete.")


if __name__ == "__main__":
    main()
