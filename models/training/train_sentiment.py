#!/usr/bin/env python3
# train_sentiment.py - Train sentiment analyzer model for Hydrion.ai
# Usage:
#   python3 models/training/train_sentiment.py \
#     --data models/training/data/sentiment_data.csv \
#     --outdir models/tflite
#
# Outputs:
#   models/tflite/sentiment_analyzer_fp32.tflite
#   models/tflite/sentiment_analyzer_float16.tflite
#   models/tflite/sentiment_analyzer_int8.tflite
#   models/training/artifacts/sentiment_scaler.pkl
#   models/training/artifacts/sentiment_label_encoder.pkl
#   models/training/artifacts/sentiment_feature_order.json
#   models/training/artifacts/sentiment_metrics.json
#
# Author: Hydrion.ai Team
# Version: 1.2

import os
import sys
import json
import time
import argparse
import logging
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import accuracy_score, f1_score, confusion_matrix
import joblib

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, callbacks


def setup_logger(log_path: Path) -> logging.Logger:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("train_sentiment")
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


def seed_everything(seed: int = 123) -> None:
    import random
    os.environ["PYTHONHASHSEED"] = str(seed)
    np.random.seed(seed)
    random.seed(seed)
    tf.random.set_seed(seed)


def build_model(input_dim: int, num_classes: int) -> keras.Model:
    model = keras.Sequential(
        [
            layers.Input(shape=(input_dim,)),
            layers.Dense(128, activation="relu"),
            layers.Dropout(0.2),
            layers.Dense(64, activation="relu"),
            layers.Dense(num_classes, activation="softmax", name="mood"),
        ]
    )
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def representative_dataset_gen(x_train: np.ndarray, batch_size: int = 100):
    def gen():
        for i in range(0, min(len(x_train), 1000), max(1, len(x_train) // batch_size)):
            yield [x_train[i : i + 1].astype(np.float32)]
    return gen


def export_tflite_variants(model: keras.Model, out_dir: Path, rep_gen, base_name: str):
    out_dir.mkdir(parents=True, exist_ok=True)

    # fp32
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_fp32 = conv.convert()
    (out_dir / f"{base_name}_fp32.tflite").write_bytes(tflite_fp32)

    # float16
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    conv.target_spec.supported_types = [tf.float16]
    tflite_f16 = conv.convert()
    (out_dir / f"{base_name}_float16.tflite").write_bytes(tflite_f16)

    # int8
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    conv.representative_dataset = rep_gen
    conv.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    conv.inference_input_type = tf.int8
    conv.inference_output_type = tf.int8
    tflite_int8 = conv.convert()
    (out_dir / f"{base_name}_int8.tflite").write_bytes(tflite_int8)


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    default_data = project_root / "training" / "data" / "sentiment_data.csv"
    default_tflite = project_root.parent / "tflite"
    artifacts_dir = project_root / "training" / "artifacts"

    parser = argparse.ArgumentParser(description="Train Hydrion sentiment analyzer")
    parser.add_argument("--data", type=str, default=str(default_data), help="sentiment csv path")
    parser.add_argument("--outdir", type=str, default=str(default_tflite), help="tflite output directory")
    parser.add_argument("--epochs", type=int, default=60, help="training epochs")
    parser.add_argument("--batch", type=int, default=64, help="batch size")
    parser.add_argument("--test_size", type=float, default=0.2, help="test split fraction")
    parser.add_argument("--log", type=str, default=str(project_root.parent / "logs" / "train_sentiment.log"), help="log file path")
    args = parser.parse_args()

    logger = setup_logger(Path(args.log))
    seed_everything(123)

    logger.info("Loading dataset: %s", args.data)
    df = pd.read_csv(args.data)

    feature_cols = ["speech_rate", "pitch_hz", "volume_db", "hydration_level"]
    target_col = "mood"

    X = df[feature_cols].values.astype(np.float32)
    y_raw = df[target_col].values

    # Label encode target and scale features; persist artifacts
    le = LabelEncoder()
    y = le.fit_transform(y_raw).astype(np.int32)

    scaler = StandardScaler()
    X = scaler.fit_transform(X).astype(np.float32)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_size, random_state=123, shuffle=True, stratify=y
    )

    logger.info("Classes: %s", list(le.classes_))
    num_classes = len(le.classes_)

    logger.info("Building model")
    model = build_model(input_dim=X.shape[1], num_classes=num_classes)

    ckpt_path = artifacts_dir / "sentiment_ckpt.keras"
    callbacks_list = [
        callbacks.EarlyStopping(monitor="val_accuracy", patience=6, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=3, min_lr=1e-5),
        callbacks.ModelCheckpoint(filepath=str(ckpt_path), monitor="val_accuracy", save_best_only=True),
    ]

    logger.info("Training for %d epochs, batch %d", args.epochs, args.batch)
    hist = model.fit(
        X_train,
        y_train,
        validation_data=(X_test, y_test),
        epochs=args.epochs,
        batch_size=args.batch,
        verbose=1,
        callbacks=callbacks_list,
    )

    # Eval
    logger.info("Evaluating")
    probs = model.predict(X_test, verbose=0)
    preds = probs.argmax(axis=1)

    acc = float(accuracy_score(y_test, preds))
    f1m = float(f1_score(y_test, preds, average="macro"))
    cm = confusion_matrix(y_test, preds).tolist()

    artifacts_dir.mkdir(parents=True, exist_ok=True)
    (artifacts_dir / "sentiment_metrics.json").write_text(json.dumps({"accuracy": acc, "f1_macro": f1m, "confusion_matrix": cm}, indent=2))
    (artifacts_dir / "sentiment_feature_order.json").write_text(json.dumps(feature_cols, indent=2))
    (artifacts_dir / "sentiment_class_mapping.json").write_text(json.dumps({int(i): cls for i, cls in enumerate(le.classes_)}, indent=2))
    joblib.dump(scaler, artifacts_dir / "sentiment_scaler.pkl")
    joblib.dump(le, artifacts_dir / "sentiment_label_encoder.pkl")

    logger.info("Metrics -> ACC: %.3f | F1_macro: %.3f", acc, f1m)

    # TFLite exports
    out_dir = Path(args.outdir)
    rep_gen = representative_dataset_gen(X_train)
    export_tflite_variants(model, out_dir, rep_gen, base_name="sentiment_analyzer")
    logger.info("TFLite models exported -> %s", out_dir)

    # Save final Keras weights buffer gate (noop if not supported)
    (artifacts_dir / "sentiment_model.keras").write_bytes(model.save_weights_to_buffer() if hasattr(model, "save_weights_to_buffer") else b"")


if __name__ == "__main__":
    main()
