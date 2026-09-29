import React, { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import { api } from '../api';
import { Layers, MapPin, Trash2, CheckCircle2, XCircle, Plus, Eye } from 'lucide-react';

interface MappingEditorProps {
  hole: any;
  courseTees: any[];
  onHoleUpdated: () => void;
}

const POLYGON_STYLES: Record<string, { color: string; fillColor: string; fillOpacity: number }> = {
  FAIRWAY: { color: '#10b981', fillColor: '#10b981', fillOpacity: 0.4 },
  GREEN: { color: '#059669', fillColor: '#059669', fillOpacity: 0.6 },
  ROUGH: { color: '#84cc16', fillColor: '#84cc16', fillOpacity: 0.3 },
  BUNKER: { color: '#f59e0b', fillColor: '#fbbf24', fillOpacity: 0.6 },
  WATER_HAZARD: { color: '#06b6d4', fillColor: '#38bdf8', fillOpacity: 0.5 },
  TEE: { color: '#8b5cf6', fillColor: '#a78bfa', fillOpacity: 0.5 },
};

export const MappingEditor: React.FC<MappingEditorProps> = ({
  hole,
  courseTees,
  onHoleUpdated,
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const layersGroupRef = useRef<L.FeatureGroup | null>(null);
  const drawingLayerRef = useRef<L.Polyline | null>(null);

  const [activeMode, setActiveMode] = useState<string>('VIEW');
  const [selectedPolyType, setSelectedPolyType] = useState<string>('FAIRWAY');
  const [selectedTeeId, setSelectedTeeId] = useState<string>(courseTees[0]?.id || '');
  const [drawingPoints, setDrawingPoints] = useState<[number, number][]>([]);
  const [mapFeatures, setMapFeatures] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [statusMsg, setStatusMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const activeModeRef = useRef(activeMode);
  activeModeRef.current = activeMode;
  const drawingPointsRef = useRef(drawingPoints);
  drawingPointsRef.current = drawingPoints;
  const selectedPolyTypeRef = useRef(selectedPolyType);
  selectedPolyTypeRef.current = selectedPolyType;
  const selectedTeeIdRef = useRef(selectedTeeId);
  selectedTeeIdRef.current = selectedTeeId;

  // Load GeoJSON Map Features for current hole
  const loadMapData = useCallback(async () => {
    if (!hole?.id) return;
    setLoading(true);
    try {
      const geoJson = await api.getHoleMap(hole.id);
      setMapFeatures(geoJson.features || []);
      renderFeaturesOnMap(geoJson.features || []);
    } catch (err: any) {
      console.error('Failed to load hole map:', err);
    } finally {
      setLoading(false);
    }
  }, [hole?.id]);

  // Initialize Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: [21.0285, 105.8542],
        zoom: 17,
        zoomControl: true,
      });

      // 1. High-Res Satellite Layer (ESRI World Imagery)
      const satelliteLayer = L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        {
          attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
          maxZoom: 20,
        }
      ).addTo(map);

      // 2. OpenStreetMap Layer
      const streetLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      });

      L.control.layers(
        { 'Satellite (ESRI)': satelliteLayer, 'Streets (OSM)': streetLayer },
        undefined,
        { position: 'topright' }
      ).addTo(map);

      const layersGroup = L.featureGroup().addTo(map);
      layersGroupRef.current = layersGroup;

      // Handle map clicks
      map.on('click', (e: L.LeafletMouseEvent) => {
        handleMapClick(e.latlng.lat, e.latlng.lng);
      });

      mapRef.current = map;
    }

    loadMapData();
  }, [hole?.id, loadMapData]);

  // Render Features on Leaflet
  const renderFeaturesOnMap = (features: any[]) => {
    if (!layersGroupRef.current || !mapRef.current) return;
    layersGroupRef.current.clearLayers();

    const bounds: L.LatLngBounds = L.latLngBounds([]);

    features.forEach((feature) => {
      const geom = feature.geometry;
      const props = feature.properties || {};

      if (!geom) return;

      if (geom.type === 'Point') {
        const [lng, lat] = geom.coordinates;
        bounds.extend([lat, lng]);

        let markerColor = '#ef4444';
        let label = props.name || props.element;

        if (props.target === 'CENTER') markerColor = '#10b981';
        if (props.target === 'FRONT') markerColor = '#3b82f6';
        if (props.target === 'BACK') markerColor = '#f59e0b';
        if (props.element === 'TEE_MARKER') markerColor = props.tee_color || '#8b5cf6';

        const icon = L.divIcon({
          className: 'custom-map-marker',
          html: `<div style="background-color: ${markerColor}; width: 14px; height: 14px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 6px rgba(0,0,0,0.6);"></div>`,
          iconSize: [14, 14],
          iconAnchor: [7, 7],
        });

        const marker = L.marker([lat, lng], { icon });
        marker.bindPopup(`<b>${label}</b><br/>Lng: ${lng.toFixed(6)}, Lat: ${lat.toFixed(6)}`);
        layersGroupRef.current?.addLayer(marker);
      } else if (geom.type === 'Polygon') {
        const latLngs = geom.coordinates.map((ring: number[][]) =>
          ring.map(([lng, lat]: [number, number]) => [lat, lng])
        );

        latLngs.forEach((ring: [number, number][]) => {
          ring.forEach(([lat, lng]) => bounds.extend([lat, lng]));
        });

        const style = POLYGON_STYLES[props.type] || {
          color: '#ffffff',
          fillColor: '#ffffff',
          fillOpacity: 0.3,
        };

        const polygon = L.polygon(latLngs, {
          color: style.color,
          fillColor: style.fillColor,
          fillOpacity: style.fillOpacity,
          weight: 2,
        });

        polygon.bindPopup(
          `<b>${props.type}</b><br/>ID: ${feature.id || 'N/A'}`
        );
        layersGroupRef.current?.addLayer(polygon);
      }
    });

    if (bounds.isValid() && mapRef.current) {
      mapRef.current.fitBounds(bounds, { padding: [40, 40], maxZoom: 18 });
    }
  };

  // Handle Map Clicks according to activeMode
  const handleMapClick = async (lat: number, lng: number) => {
    const mode = activeModeRef.current;

    if (mode === 'DRAW_POLYGON') {
      const newPoints: [number, number][] = [...drawingPointsRef.current, [lng, lat]];
      setDrawingPoints(newPoints);

      if (mapRef.current) {
        if (drawingLayerRef.current) {
          mapRef.current.removeLayer(drawingLayerRef.current);
        }
        const latLngs: [number, number][] = newPoints.map(([pLng, pLat]) => [pLat, pLng]);
        const style = POLYGON_STYLES[selectedPolyTypeRef.current] || { color: '#38bdf8' };
        drawingLayerRef.current = L.polyline(latLngs, {
          color: style.color,
          weight: 3,
          dashArray: '4, 6',
        }).addTo(mapRef.current);
      }
    } else if (mode === 'SET_GREEN_CENTER') {
      try {
        await api.updateHole(hole.id, { green_center: [lng, lat] });
        setStatusMsg({ text: 'Green Center updated!', type: 'success' });
        loadMapData();
        onHoleUpdated();
        setActiveMode('VIEW');
      } catch (e: any) {
        setStatusMsg({ text: e.message, type: 'error' });
      }
    } else if (mode === 'SET_GREEN_FRONT') {
      try {
        await api.updateHole(hole.id, { green_front: [lng, lat] });
        setStatusMsg({ text: 'Green Front updated!', type: 'success' });
        loadMapData();
        onHoleUpdated();
        setActiveMode('VIEW');
      } catch (e: any) {
        setStatusMsg({ text: e.message, type: 'error' });
      }
    } else if (mode === 'SET_GREEN_BACK') {
      try {
        await api.updateHole(hole.id, { green_back: [lng, lat] });
        setStatusMsg({ text: 'Green Back updated!', type: 'success' });
        loadMapData();
        onHoleUpdated();
        setActiveMode('VIEW');
      } catch (e: any) {
        setStatusMsg({ text: e.message, type: 'error' });
      }
    } else if (mode === 'SET_TEE_MARKER') {
      if (!selectedTeeIdRef.current) {
        setStatusMsg({ text: 'Please select a tee category first', type: 'error' });
        return;
      }
      try {
        await api.setHoleTee(hole.id, {
          course_tee_id: selectedTeeIdRef.current,
          tee_position: [lng, lat],
        });
        setStatusMsg({ text: 'Tee marker placed successfully!', type: 'success' });
        loadMapData();
        onHoleUpdated();
        setActiveMode('VIEW');
      } catch (e: any) {
        setStatusMsg({ text: e.message, type: 'error' });
      }
    }
  };

  const finishAndSavePolygon = async () => {
    if (drawingPoints.length < 3) {
      setStatusMsg({ text: 'Polygon requires at least 3 vertices', type: 'error' });
      return;
    }

    // Close ring: first point == last point
    const closedRing = [...drawingPoints, drawingPoints[0]];
    const coordinates = [closedRing];

    try {
      await api.createPolygon(hole.id, {
        polygon_type: selectedPolyType,
        coordinates,
      });

      setStatusMsg({ text: `${selectedPolyType} polygon created!`, type: 'success' });
      resetDrawing();
      loadMapData();
      onHoleUpdated();
    } catch (e: any) {
      setStatusMsg({ text: e.message, type: 'error' });
    }
  };

  const resetDrawing = () => {
    setDrawingPoints([]);
    if (drawingLayerRef.current && mapRef.current) {
      mapRef.current.removeLayer(drawingLayerRef.current);
      drawingLayerRef.current = null;
    }
    setActiveMode('VIEW');
  };

  const handleDeletePolygon = async (id: string) => {
    if (!window.confirm('Delete this vector polygon?')) return;
    try {
      await api.deletePolygon(id);
      setStatusMsg({ text: 'Polygon deleted', type: 'success' });
      loadMapData();
      onHoleUpdated();
    } catch (e: any) {
      setStatusMsg({ text: e.message, type: 'error' });
    }
  };

  return (
    <div style={{ display: 'flex', height: '100%', position: 'relative' }}>
      {/* Mapping Canvas */}
      <div ref={mapContainerRef} style={{ flex: 1, height: '100%', backgroundColor: '#020617' }} />

      {/* Control Sidebar / Overlay */}
      <div
        style={{
          width: '340px',
          backgroundColor: '#1e293b',
          borderLeft: '1px solid #334155',
          display: 'flex',
          flexDirection: 'column',
          zIndex: 1000,
          overflowY: 'auto',
          padding: '16px',
        }}
      >
        <div style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <h2 style={{ fontSize: '18px', fontWeight: 'bold' }}>Hole #{hole.hole_number}</h2>
            <p style={{ fontSize: '13px', color: '#94a3b8' }}>Par {hole.par} &bull; Stroke Index {hole.handicap_index}</p>
          </div>
          {loading && <span style={{ fontSize: '12px', color: '#38bdf8' }}>Refreshing...</span>}
        </div>

        {statusMsg && (
          <div
            style={{
              padding: '10px',
              borderRadius: '6px',
              marginBottom: '14px',
              fontSize: '13px',
              backgroundColor: statusMsg.type === 'success' ? '#064e3b' : '#7f1d1d',
              color: statusMsg.type === 'success' ? '#6ee7b7' : '#fca5a5',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
            }}
          >
            {statusMsg.type === 'success' ? <CheckCircle2 size={16} /> : <XCircle size={16} />}
            {statusMsg.text}
          </div>
        )}

        {/* Action Mode Selector */}
        <div style={{ marginBottom: '18px' }}>
          <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1', display: 'block', marginBottom: '8px' }}>
            TOOL MODE
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
            <button
              onClick={() => { resetDrawing(); setActiveMode('VIEW'); }}
              style={{
                padding: '8px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: activeMode === 'VIEW' ? '#3b82f6' : '#334155',
                color: '#ffffff',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '6px',
                fontSize: '12px',
              }}
            >
              <Eye size={14} /> View Map
            </button>
            <button
              onClick={() => { resetDrawing(); setActiveMode('DRAW_POLYGON'); }}
              style={{
                padding: '8px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: activeMode === 'DRAW_POLYGON' ? '#10b981' : '#334155',
                color: '#ffffff',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '6px',
                fontSize: '12px',
              }}
            >
              <Plus size={14} /> Draw Polygon
            </button>
          </div>
        </div>

        {/* Draw Polygon Panel */}
        {activeMode === 'DRAW_POLYGON' && (
          <div style={{ backgroundColor: '#0f172a', padding: '12px', borderRadius: '8px', marginBottom: '18px' }}>
            <label style={{ fontSize: '12px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>
              Select Polygon Type:
            </label>
            <select
              value={selectedPolyType}
              onChange={(e) => setSelectedPolyType(e.target.value)}
              style={{
                width: '100%',
                padding: '8px',
                borderRadius: '6px',
                backgroundColor: '#1e293b',
                color: '#f8fafc',
                border: '1px solid #475569',
                marginBottom: '10px',
              }}
            >
              <option value="FAIRWAY">Fairway (Đường lăn bóng)</option>
              <option value="GREEN">Green (Vùng gạt bóng)</option>
              <option value="ROUGH">Rough (Vùng cỏ cao)</option>
              <option value="BUNKER">Bunker (Bẫy cát)</option>
              <option value="WATER_HAZARD">Water Hazard (Bẫy nước)</option>
              <option value="TEE">Tee Area (Khu phát bóng)</option>
            </select>

            <div style={{ fontSize: '12px', color: '#cbd5e1', marginBottom: '10px' }}>
              Vertices: <b>{drawingPoints.length}</b> points clicked.
              <br />
              <span style={{ color: '#94a3b8' }}>Click map to add points.</span>
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                onClick={finishAndSavePolygon}
                disabled={drawingPoints.length < 3}
                style={{
                  flex: 1,
                  padding: '8px',
                  backgroundColor: drawingPoints.length >= 3 ? '#10b981' : '#475569',
                  color: 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: drawingPoints.length >= 3 ? 'pointer' : 'not-allowed',
                  fontSize: '12px',
                  fontWeight: 'bold',
                }}
              >
                Finish & Save
              </button>
              <button
                onClick={resetDrawing}
                style={{
                  padding: '8px',
                  backgroundColor: '#ef4444',
                  color: 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  fontSize: '12px',
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Spatial Target Markers */}
        <div style={{ marginBottom: '18px' }}>
          <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1', display: 'block', marginBottom: '8px' }}>
            SET GREEN TARGET POINTS (F / M / B)
          </label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <button
              onClick={() => setActiveMode('SET_GREEN_CENTER')}
              style={{
                padding: '8px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: activeMode === 'SET_GREEN_CENTER' ? '#10b981' : '#334155',
                color: '#ffffff',
                cursor: 'pointer',
                fontSize: '12px',
                textAlign: 'left',
              }}
            >
              📍 Set Green Center (Click on map)
            </button>
            <button
              onClick={() => setActiveMode('SET_GREEN_FRONT')}
              style={{
                padding: '8px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: activeMode === 'SET_GREEN_FRONT' ? '#3b82f6' : '#334155',
                color: '#ffffff',
                cursor: 'pointer',
                fontSize: '12px',
                textAlign: 'left',
              }}
            >
              📍 Set Green Front (Click on map)
            </button>
            <button
              onClick={() => setActiveMode('SET_GREEN_BACK')}
              style={{
                padding: '8px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: activeMode === 'SET_GREEN_BACK' ? '#f59e0b' : '#334155',
                color: '#ffffff',
                cursor: 'pointer',
                fontSize: '12px',
                textAlign: 'left',
              }}
            >
              📍 Set Green Back (Click on map)
            </button>
          </div>
        </div>

        {/* Tee Markers Placement */}
        <div style={{ marginBottom: '18px' }}>
          <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1', display: 'block', marginBottom: '8px' }}>
            SET TEE MARKER POSITION
          </label>
          <select
            value={selectedTeeId}
            onChange={(e) => setSelectedTeeId(e.target.value)}
            style={{
              width: '100%',
              padding: '8px',
              borderRadius: '6px',
              backgroundColor: '#0f172a',
              color: '#f8fafc',
              border: '1px solid #475569',
              marginBottom: '8px',
            }}
          >
            {courseTees.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name} Tee ({t.color})
              </option>
            ))}
          </select>
          <button
            onClick={() => setActiveMode('SET_TEE_MARKER')}
            style={{
              width: '100%',
              padding: '8px',
              borderRadius: '6px',
              border: 'none',
              backgroundColor: activeMode === 'SET_TEE_MARKER' ? '#8b5cf6' : '#334155',
              color: '#ffffff',
              cursor: 'pointer',
              fontSize: '12px',
            }}
          >
            📍 Place Selected Tee Marker (Click on map)
          </button>
        </div>

        {/* Existing Polygons List */}
        <div>
          <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1', display: 'block', marginBottom: '8px' }}>
            EXISTING HOLE POLYGONS ({mapFeatures.filter((f) => f.properties.element === 'VECTOR_POLYGON').length})
          </label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '180px', overflowY: 'auto' }}>
            {mapFeatures
              .filter((f) => f.properties.element === 'VECTOR_POLYGON')
              .map((poly) => (
                <div
                  key={poly.id}
                  style={{
                    backgroundColor: '#0f172a',
                    padding: '8px 12px',
                    borderRadius: '6px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    fontSize: '12px',
                  }}
                >
                  <span style={{ color: POLYGON_STYLES[poly.properties.type]?.color || '#ffffff', fontWeight: 'bold' }}>
                    {poly.properties.type}
                  </span>
                  <button
                    onClick={() => handleDeletePolygon(poly.id)}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: '#f87171',
                      cursor: 'pointer',
                    }}
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
          </div>
        </div>
      </div>
    </div>
  );
};
