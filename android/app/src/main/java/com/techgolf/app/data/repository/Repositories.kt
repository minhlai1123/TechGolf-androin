package com.techgolf.app.data.repository

import com.techgolf.app.core.geo.DistanceEngine
import com.techgolf.app.core.supabase.SupabaseClientManager
import com.techgolf.app.data.models.*
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.util.UUID

class AuthRepository {
    private val client get() = SupabaseClientManager.client

    val currentUserId: String?
        get() = try {
            client?.auth?.currentUserOrNull()?.id
        } catch (_: Exception) {
            null
        }

    suspend fun signUp(email: String, pass: String, fullName: String): Result<Unit> = runCatching {
        val c = client ?: throw IllegalStateException("Supabase chưa được cấu hình")
        c.auth.signUpWith(Email) {
            this.email = email
            this.password = pass
            data = buildJsonObject {
                put("full_name", fullName)
            }
        }
    }

    suspend fun signIn(email: String, pass: String): Result<Unit> = runCatching {
        val c = client ?: throw IllegalStateException("Supabase chưa được cấu hình. Vui lòng bấm biểu tượng Cài đặt góc trên để nhập Supabase URL & Key.")
        c.auth.signInWith(Email) {
            this.email = email
            this.password = pass
        }
    }

    suspend fun signOut(): Result<Unit> = runCatching {
        client?.auth?.signOut()
    }

    suspend fun getCurrentProfile(): Profile? {
        val uid = currentUserId ?: return null
        val c = client ?: return null
        return runCatching {
            c.from("profiles")
                .select {
                    filter { eq("id", uid) }
                }
                .decodeSingleOrNull<Profile>()
        }.getOrNull()
    }
}

class CourseRepository {
    private val client get() = SupabaseClientManager.client

    suspend fun getCourses(): List<Course> {
        val c = client ?: return getFallbackCourses()
        return try {
            val list = c.from("courses")
                .select {
                    filter { eq("status", "ACTIVE") }
                }
                .decodeList<Course>()
            if (list.isNotEmpty()) list else getFallbackCourses()
        } catch (_: Exception) {
            getFallbackCourses()
        }
    }

    suspend fun getHoles(courseId: String): List<Hole> {
        val c = client ?: return getFallbackHoles(courseId)
        return try {
            val list = c.from("holes")
                .select {
                    filter { eq("course_id", courseId) }
                }
                .decodeList<Hole>()
                .sortedBy { it.holeNumber }
            if (list.isNotEmpty()) list else getFallbackHoles(courseId)
        } catch (_: Exception) {
            getFallbackHoles(courseId)
        }
    }

    suspend fun getCourseTees(courseId: String): List<CourseTee> {
        val c = client ?: return getFallbackTees(courseId)
        return try {
            c.from("course_tees")
                .select {
                    filter { eq("course_id", courseId) }
                }
                .decodeList()
        } catch (_: Exception) {
            getFallbackTees(courseId)
        }
    }

