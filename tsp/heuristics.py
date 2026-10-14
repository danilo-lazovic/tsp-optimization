"""TSP heuristics.

A tour is a list of city indices that visits every city exactly once and
starts at the start city. The return leg to the start is implied.
"""

from __future__ import annotations

import math

import numpy as np


def tour_length(tour, dist: np.ndarray) -> float:
    """Length of the closed tour, including the return to the first city."""
    t = np.asarray(tour)
    return float(dist[t, np.roll(t, -1)].sum())


def nearest_neighbor(dist: np.ndarray, start: int = 0) -> list[int]:
    """Greedy construction: always go to the closest unvisited city."""
    n = len(dist)
    visited = np.zeros(n, dtype=bool)
    visited[start] = True
    tour = [start]
    for _ in range(n - 1):
        d = np.where(visited, np.inf, dist[tour[-1]])
        nxt = int(np.argmin(d))
        visited[nxt] = True
        tour.append(nxt)
    return tour


def two_opt(tour, dist: np.ndarray) -> list[int]:
    """Reverse segments while that shortens the tour. The start city stays first."""
    tour = list(tour)
    n = len(tour)
    improved = True
    while improved:
        improved = False
        for i in range(1, n - 1):
            for j in range(i + 1, n):
                a, b = tour[i - 1], tour[i]
                c, d = tour[j], tour[(j + 1) % n]
                delta = dist[a, c] + dist[b, d] - dist[a, b] - dist[c, d]
                if delta < -1e-9:
                    tour[i : j + 1] = reversed(tour[i : j + 1])
                    improved = True
    return tour


def simulated_annealing(
    tour,
    dist: np.ndarray,
    iterations: int = 50_000,
    t_start: float | None = None,
    t_end: float = 1e-3,
    rng: np.random.Generator | None = None,
) -> list[int]:
    """Simulated annealing with 2-opt (segment reversal) moves.

    The temperature falls geometrically from ``t_start`` to ``t_end`` over all
    iterations. By default ``t_start`` is 10% of the starting tour length, so
    the schedule fits the scale of the distances.
    """
    rng = rng or np.random.default_rng()
    current = list(tour)
    n = len(current)
    cur_len = tour_length(current, dist)
    best, best_len = current[:], cur_len
    t = t_start if t_start is not None else 0.1 * cur_len
    alpha = (t_end / t) ** (1 / iterations)

    for _ in range(iterations):
        i, j = sorted(rng.choice(np.arange(1, n), size=2, replace=False))
        a, b = current[i - 1], current[i]
        c, d = current[j], current[(j + 1) % n]
        delta = dist[a, c] + dist[b, d] - dist[a, b] - dist[c, d]
        if delta < 0 or rng.random() < math.exp(-delta / t):
            current[i : j + 1] = reversed(current[i : j + 1])
            cur_len += delta
            if cur_len < best_len - 1e-9:
                best, best_len = current[:], cur_len
        t *= alpha
    return best


def _order_crossover(pa: np.ndarray, pb: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    m = len(pa)
    c1, c2 = sorted(rng.integers(0, m, size=2))
    child = np.full(m, -1)
    child[c1 : c2 + 1] = pa[c1 : c2 + 1]
    taken = set(child[c1 : c2 + 1].tolist())
    fill = [g for g in np.roll(pb, -(c2 + 1)) if g not in taken]
    positions = [(c2 + 1 + k) % m for k in range(m - (c2 - c1 + 1))]
    child[positions] = fill
    return child


def genetic_algorithm(
    dist: np.ndarray,
    start: int = 0,
    pop_size: int = 100,
    generations: int = 300,
    mutation_rate: float = 0.2,
    rng: np.random.Generator | None = None,
) -> list[int]:
    """Genetic algorithm: tournament selection (size 2), order crossover (OX),
    swap mutation and elitism. Individuals are orders of the non-start cities."""
    rng = rng or np.random.default_rng()
    others = np.array([c for c in range(len(dist)) if c != start])

    def fitness(ind):
        return tour_length([start, *ind], dist)

    pop = [rng.permutation(others) for _ in range(pop_size)]
    fit = np.array([fitness(p) for p in pop])

    for _ in range(generations):
        new_pop = [pop[int(np.argmin(fit))]]
        while len(new_pop) < pop_size:
            i1, i2 = rng.integers(0, pop_size, size=2)
            j1, j2 = rng.integers(0, pop_size, size=2)
            pa = pop[i1] if fit[i1] < fit[i2] else pop[i2]
            pb = pop[j1] if fit[j1] < fit[j2] else pop[j2]
            child = _order_crossover(pa, pb, rng)
            if rng.random() < mutation_rate:
                a, b = rng.choice(len(child), size=2, replace=False)
                child[a], child[b] = child[b], child[a]
            new_pop.append(child)
        pop = new_pop
        fit = np.array([fitness(p) for p in pop])

    best = pop[int(np.argmin(fit))]
    return [start, *best.tolist()]


def held_karp(dist: np.ndarray, start: int = 0) -> list[int]:
    """Exact optimum by dynamic programming, O(2^n * n^2). Practical up to ~18 cities."""
    n = len(dist)
    if n > 20:
        raise ValueError("held_karp is only practical for up to ~20 cities")
    others = [c for c in range(n) if c != start]
    m = len(others)
    d = dist[np.ix_(others, others)]
    full = 1 << m
    dp = np.full((full, m), np.inf)
    parent = np.full((full, m), -1, dtype=np.int64)
    for j in range(m):
        dp[1 << j, j] = dist[start, others[j]]
    bits = 1 << np.arange(m)
    for mask in range(1, full):
        in_mask = (mask & bits) != 0
        if in_mask.sum() < 2:
            continue
        for j in np.flatnonzero(in_mask):
            prev = mask ^ (1 << j)
            cand = dp[prev] + d[:, j]
            k = int(np.argmin(cand))
            dp[mask, j] = cand[k]
            parent[mask, j] = k
    last = int(np.argmin(dp[full - 1] + dist[others, start]))
    order, mask = [], full - 1
    while last != -1:
        order.append(others[last])
        mask, last = mask ^ (1 << last), int(parent[mask, last])
    return [start, *reversed(order)]
