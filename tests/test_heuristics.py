import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tsp import (  # noqa: E402
    distance_matrix,
    genetic_algorithm,
    haversine_km,
    held_karp,
    load_cities,
    nearest_neighbor,
    simulated_annealing,
    tour_length,
    two_opt,
)

DATA = Path(__file__).resolve().parents[1] / "data" / "cities.csv"


@pytest.fixture(scope="module")
def dist():
    _, coords = load_cities(DATA)
    return distance_matrix(coords)


def is_valid(tour, n, start=0):
    return tour[0] == start and sorted(tour) == list(range(n))


def test_haversine_belgrade_novi_sad():
    # Straight-line distance is about 68 km.
    assert haversine_km(20.4569, 44.8178, 19.8452, 45.2551) == pytest.approx(68, abs=2)


def test_square_tour_length():
    pts = np.array([[0, 0], [0, 1], [1, 1], [1, 0]], dtype=float)
    d = np.linalg.norm(pts[:, None] - pts[None, :], axis=-1)
    assert tour_length([0, 1, 2, 3], d) == pytest.approx(4)
    assert two_opt([0, 2, 1, 3], d) in ([0, 1, 2, 3], [0, 3, 2, 1])


def test_all_heuristics_return_valid_tours(dist):
    n = len(dist)
    rng = np.random.default_rng(0)
    nn = nearest_neighbor(dist)
    for tour in (
        nn,
        two_opt(nn, dist),
        simulated_annealing(nn, dist, iterations=5_000, rng=rng),
        genetic_algorithm(dist, pop_size=30, generations=30, rng=rng),
    ):
        assert is_valid(tour, n)


def test_improvements_never_worse_than_start(dist):
    nn = nearest_neighbor(dist)
    base = tour_length(nn, dist)
    assert tour_length(two_opt(nn, dist), dist) <= base
    sa = simulated_annealing(nn, dist, iterations=5_000, rng=np.random.default_rng(1))
    assert tour_length(sa, dist) <= base


def test_held_karp_is_optimal_on_small_instance():
    rng = np.random.default_rng(3)
    pts = rng.random((8, 2))
    d = np.linalg.norm(pts[:, None] - pts[None, :], axis=-1)
    from itertools import permutations

    brute = min(tour_length([0, *p], d) for p in permutations(range(1, 8)))
    assert tour_length(held_karp(d), d) == pytest.approx(brute)
