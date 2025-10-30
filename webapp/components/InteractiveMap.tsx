"use client";

import { useEffect, useRef, useState } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import { motion, AnimatePresence } from "framer-motion";
import { StateData, STATES_DATA } from "@/data/states";
import StatePopup from "./StatePopup";
import { getSeverityColor } from "@/lib/utils";
import { X } from "lucide-react";

// Mapbox token - você vai precisar adicionar o seu!
mapboxgl.accessToken =
  process.env.NEXT_PUBLIC_MAPBOX_TOKEN ||
  "pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw";

export default function InteractiveMap() {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const [selectedState, setSelectedState] = useState<StateData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!mapContainer.current || map.current) return;

    // Initialize map
    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: "mapbox://styles/mapbox/dark-v11",
      center: [-95.7129, 37.0902],
      zoom: 3.5,
      pitch: 0,
      bearing: 0,
      attributionControl: false,
    });

    map.current.on("load", () => {
      setIsLoading(false);

      // Add US states layer
      map.current?.addSource("states", {
        type: "geojson",
        data: "https://raw.githubusercontent.com/PublicaMundi/MappingAPI/master/data/geojson/us-states.json",
      });

      // Add fill layer with severity colors
      map.current?.addLayer({
        id: "states-fill",
        type: "fill",
        source: "states",
        paint: {
          "fill-color": [
            "match",
            ["get", "name"],
            "Texas",
            getSeverityColor(100),
            "Florida",
            getSeverityColor(100),
            "California",
            getSeverityColor(38),
            "New York",
            getSeverityColor(35),
            "Hawaii",
            getSeverityColor(20),
            "Louisiana",
            getSeverityColor(95),
            "Vermont",
            getSeverityColor(22),
            "Massachusetts",
            getSeverityColor(28),
            "Washington",
            getSeverityColor(35),
            "Illinois",
            getSeverityColor(38),
            "#666666", // Default color for states without data
          ],
          "fill-opacity": [
            "case",
            ["boolean", ["feature-state", "hover"], false],
            0.9,
            0.7,
          ],
        },
      });

      // Add border layer
      map.current?.addLayer({
        id: "states-border",
        type: "line",
        source: "states",
        paint: {
          "line-color": "#ffffff",
          "line-width": [
            "case",
            ["boolean", ["feature-state", "hover"], false],
            3,
            1,
          ],
          "line-opacity": 0.5,
        },
      });

      // Add glow effect on hover
      let hoveredStateId: string | number | null = null;

      map.current?.on("mousemove", "states-fill", (e) => {
        if (e.features && e.features.length > 0) {
          if (hoveredStateId !== null) {
            map.current?.setFeatureState(
              { source: "states", id: hoveredStateId },
              { hover: false }
            );
          }
          hoveredStateId = e.features[0].id || null;
          if (hoveredStateId !== null) {
            map.current?.setFeatureState(
              { source: "states", id: hoveredStateId },
              { hover: true }
            );
          }
        }
        if (map.current) {
          map.current.getCanvas().style.cursor = "pointer";
        }
      });

      map.current?.on("mouseleave", "states-fill", () => {
        if (hoveredStateId !== null) {
          map.current?.setFeatureState(
            { source: "states", id: hoveredStateId },
            { hover: false }
          );
        }
        hoveredStateId = null;
        if (map.current) {
          map.current.getCanvas().style.cursor = "";
        }
      });

      // Handle clicks
      map.current?.on("click", "states-fill", (e) => {
        if (e.features && e.features.length > 0) {
          const feature = e.features[0];
          const stateName = feature.properties?.name;

          // Find state data
          const stateData = Object.values(STATES_DATA).find(
            (s) => s.name === stateName
          );

          if (stateData) {
            setSelectedState(stateData);

            // Smooth fly to state
            map.current?.flyTo({
              center: [stateData.center.lng, stateData.center.lat],
              zoom: stateData.center.zoom,
              duration: 2000,
              essential: true,
              curve: 1.42,
              easing: (t) =>
                t < 0.5
                  ? 4 * t * t * t
                  : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1,
            });
          }
        }
      });
    });

    // Cleanup
    return () => {
      map.current?.remove();
      map.current = null;
    };
  }, []);

  const handleReset = () => {
    setSelectedState(null);
    map.current?.flyTo({
      center: [-95.7129, 37.0902],
      zoom: 3.5,
      duration: 1500,
      essential: true,
    });
  };

  return (
    <div className="relative w-full h-screen">
      {/* Loading overlay */}
      <AnimatePresence>
        {isLoading && (
          <motion.div
            initial={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 z-50 flex items-center justify-center bg-gray-900"
          >
            <div className="text-center">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"
              />
              <p className="text-white text-xl font-semibold">Loading Map...</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Map container */}
      <div ref={mapContainer} className="w-full h-full" />

      {/* Title overlay */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="absolute top-6 left-6 z-10"
      >
        <div className="backdrop-blur-xl bg-white/10 rounded-2xl px-6 py-4 shadow-2xl border border-white/20">
          <h1 className="text-3xl font-bold text-white mb-1">
            🇺🇸 US Law Severity Map
          </h1>
          <p className="text-white/70 text-sm">
            Click any state to explore detailed statistics
          </p>
        </div>
      </motion.div>

      {/* Legend */}
      <motion.div
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        className="absolute top-6 right-6 z-10"
      >
        <div className="backdrop-blur-xl bg-white/10 rounded-2xl px-4 py-3 shadow-2xl border border-white/20">
          <h3 className="text-white font-semibold mb-2 text-sm">
            Severity Scale
          </h3>
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <div
                className="w-4 h-4 rounded"
                style={{ backgroundColor: getSeverityColor(100) }}
              />
              <span className="text-white/80 text-xs">
                Very Severe (95-100)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <div
                className="w-4 h-4 rounded"
                style={{ backgroundColor: getSeverityColor(75) }}
              />
              <span className="text-white/80 text-xs">Severe (65-94)</span>
            </div>
            <div className="flex items-center gap-2">
              <div
                className="w-4 h-4 rounded"
                style={{ backgroundColor: getSeverityColor(50) }}
              />
              <span className="text-white/80 text-xs">Moderate (40-64)</span>
            </div>
            <div className="flex items-center gap-2">
              <div
                className="w-4 h-4 rounded"
                style={{ backgroundColor: getSeverityColor(25) }}
              />
              <span className="text-white/80 text-xs">Lenient (20-39)</span>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Reset button */}
      <AnimatePresence>
        {selectedState && (
          <motion.button
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.8 }}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={handleReset}
            className="absolute bottom-6 right-6 z-10 backdrop-blur-xl bg-white/10 rounded-full p-4 shadow-2xl border border-white/20 text-white hover:bg-white/20 transition-colors"
          >
            <X className="w-6 h-6" />
          </motion.button>
        )}
      </AnimatePresence>

      {/* State popup */}
      <AnimatePresence>
        {selectedState && (
          <StatePopup state={selectedState} onClose={handleReset} />
        )}
      </AnimatePresence>
    </div>
  );
}