    suspend fun getHolePolygons(holeId: String): List<HolePolygon> {
        val c = client ?: return emptyList()
        return try {
            c.from("hole_polygons")
                .select {
                    filter { eq("hole_id", holeId) }
                }
                .decodeList()
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun getFallbackCourses(): List<Course> = listOf(
        Course(
            id = "demo-pine-valley",
            name = "Pine Valley Championship Golf Club",
            address = "100 Fairway Boulevard, Golf Valley",
            city = "Hanoi",
            country = "Vietnam",
            latitude = 21.0285,
            longitude = 105.8542,
            totalHoles = 18,
            description = "Championship 18-hole golf facility."
        )
    )

    private fun getFallbackHoles(courseId: String): List<Hole> = (1..9).map { num ->
        val par = if (num == 2 || num == 6) 3 else if (num == 3 || num == 7) 5 else 4
        Hole(
            id = "hole-$num",
            courseId = courseId,
            holeNumber = num,
            par = par,
            handicapIndex = num * 2,
            greenCenterLat = 21.0310 + num * 0.001,
            greenCenterLng = 105.8560 + num * 0.001,
            greenFrontLat = 21.0308 + num * 0.001,
            greenFrontLng = 105.8558 + num * 0.001,
            greenBackLat = 21.0312 + num * 0.001,
            greenBackLng = 21.0312 + num * 0.001
        )
    }

    private fun getFallbackTees(courseId: String): List<CourseTee> = listOf(
        CourseTee("t-1", courseId, "Black", "#0F172A", 75.2, 142, 7250),
        CourseTee("t-2", courseId, "Blue", "#2563EB", 73.1, 135, 6820),
        CourseTee("t-3", courseId, "White", "#F8FAFC", 71.0, 128, 6410),
        CourseTee("t-4", courseId, "Red", "#EF4444", 69.5, 120, 5890)
    )
}

class RoundRepository {
    private val client get() = SupabaseClientManager.client

    // Local in-memory cache fallback if Supabase is offline or not configured
    private val memoryScores = mutableMapOf<String, RoundScore>()

    suspend fun createRound(
        courseId: String,
        gameMode: String,
        playerNames: List<String>,
        creatorId: String
    ): Result<Round> = runCatching {
        val roundId = UUID.randomUUID().toString()
        val newRound = Round(
            id = roundId,
            courseId = courseId,
            gameMode = gameMode,
            status = "IN_PROGRESS",
            createdBy = creatorId
        )

        client?.from("rounds")?.insert(newRound)

        playerNames.forEachIndexed { index, name ->
            val player = RoundPlayer(
                id = UUID.randomUUID().toString(),
                roundId = roundId,
                playerName = name,
                playerOrder = index + 1,
                userId = if (index == 0) creatorId else null
            )
            client?.from("round_players")?.insert(player)
        }

        newRound
    }

    suspend fun getRoundPlayers(roundId: String): List<RoundPlayer> {
        val c = client ?: return listOf(RoundPlayer("p-1", roundId, null, null, "Tôi (Golfer)", 1))
        return try {
            val list = c.from("round_players")
                .select {
                    filter { eq("round_id", roundId) }
                }
                .decodeList<RoundPlayer>()
                .sortedBy { it.playerOrder }
            if (list.isNotEmpty()) list else listOf(RoundPlayer("p-1", roundId, null, null, "Tôi (Golfer)", 1))
        } catch (_: Exception) {
            listOf(RoundPlayer("p-1", roundId, null, null, "Tôi (Golfer)", 1))
        }
    }

    suspend fun getRoundScores(roundId: String): List<RoundScore> {
        val c = client ?: return memoryScores.values.filter { it.roundId == roundId }
        return try {
            c.from("round_scores")
                .select {
                    filter { eq("round_id", roundId) }
                }
                .decodeList()
        } catch (_: Exception) {
            memoryScores.values.filter { it.roundId == roundId }
        }
    }

    suspend fun saveScore(
        roundId: String,
        playerId: String,
        holeId: String,
        gross: Int,
        putts: Int,
        penalties: Int,
        fairwayHit: String?,
        gir: Boolean?
    ): Result<Unit> = runCatching {
        val score = RoundScore(
            id = UUID.randomUUID().toString(),
            roundId = roundId,
            playerId = playerId,
            holeId = holeId,
            grossScore = gross,
            putts = putts,
            penalties = penalties,
            fairwayHit = fairwayHit,
            gir = gir
        )

        memoryScores["${roundId}_${playerId}_${holeId}"] = score

        client?.from("round_scores")?.upsert(score) {
            onConflict = "round_id,player_id,hole_id"
        }
    }

    suspend fun finishRound(roundId: String): Result<Unit> = runCatching {
        client?.from("rounds")?.update(
            mapOf("status" to "COMPLETED")
        ) {
            filter { eq("id", roundId) }
        }
    }

    fun subscribeToRoundScores(roundId: String): Flow<RoundScore> {
        val c = client ?: return emptyFlow()
        return try {
            val channel = c.realtime.channel("round_scores_$roundId")
            channel.postgresChangeFlow(schema = "public") {
                table = "round_scores"
                filter = "round_id=eq.$roundId"
            }
        } catch (_: Exception) {
            emptyFlow()
        }
    }
}

class ShotRepository {
    private val client get() = SupabaseClientManager.client

    suspend fun getUserClubs(userId: String): List<GolfBagClub> {
        val c = client ?: return getFallbackClubs()
        return try {
            val list = c.from("golf_bag_clubs")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("is_active", true)
                    }
                }
                .decodeList<GolfBagClub>()
            if (list.isNotEmpty()) list else getFallbackClubs()
        } catch (_: Exception) {
            getFallbackClubs()
        }
    }

    suspend fun startShot(
        roundId: String,
        playerId: String,
        userId: String?,
        holeId: String,
        clubId: String?,
        lat: Double,
        lng: Double,
        elevation: Double? = null
    ): Result<Shot> = runCatching {
        val shot = Shot(
            id = UUID.randomUUID().toString(),
            roundId = roundId,
            playerId = playerId,
            userId = userId,
            holeId = holeId,
            clubId = clubId,
            status = "STARTED",
            startLatitude = lat,
            startLongitude = lng,
            startElevation = elevation
        )
        client?.from("shots")?.insert(shot)
        shot
    }

    suspend fun saveShot(
        shotId: String,
        endLat: Double,
        endLng: Double,
        endElevation: Double?,
        clubId: String?
    ): Result<Unit> = runCatching {
        val c = client ?: return@runCatching
        val existing = c.from("shots").select {
            filter { eq("id", shotId) }
        }.decodeSingle<Shot>()

        val distanceYards = DistanceEngine.distanceBetweenYards(
            existing.startLatitude, existing.startLongitude,
            endLat, endLng
        )

        val elevDelta = if (existing.startElevation != null && endElevation != null) {
            endElevation - existing.startElevation
        } else null

        c.from("shots").update(
            mapOf(
                "end_latitude" to endLat,
                "end_longitude" to endLng,
                "end_elevation" to endElevation,
                "elevation_delta" to elevDelta,
                "distance" to distanceYards,
                "status" to "SAVED",
                "club_id" to clubId
            )
        ) {
            filter { eq("id", shotId) }
        }
    }

    private fun getFallbackClubs(): List<GolfBagClub> = listOf(
        GolfBagClub("c-1", "u-1", "DRIVER", "Driver 10.5°", 215.0),
        GolfBagClub("c-2", "u-1", "WOOD_3", "3-Wood 15°", 195.0),
        GolfBagClub("c-3", "u-1", "HYBRID_4", "4-Hybrid 22°", 175.0),
        GolfBagClub("c-4", "u-1", "IRON_7", "7 Iron", 145.0),
        GolfBagClub("c-5", "u-1", "PITCHING_WEDGE", "PW 46°", 115.0),
        GolfBagClub("c-6", "u-1", "SAND_WEDGE", "SW 54°", 85.0),
        GolfBagClub("c-7", "u-1", "PUTTER", "Blade Putter", 0.0)
    )
}
