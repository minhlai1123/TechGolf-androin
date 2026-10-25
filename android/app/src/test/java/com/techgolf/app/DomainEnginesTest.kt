package com.techgolf.app

import com.techgolf.app.core.geo.DistanceEngine
import com.techgolf.app.data.models.GolfBagClub
import com.techgolf.app.domain.ClubRecommendationEngine
import com.techgolf.app.domain.GameModeEngine
import com.techgolf.app.domain.WhsHandicapEngine
import org.junit.Assert.*
import org.junit.Test

class DomainEnginesTest {

    @Test
    fun testHaversineDistanceCalculation() {
        // Two points ~150 meters apart
        val lat1 = 21.028500
        val lng1 = 105.854200
        val lat2 = 21.029800
        val lng2 = 105.854200

        val meters = DistanceEngine.distanceBetweenMeters(lat1, lng1, lat2, lng2)
        val yards = DistanceEngine.distanceBetweenYards(lat1, lng1, lat2, lng2)

        assertTrue("Distance should be around 144-145 meters", meters in 140.0..150.0)
        assertTrue("Yards should be greater than meters", yards > meters)
    }

    @Test
    fun testPlaysLikeDistance() {
        val flatYards = 150.0
        val uphillAdjusted = DistanceEngine.calculatePlaysLikeYards(flatYards, elevationDeltaMeters = 10.0)
        val downhillAdjusted = DistanceEngine.calculatePlaysLikeYards(flatYards, elevationDeltaMeters = -10.0)

        assertTrue("Uphill must play longer than flat", uphillAdjusted > flatYards)
        assertTrue("Downhill must play shorter than flat", downhillAdjusted < flatYards)
    }

    @Test
    fun testStablefordScoring() {
        val par = 4
        assertEquals("Albatross = 5 pts", 5, GameModeEngine.calculateStablefordPoints(netScore = 1, par = par))
        assertEquals("Eagle = 4 pts", 4, GameModeEngine.calculateStablefordPoints(netScore = 2, par = par))
        assertEquals("Birdie = 3 pts", 3, GameModeEngine.calculateStablefordPoints(netScore = 3, par = par))
        assertEquals("Par = 2 pts", 2, GameModeEngine.calculateStablefordPoints(netScore = 4, par = par))
        assertEquals("Bogey = 1 pt", 1, GameModeEngine.calculateStablefordPoints(netScore = 5, par = par))
        assertEquals("Double Bogey = 0 pts", 0, GameModeEngine.calculateStablefordPoints(netScore = 6, par = par))
        assertEquals("Triple Bogey = 0 pts", 0, GameModeEngine.calculateStablefordPoints(netScore = 7, par = par))
    }

    @Test
    fun testMatchPlayStanding() {
        val p1 = listOf(4, 3, 5, 4)
        val p2 = listOf(5, 3, 4, 5) // P1 wins h1 & h4, P2 wins h3, P1 is 1 UP

        val (advantage, text) = GameModeEngine.calculateMatchPlayStanding(p1, p2)
        assertEquals(1, advantage)
        assertTrue(text.contains("1 UP"))
    }

    @Test
    fun testClubRecommendation() {
        val clubs = listOf(
            GolfBagClub("1", "u1", "DRIVER", "Driver", 220.0),
            GolfBagClub("2", "u1", "IRON_7", "7 Iron", 140.0), // ~153 yds
            GolfBagClub("3", "u1", "PITCHING_WEDGE", "PW", 110.0) // ~120 yds
        )

        val recommended = ClubRecommendationEngine.recommendClub(150.0, clubs)
        assertNotNull(recommended)
        assertEquals("7 Iron", recommended?.customName)
    }

    @Test
    fun testWhsHandicapCalculation() {
        val diff = WhsHandicapEngine.calculateScoreDifferential(
            adjustedGrossScore = 85,
            courseRating = 72.0,
            slopeRating = 130,
            pcc = 0.0
        )
        // (113 / 130) * (85 - 72) = 0.86923 * 13 = 11.3
        assertEquals(11.3, diff, 0.1)

        val differentials = listOf(11.3, 10.5, 9.8, 12.0, 14.1, 13.0, 8.5, 9.2, 10.1, 11.0)
        val index = WhsHandicapEngine.calculateHandicapIndex(differentials)
        assertTrue("Handicap index should be valid and formatted", index in 0.0..54.0)
    }
}
