package com.techgolf.app.core.geo

import kotlin.math.*

/**
 * Geodesic Distance Engine implementing WGS84 spherical Haversine formula
 * and Plays-Like distance calculations for golf rangefinding.
 * Reference: Hole19 Distance Specification
 */
object DistanceEngine {
    private const val EARTH_RADIUS_METERS = 6371000.0
    private const val METERS_TO_YARDS = 1.0936132983
    private const val YARDS_TO_METERS = 0.9144

    /**
     * Calculates geodesic distance between two points in meters using Haversine.
     */
    fun distanceBetweenMeters(
        lat1: Double,
        lng1: Double,
        lat2: Double,
        lng2: Double
    ): Double {
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        val a = sin(dLat / 2).pow(2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLng / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return EARTH_RADIUS_METERS * c
    }

    /**
     * Calculates distance in yards.
     */
    fun distanceBetweenYards(
        lat1: Double,
        lng1: Double,
        lat2: Double,
        lng2: Double
    ): Double {
        return metersToYards(distanceBetweenMeters(lat1, lng1, lat2, lng2))
    }

    fun metersToYards(meters: Double): Double = meters * METERS_TO_YARDS
    fun yardsToMeters(yards: Double): Double = yards * YARDS_TO_METERS

    /**
     * Calculates Plays-Like adjusted distance taking elevation delta into account.
     * Formula: 1 meter elevation change corresponds to ~1.05 yards adjusted play distance.
     */
    fun calculatePlaysLikeYards(
        flatDistanceYards: Double,
        elevationDeltaMeters: Double?,
        windSpeedMps: Double = 0.0,
        windDirectionAngleDeg: Double = 0.0
    ): Double {
        var adjusted = flatDistanceYards
        if (elevationDeltaMeters != null) {
            // Uphill plays longer (+), Downhill plays shorter (-)
            adjusted += (elevationDeltaMeters * 1.05)
        }
        // Wind adjustment: Headwind (+), Tailwind (-)
        if (windSpeedMps > 0.0) {
            val headwindComponent = windSpeedMps * cos(Math.toRadians(windDirectionAngleDeg))
            adjusted += (headwindComponent * 1.2)
        }
        return max(0.0, adjusted)
    }

    /**
     * Computes initial bearing from point 1 to point 2 in degrees (0-360).
     */
    fun calculateBearing(
        lat1: Double,
        lng1: Double,
        lat2: Double,
        lng2: Double
    ): Double {
        val phi1 = Math.toRadians(lat1)
        val phi2 = Math.toRadians(lat2)
        val dLambda = Math.toRadians(lng2 - lng1)

        val y = sin(dLambda) * cos(phi2)
        val x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda)
        val bearingRad = atan2(y, x)
        return (Math.toDegrees(bearingRad) + 360.0) % 360.0
    }
}
