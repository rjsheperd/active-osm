STATE=${1:-montana}
TYPE=bikeparking
FILEBASE="${STATE}_${TYPE}"
export OSM_CONFIG_FILE="$(pwd)/osmconf.ini"
O5M=${FILEBASE}.o5m
PBF=${FILEBASE}.osm.pbf
GEOJSON=${FILEBASE}.geojson
NOW=$(date +"%m-%d-%y-%T")

# Download latest data
echo "-- Downloading ${STATE}-latest.osm.pbf from Geofabrik"
if [ -f "${STATE}-latest.osm.pbf" ]; then
  echo "-- Already downloaded file."
else
  curl -O https://download.geofabrik.de/north-america/us/$STATE-latest.osm.pbf
fi

# Convert to o5m for filtering
echo "-- Converting ${STATE}-latest.osm.pbf to ${STATE}.o5m for filtering"
if [ -f "${STATE}.o5m" ]; then
  echo "-- Already converted file."
else
  osmconvert ${STATE}-latest.osm.pbf --out-o5m -o=$STATE.o5m
fi

# Filter Bike Parking
echo "-- Filtering ${STATE}.o5m for bike parking"
osmfilter $STATE.o5m \
  --keep="amenity=bicycle_parking" \
  -o=$O5M

# Convert to nodes
echo "-- Converting $O5M polygons to nodes"
osmconvert $O5M \
  --all-to-nodes \
  --out-pbf -o=$PBF

# Produce GeoJSON
#echo "-- Converting $PBF to $GEOJSON"
#if [ -f $GEOJSON ]; then
  #mv $GEOJSON "${FILEBASE}_${NOW}.geojson"
#fi
#osmtogeojson -m "${STATE}_bikeparking.osm.pbf" > "${STATE}_bikeparking.geojson"
#ogr2ogr -f GeoJSON $GEOJSON $PBF points
ogrinfo "${STATE}_${TYPE}.osm.pbf" lines | head -n 100

# Insert into DB
echo "-- Inserting into DB"
ogr2ogr -f PostgreSQL  \
  -lco GEOMETRY_NAME=geom \
  PG:dbname=pythonspatial $GEOJSON
