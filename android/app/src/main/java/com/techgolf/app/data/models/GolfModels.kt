package com.techgolf.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Profile(
    val id: String,
    val email: String,
    @SerialName("full_name") val fullName: String,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("handicap_index") val handicapIndex: Double = 54.0,
    val role: String = "USER",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
data class GolfBagClub(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("club_type") val clubType: String,
    @SerialName("custom_name") val customName: String? = null,
    @SerialName("average_distance_meters") val averageDistanceMeters: Double = 0.0,
    @SerialName("total_shots_recorded") val totalShotsRecorded: Int = 0,
    @SerialName("is_active") val isActive: Boolean = true
) {
    val averageDistanceYards: Double
        get() = averageDistanceMeters * 1.093613
}

@Serializable
data class Course(
    val id: String,
    val name: String,
    val address: String,
    val city: String,
    val country: String,
    val latitude: Double,
    val longitude: Double,
    val timezone: String = "Asia/Ho_Chi_Minh",
    @SerialName("total_holes") val totalHoles: Int = 18,
    val description: String? = null,
    val status: String = "ACTIVE"
)

@Serializable
data class CourseTee(
    val id: String,
    @SerialName("course_id") val courseId: String,
    val name: String,
    val color: String,
    val rating: Double,
    @SerialName("slope_rating") val slopeRating: Int,
    @SerialName("total_yardage") val totalYardage: Int? = null
)

@Serializable
data class Hole(
    val id: String,
    @SerialName("course_id") val courseId: String,
    @SerialName("hole_number") val holeNumber: Int,
    val par: Int,
    @SerialName("handicap_index") val handicapIndex: Int,
    @SerialName("green_center_lat") val greenCenterLat: Double? = null,
    @SerialName("green_center_lng") val greenCenterLng: Double? = null,
    @SerialName("green_front_lat") val greenFrontLat: Double? = null,
    @SerialName("green_front_lng") val greenFrontLng: Double? = null,
    @SerialName("green_back_lat") val greenBackLat: Double? = null,
    @SerialName("green_back_lng") val greenBackLng: Double? = null
)

@Serializable
data class HoleTee(
    val id: String,
    @SerialName("hole_id") val holeId: String,
    @SerialName("course_tee_id") val courseTeeId: String,
    @SerialName("tee_lat") val teeLat: Double? = null,
    @SerialName("tee_lng") val teeLng: Double? = null,
    @SerialName("distance_meters") val distanceMeters: Int? = null
)

@Serializable
data class HolePolygon(
    val id: String,
    @SerialName("hole_id") val holeId: String,
    @SerialName("polygon_type") val polygonType: String,
    val geojson: String? = null,
    val metadata: String? = null
)

@Serializable
data class Round(
    val id: String,
    @SerialName("course_id") val courseId: String,
    @SerialName("game_mode") val gameMode: String = "STROKE_PLAY",
    val status: String = "NOT_STARTED",
    @SerialName("current_hole") val currentHole: Int = 1,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("finished_at") val finishedAt: String? = null,
    @SerialName("created_by") val createdBy: String
)

@Serializable
data class RoundPlayer(
    val id: String,
    @SerialName("round_id") val roundId: String,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("tee_id") val teeId: String? = null,
    @SerialName("player_name") val playerName: String,
    @SerialName("player_order") val playerOrder: Int,
    @SerialName("team_id") val teamId: String? = null
)

@Serializable
data class RoundScore(
    val id: String,
    @SerialName("round_id") val roundId: String,
    @SerialName("player_id") val playerId: String,
    @SerialName("hole_id") val holeId: String,
    @SerialName("gross_score") val grossScore: Int,
    val putts: Int = 0,
    val penalties: Int = 0,
    @SerialName("fairway_hit") val fairwayHit: String? = null,
    val gir: Boolean? = null
)

@Serializable
data class Shot(
    val id: String,
    @SerialName("round_id") val roundId: String,
    @SerialName("player_id") val playerId: String,
    @SerialName("user_id") val userId: String? = null,
    @SerialName("hole_id") val holeId: String,
    @SerialName("club_id") val clubId: String? = null,
    val status: String = "STARTED",
    @SerialName("start_latitude") val startLatitude: Double,
    @SerialName("start_longitude") val startLongitude: Double,
    @SerialName("start_elevation") val startElevation: Double? = null,
    @SerialName("end_latitude") val endLatitude: Double? = null,
    @SerialName("end_longitude") val endLongitude: Double? = null,
    @SerialName("end_elevation") val endElevation: Double? = null,
    @SerialName("elevation_delta") val elevationDelta: Double? = null,
    val distance: Double? = null,
    @SerialName("distance_unit") val distanceUnit: String = "YARDS"
)

@Serializable
data class HandicapRecord(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("round_id") val roundId: String? = null,
    @SerialName("score_differential") val scoreDifferential: Double,
    @SerialName("resulting_handicap_index") val resultingHandicapIndex: Double,
    @SerialName("rounds_count") val roundsCount: Int = 0,
    @SerialName("differentials_used_count") val differentialsUsedCount: Int = 0,
    @SerialName("calculated_at") val calculatedAt: String? = null
)

@Serializable
data class ScoreDifferential(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("round_id") val roundId: String,
    @SerialName("course_id") val courseId: String,
    @SerialName("gross_score") val grossScore: Int,
    @SerialName("adjusted_gross_score") val adjustedGrossScore: Int,
    @SerialName("course_rating") val courseRating: Double,
    @SerialName("slope_rating") val slopeRating: Int,
    val pcc: Double = 0.0,
    @SerialName("score_differential") val scoreDifferential: Double,
    @SerialName("is_used_in_handicap") val isUsedInHandicap: Boolean = false,
    @SerialName("played_at") val playedAt: String
)
