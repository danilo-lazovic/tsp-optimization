"""Run every heuristic on a city list and save a comparison.

    python -m tsp                      # uses data/cities.csv
    python -m tsp --cities my.csv --seed 1 --no-plot
"""

from __future__ import annotations

import argparse
import csv
import time
from pathlib import Path

import numpy as np

from .geo import distance_matrix, load_cities
from .heuristics import (
    genetic_algorithm,
    held_karp,
    nearest_neighbor,
    simulated_annealing,
    tour_length,
    two_opt,
)

REPO_ROOT = Path(__file__).resolve().parents[1]


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--cities", type=Path, default=REPO_ROOT / "data" / "cities.csv")
    p.add_argument("--out", type=Path, default=REPO_ROOT / "results")
    p.add_argument("--start", type=int, default=0, help="index of the start city (default: first row)")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--no-plot", action="store_true")
    args = p.parse_args(argv)

    names, coords = load_cities(args.cities)
    dist = distance_matrix(coords)
    rng = np.random.default_rng(args.seed)

    runs = {}

    def run(label, fn):
        t0 = time.perf_counter()
        tour = fn()
        runs[label] = (tour, tour_length(tour, dist), time.perf_counter() - t0)

    run("Nearest Neighbor", lambda: nearest_neighbor(dist, args.start))
    nn = runs["Nearest Neighbor"][0]
    run("NN + 2-opt", lambda: two_opt(nn, dist))
    run("Simulated Annealing", lambda: simulated_annealing(nn, dist, rng=rng))
    run("Genetic Algorithm", lambda: genetic_algorithm(dist, args.start, rng=rng))
    if len(names) <= 18:
        run("Optimum (Held-Karp)", lambda: held_karp(dist, args.start))

    best = min(length for _, length, _ in runs.values())
    print(f"{'Method':<22}{'km':>10}{'gap %':>8}{'time s':>9}")
    for label, (_, length, secs) in runs.items():
        print(f"{label:<22}{length:>10.1f}{100 * (length / best - 1):>8.2f}{secs:>9.2f}")

    args.out.mkdir(parents=True, exist_ok=True)
    with open(args.out / "results.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Method", "LengthKm", "Route"])
        for label, (tour, length, _) in runs.items():
            w.writerow([label, f"{length:.1f}", " -> ".join(names[i] for i in [*tour, tour[0]])])
    print(f"\nSaved {args.out / 'results.csv'}")

    if not args.no_plot:
        from .plot import plot_routes

        path = args.out / "routes.png"
        plot_routes(names, coords, {k: (t, l) for k, (t, l, _) in runs.items()}, path)
        print(f"Saved {path}")


if __name__ == "__main__":
    main()
