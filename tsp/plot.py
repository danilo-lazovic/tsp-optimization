"""Route plots."""

from __future__ import annotations

import math

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402


def plot_routes(names, coords, routes: dict, path) -> None:
    """One panel per method. ``routes`` maps label -> (tour, length_km)."""
    k = len(routes)
    cols = min(k, 3)
    rows = math.ceil(k / cols)
    fig, axes = plt.subplots(rows, cols, figsize=(5.5 * cols, 4.8 * rows), squeeze=False)
    for ax, (label, (tour, length)) in zip(axes.flat, routes.items()):
        closed = [*tour, tour[0]]
        ax.plot(coords[closed, 0], coords[closed, 1], "-o", lw=1.8, ms=4)
        ax.plot(*coords[tour[0]], "s", ms=9, color="crimson", label="start")
        for i, name in enumerate(names):
            ax.annotate(name, coords[i], fontsize=7, xytext=(3, 3), textcoords="offset points")
        ax.set_title(f"{label}: {length:,.0f} km")
        ax.set_xlabel("longitude")
        ax.set_ylabel("latitude")
        ax.grid(alpha=0.3)
    for ax in list(axes.flat)[k:]:
        ax.axis("off")
    fig.tight_layout()
    fig.savefig(path, dpi=130)
    plt.close(fig)
