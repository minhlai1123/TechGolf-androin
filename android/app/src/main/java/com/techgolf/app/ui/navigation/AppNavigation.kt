package com.techgolf.app.ui.navigation

import androidx.compose.runtime.*
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.techgolf.app.data.models.GolfBagClub
import com.techgolf.app.data.models.Hole
import com.techgolf.app.data.models.RoundPlayer
import com.techgolf.app.data.repository.AuthRepository
import com.techgolf.app.data.repository.CourseRepository
import com.techgolf.app.data.repository.RoundRepository
import com.techgolf.app.data.repository.ShotRepository
import com.techgolf.app.ui.screens.auth.LoginScreen
import com.techgolf.app.ui.screens.auth.RegisterScreen
import com.techgolf.app.ui.screens.courses.CourseListScreen
import com.techgolf.app.ui.screens.features.LivePlayLeaderboardScreen
import com.techgolf.app.ui.screens.features.ShotTrackerScreen
import com.techgolf.app.ui.screens.features.StatsDashboardScreen
import com.techgolf.app.ui.screens.rangefinder.GpsRangefinderScreen
import com.techgolf.app.ui.screens.scorecard.RoundSetupScreen
import com.techgolf.app.ui.screens.scorecard.ScoreEntryScreen
import com.techgolf.app.ui.screens.scorecard.ScorecardScreen

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authRepo = remember { AuthRepository() }
    val courseRepo = remember { CourseRepository() }
    val roundRepo = remember { RoundRepository() }
    val shotRepo = remember { ShotRepository() }

    // Active session state
    var activeCourseId by remember { mutableStateOf<String?>(null) }
    var activeRoundId by remember { mutableStateOf<String?>(null) }
    var activeHoles by remember { mutableStateOf<List<Hole>>(emptyList()) }
    var activePlayers by remember { mutableStateOf<List<RoundPlayer>>(emptyList()) }
    var userClubs by remember { mutableStateOf<List<GolfBagClub>>(emptyList()) }

    // Check auth status
    val startDestination = if (authRepo.currentUserId != null) "courses" else "login"

    NavHost(navController = navController, startDestination = startDestination) {
        composable("login") {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate("courses") {
                        popUpTo("login") { inclusive = true }
                    }
                },
                onNavigateToRegister = { navController.navigate("register") }
            )
        }

        composable("register") {
            RegisterScreen(
                onRegisterSuccess = {
                    navController.navigate("courses") {
                        popUpTo("register") { inclusive = true }
                    }
                },
                onNavigateToLogin = { navController.popBackStack() }
            )
        }

        composable("courses") {
            CourseListScreen(
                onSelectCourseForRound = { courseId ->
                    activeCourseId = courseId
                    navController.navigate("round_setup")
                },
                onNavigateToStats = { navController.navigate("stats") }
            )
        }

        composable("round_setup") {
            val cId = activeCourseId ?: return@composable
            val uid = authRepo.currentUserId ?: "guest-uid"

            RoundSetupScreen(
                courseId = cId,
                currentUserId = uid,
                onStartRound = { rId ->
                    activeRoundId = rId
                    // Load holes & clubs in background
                    navController.navigate("rangefinder") {
                        popUpTo("round_setup") { inclusive = true }
                    }
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable("rangefinder") {
            val cId = activeCourseId ?: "demo-course"
            val rId = activeRoundId ?: "demo-round"

            LaunchedEffect(cId, rId) {
                activeHoles = try {
                    val loaded = courseRepo.getHoles(cId)
                    if (loaded.isNotEmpty()) loaded else getFallbackHoles(cId)
                } catch (_: Exception) {
                    getFallbackHoles(cId)
                }

                activePlayers = try {
                    val p = roundRepo.getRoundPlayers(rId)
                    if (p.isNotEmpty()) p else listOf(RoundPlayer("p-1", rId, null, null, "Tôi (Golfer)", 1))
                } catch (_: Exception) {
                    listOf(RoundPlayer("p-1", rId, null, null, "Tôi (Golfer)", 1))
                }

                userClubs = try {
                    val uid = authRepo.currentUserId
                    if (uid != null) shotRepo.getUserClubs(uid) else getFallbackClubs()
                } catch (_: Exception) {
                    getFallbackClubs()
                }
            }

            GpsRangefinderScreen(
                courseName = "Pine Valley Championship Golf Club",
                holes = activeHoles,
                userClubs = userClubs,
                onNavigateToScoreEntry = { holeNum ->
                    navController.navigate("score_entry/$holeNum")
                },
                onNavigateToScorecard = { navController.navigate("scorecard") },
                onOpenShotTracker = { holeId, lat, lng ->
                    navController.navigate("shot_tracker/$holeId/$lat/$lng")
                },
                onNavigateToLivePlay = { navController.navigate("liveplay") },
                onBack = { navController.popBackStack() }
            )
        }

        composable("score_entry/{holeNumber}") { backStackEntry ->
            val holeNum = backStackEntry.arguments?.getString("holeNumber")?.toIntOrNull() ?: 1
            val rId = activeRoundId ?: "demo-round"

            ScoreEntryScreen(
                roundId = rId,
                holeNumber = holeNum,
                holes = activeHoles,
                players = activePlayers,
                onFinishHole = { navController.popBackStack() },
                onBack = { navController.popBackStack() }
            )
        }

        composable("scorecard") {
            val rId = activeRoundId ?: "demo-round"
            ScorecardScreen(
                roundId = rId,
                holes = activeHoles,
                players = activePlayers,
                onBack = { navController.popBackStack() }
            )
        }

        composable("shot_tracker/{holeId}/{lat}/{lng}") { backStackEntry ->
            val holeId = backStackEntry.arguments?.getString("holeId") ?: "h-1"
            val lat = backStackEntry.arguments?.getString("lat")?.toDoubleOrNull() ?: 21.0285
            val lng = backStackEntry.arguments?.getString("lng")?.toDoubleOrNull() ?: 105.8542
            val rId = activeRoundId ?: "demo-round"
            val pId = activePlayers.firstOrNull()?.id ?: "p-1"

            ShotTrackerScreen(
                roundId = rId,
                playerId = pId,
                userId = authRepo.currentUserId,
                holeId = holeId,
                currentLat = lat,
                currentLng = lng,
                userClubs = userClubs,
                onBack = { navController.popBackStack() }
            )
        }

        composable("liveplay") {
            val rId = activeRoundId ?: "demo-round"
            LivePlayLeaderboardScreen(
                roundId = rId,
                players = activePlayers,
                onBack = { navController.popBackStack() }
            )
        }

        composable("stats") {
            StatsDashboardScreen(onBack = { navController.popBackStack() })
        }
    }
}

// Fallback demo data if offline or before loading from Supabase
private fun getFallbackHoles(courseId: String): List<Hole> {
    return (1..9).map { num ->
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
}

private fun getFallbackClubs(): List<GolfBagClub> {
    return listOf(
        GolfBagClub("c-1", "user-1", "DRIVER", "Driver 10.5°", 215.0),
        GolfBagClub("c-2", "user-1", "WOOD_3", "3-Wood 15°", 195.0),
        GolfBagClub("c-3", "user-1", "HYBRID_4", "4-Hybrid 22°", 175.0),
        GolfBagClub("c-4", "user-1", "IRON_7", "7 Iron", 145.0),
        GolfBagClub("c-5", "user-1", "PITCHING_WEDGE", "PW 46°", 115.0),
        GolfBagClub("c-6", "user-1", "SAND_WEDGE", "SW 54°", 85.0),
        GolfBagClub("c-7", "user-1", "PUTTER", "Blade Putter", 0.0)
    )
}
