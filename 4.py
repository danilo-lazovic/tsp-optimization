import time
import pandas as pd
from geopy.geocoders import Nominatim

with open("cities.txt", "r", encoding="utf-8") as f:
    city_names = [line.strip() for line in f if line.strip()]

# geokoder
geolocator = Nominatim(user_agent="city_extractor")
cities, latitudes, longitudes = [], [], []

for city in city_names:
    try:
        location = geolocator.geocode(city)
        if location:
            cities.append(city)
            latitudes.append(location.latitude)
            longitudes.append(location.longitude)
            print(f"{city}: {location.latitude}, {location.longitude}")
        else:
            print(f"Koordinate za {city} nisu pronađene.")
    except Exception as e:
        print(f"Greška za {city}: {e}")
    time.sleep(1)  # pauza da ne blokira API

df = pd.DataFrame({
    "City": cities,
    "X": longitudes,   # longitude
    "Y": latitudes     # latitude
})

df.to_excel("cities.xlsx", index=False)
print(f"\nUspešno kreirano: cities.xlsx sa {len(df)} gradova")
