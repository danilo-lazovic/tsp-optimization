"""Loading city coordinates and computing great-circle distances."""

from __future__ import annotations

import csv
from pathlib import Path

import numpy as np

EARTH_RADIUS_KM = 6371.0


def load_cities(path: str | Path) -> tuple[list[str], np.ndarray]:
    """Read a ``City,Lon,Lat`` CSV. Returns names and an (n, 2) array of [lon, lat]."""
    names, coords = [], []
    with open(path, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            names.append(row["City"])
            coords.append((float(row["Lon"]), float(row["Lat"])))
    return names, np.array(coords)


def haversine_km(lon1, lat1, lon2, lat2):
    """Great-circle distance in km. Works on scalars and numpy arrays."""
    lon1, lat1, lon2, lat2 = map(np.radians, (lon1, lat1, lon2, lat2))
    a = (
        np.sin((lat2 - lat1) / 2) ** 2
        + np.cos(lat1) * np.cos(lat2) * np.sin((lon2 - lon1) / 2) ** 2
    )
    return 2 * EARTH_RADIUS_KM * np.arcsin(np.sqrt(a))


def distance_matrix(coords: np.ndarray) -> np.ndarray:
    """Symmetric (n, n) matrix of great-circle distances in km."""
    lon, lat = coords[:, 0], coords[:, 1]
    return haversine_km(lon[:, None], lat[:, None], lon[None, :], lat[None, :])
