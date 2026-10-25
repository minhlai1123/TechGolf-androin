package com.techgolf.app.data.repository

import com.techgolf.app.core.geo.DistanceEngine
import com.techgolf.app.core.supabase.SupabaseClientManager
import com.techgolf.app.data.models.*
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.util.UUID

class AuthRepository {
    private val client = SupabaseClientManager.client

    val currentUserId: String?
        get() = client.auth.currentUserOrNull()?.id

    suspend fun signUp(email: String, pass: String, fullName: String): Result<Unit> = runCatching {
        client.auth.signUpWith(Email) {
            this.email = email
            this.password = pass
            data = buildJsonObject {
                put("full_name", fullName)
            }
        }
    }

    suspend fun signIn(email: String, pass: String): Result<Unit> = runCatching {
        client.auth.signInWith(Email) {
            this.email = email
            this.password = pass
        }
    }

    suspend fun signOut(): Result<Unit> = runCatching {
        client.auth.signOut()
    }

    suspend fun getCurrentProfile(): Profile? {
        val uid = currentUserId ?: return null
        return runCatching {
            client.from("profiles")
                .select {
                    filter { eq("id", uid) }
                }
                .decodeSingleOrNull<Profile>()
        }.getOrNull()
    }
}

class CourseRepository {
    private val client = SupabaseClientManager.client

    suspend fun getCourses(): List<Course> {
        return client.from("courses")
            .select {
                filter { eq("status", "ACTIVE") }
            }
            .decodeList()
    }

    suspend fun getHoles(courseId: String): List<Hole> {
        return client.from("holes")
            .select {
                filter { eq("course_id", courseId) }
            }
            .decodeList<Hole>()
            .sortedBy { it.holeNumber }
    }

    suspend fun getCourseTees(courseId: String): List<CourseTee> {
        return client.from("course_tees")
            .select {
                filter { eq("course_id", courseId) }
            }
            .decodeList()
    }

    suspend fun getHolePolygons(holeId: String): List<HolePolygon> {
        return client.from("hole_polygons")
            .select {
                filter { eq("hole_id", holeId) }
            }
            .decodeList()
    }
}

class RoundRepository {
    private val client = SupabaseClientManager.client

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

        client.from("rounds").insert(newRound)

        playerNames.forEachIndexed { index, name ->
            val player = RoundPlayer(
                id = UUID.randomUUID().toString(),
                roundId = roundId,
                playerName = name,
                playerOrder = index + 1,
                userId = if (index == 0) creatorId else null
            )
            client.from("round_players").insert(player)
        }

        newRound
    }

    suspend fun getRoundPlayers(roundId: String): List<RoundPlayer> {
        return client.from("round_players")
            .select {
                filter { eq("round_id", roundId) }
            }
            .decodeList<RoundPlayer>()
            .sortedBy { it.playerOrder }
    }

    suspend fun getRoundScores(roundId: String): List<RoundScore> {
        return client.from("round_scores")
            .select {
                filter { eq("round_id", roundId) }
            }
            .decodeList()
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

        client.from("round_scores").upsert(score) {
            onConflict = "round_id,player_id,hole_id"
        }
    }

    suspend fun finishRound(roundId: String): Result<Unit> = runCatching {
        client.from("rounds").update(
            mapOf("status" to "COMPLETED")
        ) {
            filter { eq("id", roundId) }
        }
    }

    /**
     * Subscribes to live score changes across all players in the round via Supabase Realtime
     */
    fun subscribeToRoundScores(roundId: String): Flow<RoundScore> {
        val channel = client.realtime.channel("round_scores_$roundId")
        return channel.postgresChangeFlow<RoundScore>(schema = "public") {
            table = "round_scores"
            filter = "round_id=eq.$roundId"
        }
    }
}

class ShotRepository {
    private val client = SupabaseClientManager.client

    suspend fun getUserClubs(userId: String): List<GolfBagClub> {
        return client.from("golf_bag_clubs")
            .select {
                filter {
                    eq("user_id", userId)
                    eq("is_active", true)
                }
            }
            .decodeList()
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
        client.from("shots").insert(shot)
        shot
    }

    suspend fun saveShot(
        shotId: String,
        endLat: Double,
        endLng: Double,
        endElevation: Double?,
        clubId: String?
    ): Result<Unit> = runCatching {
        val existing = client.from("shots").select {
            filter { eq("id", shotId) }
        }.decodeSingle<Shot>()

        val distanceYards = DistanceEngine.distanceBetweenYards(
            existing.startLatitude, existing.startLongitude,
            endLat, endLng
        )

        val elevDelta = if (existing.startElevation != null && endElevation != null) {
            endElevation - existing.startElevation
        } else null

        client.from("shots").update(
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
}
