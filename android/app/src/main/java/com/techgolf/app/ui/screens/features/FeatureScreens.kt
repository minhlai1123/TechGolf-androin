package com.techgolf.app.ui.screens.features

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.techgolf.app.core.geo.DistanceEngine
import com.techgolf.app.data.models.GolfBagClub
import com.techgolf.app.data.models.RoundPlayer
import com.techgolf.app.data.models.RoundScore
import com.techgolf.app.data.models.Shot
import com.techgolf.app.data.repository.RoundRepository
import com.techgolf.app.data.repository.ShotRepository
import com.techgolf.app.domain.WhsHandicapEngine
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShotTrackerScreen(
    roundId: String,
    playerId: String,
    userId: String?,
    holeId: String,
    currentLat: Double,
    currentLng: Double,
    userClubs: List<GolfBagClub>,
    onBack: () -> Unit
) {
    val shotRepo = remember { ShotRepository() }
    val scope = rememberCoroutineScope()

    var activeShot by remember { mutableStateOf<Shot?>(null) }
    var selectedClub by remember { mutableStateOf<GolfBagClub?>(userClubs.firstOrNull()) }
    var isStarting by remember { mutableStateOf(false) }
    var isSaving by remember { mutableStateOf(false) }

    // Simulated walking: player moves 210 yards ahead
    var currentBallLat by remember { mutableDoubleStateOf(currentLat + 0.0018) }
    var currentBallLng by remember { mutableDoubleStateOf(currentLng + 0.0012) }

    val liveDistanceYards = remember(activeShot, currentBallLat, currentBallLng) {
        if (activeShot != null) {
            DistanceEngine.distanceBetweenYards(
                activeShot!!.startLatitude, activeShot!!.startLongitude,
                currentBallLat, currentBallLng
            ).roundToInt()
        } else 0
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Đo Cú Đánh (Shot Tracker)", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                    navigationIconContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (activeShot == null) {
                // Step 1: Start Shot
                Text("Bắt đầu ghi nhận cú đánh", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                Text(
                    "Đứng tại vị trí phát bóng hoặc vị trí bóng nằm hiện tại",
                    fontSize = 13.sp,
                    color = Color.Gray
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Select Club
                Text("Chọn gậy chuẩn bị đánh:", fontWeight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.Start))
                Spacer(modifier = Modifier.height(8.dp))

                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(userClubs) { club ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = if (selectedClub?.id == club.id) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
                            ),
                            onClick = { selectedClub = club }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(club.customName ?: club.clubType, fontWeight = FontWeight.Bold)
                                Text("TB: ${club.averageDistanceYards.roundToInt()} yds", color = Color.Gray)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        isStarting = true
                        scope.launch {
                            val res = shotRepo.startShot(
                                roundId = roundId,
                                playerId = playerId,
                                userId = userId,
                                holeId = holeId,
                                clubId = selectedClub?.id,
                                lat = currentLat,
                                lng = currentLng,
                                elevation = 12.0
                            )
                            isStarting = false
                            res.onSuccess { s -> activeShot = s }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(12.dp),
                    enabled = !isStarting
                ) {
                    if (isStarting) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                    } else {
                        Text("BẮT ĐẦU CÚ ĐÁNH TẠI ĐÂY", fontWeight = FontWeight.Bold)
                    }
                }
            } else {
                // Step 2: In-Flight Shot Tracking
                Spacer(modifier = Modifier.height(20.dp))
                Icon(
                    Icons.Default.DirectionsWalk,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(64.dp)
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text("Di chuyển tới vị trí bóng dừng...", fontSize = 16.sp, color = Color.Gray)

                Spacer(modifier = Modifier.height(24.dp))

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("KHOẢNG CÁCH CÚ ĐÁNH", fontSize = 13.sp, color = Color.Gray, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("$liveDistanceYards YDS", fontSize = 54.sp, fontWeight = FontWeight.ExtraBold, color = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text("Gậy: ${selectedClub?.customName ?: selectedClub?.clubType}", fontSize = 14.sp, color = Color.White)
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                Button(
                    onClick = {
                        isSaving = true
                        scope.launch {
                            shotRepo.saveShot(
                                shotId = activeShot!!.id,
                                endLat = currentBallLat,
                                endLng = currentBallLng,
                                endElevation = 14.0,
                                clubId = selectedClub?.id
                            )
                            isSaving = false
                            onBack()
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(12.dp),
                    enabled = !isSaving
                ) {
                    if (isSaving) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                    } else {
                        Text("LƯU CÚ ĐÁNH NÀY ($liveDistanceYards yds)", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LivePlayLeaderboardScreen(
    roundId: String,
    players: List<RoundPlayer>,
    onBack: () -> Unit
) {
    val roundRepo = remember { RoundRepository() }
    var scores by remember { mutableStateOf<List<RoundScore>>(emptyList()) }
    var isLiveConnected by remember { mutableStateOf(true) }

    LaunchedEffect(roundId) {
        // Initial fetch
        scores = try {
            roundRepo.getRoundScores(roundId)
        } catch (_: Exception) {
            emptyList()
        }

        // Supabase Realtime Subscription for LivePlay
        try {
            roundRepo.subscribeToRoundScores(roundId).collect { updatedScore ->
                scores = scores.filterNot {
                    it.playerId == updatedScore.playerId && it.holeId == updatedScore.holeId
                } + updatedScore
            }
        } catch (_: Exception) {
            isLiveConnected = false
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("LivePlay Leaderboard", fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .background(if (isLiveConnected) Color.Green else Color.Red, RoundedCornerShape(5.dp))
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                    navigationIconContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            Text(
                "Đồng bộ trực tiếp qua Supabase Realtime",
                fontSize = 13.sp,
                color = Color.Gray,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            // Ranked Players List
            val ranked = players.map { p ->
                val pScores = scores.filter { it.playerId == p.id }
                val totalGross = pScores.sumOf { it.grossScore }
                val completed = pScores.size
                Triple(p, totalGross, completed)
            }.sortedBy { it.second }

            LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(ranked) { (player, totalGross, completed) ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.SportsGolf, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(player.playerName, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                    Text("Đã chơi $completed hố", fontSize = 12.sp, color = Color.Gray)
                                }
                            }
                            Text(
                                if (totalGross > 0) "$totalGross Gross" else "-",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatsDashboardScreen(onBack: () -> Unit) {
    // Demo Differentials to calculate official WHS Handicap Index
    val demoDifferentials = listOf(8.2, 9.4, 7.8, 11.2, 10.0, 8.5, 9.1, 7.5, 12.0, 8.9)
    val calculatedIndex = remember { WhsHandicapEngine.calculateHandicapIndex(demoDifferentials) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Golf Stats & WHS Handicap", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                    navigationIconContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            // WHS Handicap Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1B5E20))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("WHS HANDICAP INDEX", color = Color(0xFF81C784), fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("$calculatedIndex", color = Color.White, fontSize = 56.sp, fontWeight = FontWeight.ExtraBold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Tính từ 8 vòng tốt nhất trong 20 vòng gần nhất", color = Color.LightGray, fontSize = 12.sp)
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
            Text("Chỉ số hiệu suất thi đấu (Stats)", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(12.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                StatCard(title = "Fairways Hit (FIR)", value = "64.2%", modifier = Modifier.weight(1f))
                StatCard(title = "Greens in Reg (GIR)", value = "55.0%", modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                StatCard(title = "Putts / Hole", value = "1.8", modifier = Modifier.weight(1f))
                StatCard(title = "Scrambling", value = "42.0%", modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
fun StatCard(title: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, fontSize = 12.sp, color = Color.Gray)
            Spacer(modifier = Modifier.height(6.dp))
            Text(value, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
        }
    }
}
