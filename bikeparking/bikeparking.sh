STATE=${1:-montna}

# Download latest data
echo "Downloading ${STATE}-latest.osm.pbf from Geofabrik"
curl -O https://download.geofabrik.de/north-america/us/$STATE-latest.osm.pbf

# Convert to o5m for filtering
echo "Converting ${STATE}-latest.osm.pbf to ${STATE}.o5m for filtering"
osmconvert ${STATE}-latest.osm.pbf --out-o5m -o=$STATE.o5m

# Filter Bike Parking
echo "Filtering ${STATE}.o5m for bike parking"
osmfilter $STATE.o5m \
  --keep="amenity=bicycle_parking" \
  -o="${STATE}_bikeparking.o5m"

# Convert to nodes
echo "Converting ${STATE}_bikeparking.o5m polygons to nodes"
osmconvert "${STATE}_bikeparking.o5m" \
  --all-to-nodes \
  --out-pbf -o="${STATE}_bikeparking.osm.pbf"

# Produce GeoJSON
echo "Producing ${STATE}_bikeparking.geojson"
osmtogeojson -m "${STATE}_bikeparking.osm.pbf" > "${STATE}_bikeparking.geojson"
#ogr2ogr -f GeoJSON "${STATE}_bikeparking.geojson" \
  #-select bicycle_parking,capacity,covered,fee, \
  #"${STATE}_bikeparking.osm.pbf" points

# Insert into DB
echo "Inserting into DB"
ogr2ogr --create -f PostgreSQL PG:dbname=pythonspatial "${STATE}_bikeparking.geojson"

