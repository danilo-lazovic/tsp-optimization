"""Look up coordinates for the cities in data/cities.txt and write data/cities.csv.

    python scripts/geocode.py

Uses OpenStreetMap Nominatim (free, max 1 request per second). The repo already
ships data/cities.csv, so you only need this when you change the city list.
"""

from __future__ import annotations

import csv
import time
from pathlib import Path

from geopy.geocoders import Nominatim

DATA = Path(__file__).resolve().parents[1] / "data"


def main() -> None:
    queries = [
        line.strip()
        for line in (DATA / "cities.txt").read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    geolocator = Nominatim(user_agent="tsp-optimization (github.com/danilo-lazovic)")

    rows = []
    for query in queries:
        try:
            location = geolocator.geocode(query)
        except Exception as e:  # network errors, rate limits
            print(f"Greška za {query}: {e}")
            location = None
        if location:
            name = query.split(",")[0].strip()
            rows.append((name, round(location.longitude, 4), round(location.latitude, 4)))
            print(f"{query}: {location.latitude:.4f}, {location.longitude:.4f}")
        else:
            print(f"Koordinate za {query} nisu pronađene.")
        time.sleep(1)  # Nominatim usage policy: max 1 request per second

    with open(DATA / "cities.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["City", "Lon", "Lat"])
        w.writerows(rows)
    print(f"\nUspešno kreirano: {DATA / 'cities.csv'} sa {len(rows)} gradova")


if __name__ == "__main__":
    main()
