package com.techgolf.app.domain

import com.techgolf.app.data.models.GolfBagClub
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Game Mode Scoring Engine implementing:
 * - Stroke Play
 * - Stableford Points
 * - Match Play
 * - Scramble & Four-Ball
 */
object GameModeEngine {

    enum class Mode(val code: String, val displayName: String) {
        STROKE_PLAY("STROKE_PLAY", "Stroke Play"),
        STABLEFORD("STABLEFORD", "Stableford"),
        MATCH_PLAY("MATCH_PLAY", "Match Play"),
        SCRAMBLE("SCRAMBLE", "Scramble"),
        FOUR_BALL("FOUR_BALL", "Four-Ball")
    }

    /**
     * Calculates Stableford points for a single hole:
     * Net Double Bogey or worse = 0 pts
     * Net Bogey = 1 pt
     * Net Par = 2 pts
     * Net Birdie = 3 pts
     * Net Eagle = 4 pts
     * Net Albatross = 5 pts
     */
    fun calculateStablefordPoints(netScore: Int, par: Int): Int {
        val diff = netScore - par
        return when {
            diff >= 2 -> 0
            diff == 1 -> 1
            diff == 0 -> 2
            diff == -1 -> 3
            diff == -2 -> 4
            diff <= -3 -> 5
            else -> 0
        }
    }

    /**
     * Calculates Match Play standing between 2 players / teams across completed holes.
     * Positive = Player 1 is UP, Negative = Player 2 is UP, 0 = All Square (AS).
     */
    fun calculateMatchPlayStanding(
        player1Scores: List<Int>,
        player2Scores: List<Int>
    ): Pair<Int, String> {
        var p1HolesWon = 0
        var p2HolesWon = 0
        val minHoles = minOf(player1Scores.size, player2Scores.size)

        for (i in 0 until minHoles) {
            val s1 = player1Scores[i]
            val s2 = player2Scores[i]
            if (s1 < s2) p1HolesWon++
            else if (s2 < s1) p2HolesWon++
        }

        val netAdvantage = p1HolesWon - p2HolesWon
        val remainingHoles = 18 - minHoles

        val statusText = when {
            netAdvantage == 0 -> "All Square (AS)"
            netAdvantage > 0 -> {
                if (netAdvantage > remainingHoles) "${abs(netAdvantage)} & $remainingHoles (P1 Wins)"
                else "${abs(netAdvantage)} UP (P1)"
            }
            else -> {
                if (abs(netAdvantage) > remainingHoles) "${abs(netAdvantage)} & $remainingHoles (P2 Wins)"
                else "${abs(netAdvantage)} UP (P2)"
            }
        }

        return Pair(netAdvantage, statusText)
    }
}

/**
 * Caddie Club Recommendation Engine
 * Matches target distance to player's actual recorded bag distances.
 */
object ClubRecommendationEngine {
    fun recommendClub(
        targetDistanceYards: Double,
        clubs: List<GolfBagClub>
    ): GolfBagClub? {
        val activeClubs = clubs.filter { it.isActive && it.averageDistanceMeters > 0.0 }
        if (activeClubs.isEmpty()) return null

        // Find club whose average distance is closest to target distance
        return activeClubs.minByOrNull {
            abs(it.averageDistanceYards - targetDistanceYards)
        }
    }
}

/**
 * World Handicap System (WHS) Engine
 * Implements USGA/WHS Rules of Handicapping:
 * - Score Differential = (113 / Slope Rating) * (Adjusted Gross Score - Course Rating - PCC)
 * - Handicap Index calculation based on number of rounds (e.g. Lowest 8 of 20).
 */
object WhsHandicapEngine {

    fun calculateScoreDifferential(
        adjustedGrossScore: Int,
        courseRating: Double,
        slopeRating: Int,
        pcc: Double = 0.0
    ): Double {
        val diff = (113.0 / slopeRating.toDouble()) * (adjustedGrossScore.toDouble() - courseRating - pcc)
        // Round to 1 decimal place
        return (diff * 10.0).roundToInt() / 10.0
    }

    /**
     * Calculates WHS Handicap Index from a list of differentials.
     * Follows official WHS sliding scale based on available scores (up to 20).
     */
    fun calculateHandicapIndex(differentials: List<Double>): Double {
        if (differentials.isEmpty()) return 54.0

        val sorted = differentials.sorted()
        val count = sorted.size

        val (usedCount, adjustment) = when (count) {
            1, 2 -> Pair(1, -2.0)
            3 -> Pair(1, -2.0)
            4 -> Pair(1, -1.0)
            5 -> Pair(1, 0.0)
            6 -> Pair(2, -1.0)
            7, 8 -> Pair(2, 0.0)
            9, 10, 11 -> Pair(3, 0.0)
            12, 13, 14 -> Pair(4, 0.0)
            15, 16 -> Pair(5, 0.0)
            17, 18 -> Pair(6, 0.0)
            19 -> Pair(7, 0.0)
            else -> Pair(8, 0.0) // 20 or more: Lowest 8 of 20
        }

        val lowest = sorted.take(usedCount)
        val average = lowest.average() + adjustment
        val index = (average * 10.0).roundToInt() / 10.0
        return index.coerceIn(-10.0, 54.0)
    }

    /**
     * Computes Course Handicap: Handicap Index * (Slope / 113) + (Course Rating - Par)
     */
    fun calculateCourseHandicap(
        handicapIndex: Double,
        slopeRating: Int,
        courseRating: Double,
        par: Int
    ): Int {
        val ch = handicapIndex * (slopeRating.toDouble() / 113.0) + (courseRating - par.toDouble())
        return ch.roundToInt()
    }
}
