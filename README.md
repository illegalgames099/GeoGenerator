# GeoGenerator

GeoGenerator is a Roblox Studio plugin for generating real-world terrain and map features from OpenStreetMap and elevation data. It builds on the WorldLoader idea with GeoGenerator branding, improved coordinate compatibility, configurable generation settings, and optional procedural/extra building support.

## New generation upgrades

- Roads can generate raised sidewalks, curbs, and dashed lane markings from OSM highway/sidewalk/lane tags.
- Area and road surfaces can receive an optional top satellite texture by setting `Generation Rules["Satellite Texture Id"]` to a Roblox texture asset id.
- Street data downloads are split into smaller Overpass chunks with response caching to reduce rate-limit pain during iteration.
- Elevation responses are cached per request URL so repeated generation of the same area can reuse previous height data.
