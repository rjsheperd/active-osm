STATE=${1:-montana}
TYPE=cycleway
BIKE="(highway= and bicycle=yes =designated) or \
  (cycleway=lane =shared_lane =opposite =track =opposite_lane =crossing =shoulder) or \
  (highway=cycleway =path =footway)"\
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

# Filter
echo "-- Filtering ${STATE}.o5m for $TYPE"
osmfilter $STATE.o5m \
  --keep-ways="$BIKE" \
  -o="${STATE}_${TYPE}.o5m"

# Convert back to PBF
echo "-- Converting back to .pbf"
osmconvert "${STATE}_${TYPE}.o5m" \
  --out-pbf -o="${STATE}_${TYPE}.osm.pbf"

# Produce GeoJSON
#echo "-- Producing ${STATE}_${TYPE}.geojson"
#osmtogeojson -m "${STATE}_${TYPE}.osm.pbf" > "${STATE}_${TYPE}.geojson"
ogrinfo "${STATE}_${TYPE}.osm.pbf" lines | head -n 100
#ogr2ogr -f GeoJSON "${STATE}_${TYPE}.geojson" \
  #-select bicycle_parking,capacity,covered,fee, \
  #"${STATE}_${TYPE}.osm.pbf" points

# Insert into DB
echo "-- Inserting into DB"
#ogr2ogr --create -f PostgreSQL PG:dbname=pythonspatial "${STATE}_${TYPE}.geojson"
