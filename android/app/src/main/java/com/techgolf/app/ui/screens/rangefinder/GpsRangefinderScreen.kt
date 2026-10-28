package com.techgolf.app.ui.screens.rangefinder

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
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
import com.techgolf.app.data.models.Hole
import com.techgolf.app.domain.ClubRecommendationEngine
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GpsRangefinderScreen(
    courseName: String,
    holes: List<Hole>,
    userClubs: List<GolfBagClub>,
    onNavigateToScoreEntry: (holeNumber: Int) -> Unit,
    onNavigateToScorecard: () -> Unit,
    onOpenShotTracker: (holeId: String, currentLat: Double, currentLng: Double) -> Unit,
    onNavigateToLivePlay: () -> Unit,
    onBack: () -> Unit
) {
    var currentHoleIndex by remember { mutableIntStateOf(0) }
    var useYards by remember { mutableStateOf(true) }
    var isPlaysLikeActive by remember { mutableStateOf(false) }

    // Simulated player GPS location near hole 1 tee of Pine Valley (or update from FusedLocation)
    var playerLat by remember { mutableDoubleStateOf(21.028500) }
    var playerLng by remember { mutableDoubleStateOf(105.854200) }

    if (holes.isEmpty()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212)),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(color = Color(0xFF4CAF50))
        }
        return
    }

    val currentHole = holes.getOrElse(currentHoleIndex) { holes.first() }

    // Calculate Geodesic distances to Green Front, Center, Back
    val distFrontMeters = if (currentHole.greenFrontLat != null && currentHole.greenFrontLng != null) {
        DistanceEngine.distanceBetweenMeters(playerLat, playerLng, currentHole.greenFrontLat, currentHole.greenFrontLng)
    } else 145.0

    val distCenterMeters = if (currentHole.greenCenterLat != null && currentHole.greenCenterLng != null) {
        DistanceEngine.distanceBetweenMeters(playerLat, playerLng, currentHole.greenCenterLat, currentHole.greenCenterLng)
    } else 160.0

    val distBackMeters = if (currentHole.greenBackLat != null && currentHole.greenBackLng != null) {
        DistanceEngine.distanceBetweenMeters(playerLat, playerLng, currentHole.greenBackLat, currentHole.greenBackLng)
    } else 175.0

    val unitMultiplier = if (useYards) 1.093613 else 1.0
    val unitLabel = if (useYards) "YDS" else "M"

    // Plays-Like calculation (+6 yards simulated uphill)
    val playsLikeDelta = if (isPlaysLikeActive) 6.0 else 0.0

    val dispFront = ((distFrontMeters * unitMultiplier) + playsLikeDelta).roundToInt()
    val dispCenter = ((distCenterMeters * unitMultiplier) + playsLikeDelta).roundToInt()
    val dispBack = ((distBackMeters * unitMultiplier) + playsLikeDelta).roundToInt()

    // Caddie Recommendation
    val recommendedClub = remember(dispCenter, userClubs) {
        ClubRecommendationEngine.recommendClub(dispCenter.toDouble(), userClubs)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(courseName, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        Text(
                            "Hố ${currentHole.holeNumber} • Par ${currentHole.par} • HCP ${currentHole.handicapIndex}",
                            fontSize = 12.sp,
                            color = Color.LightGray
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    // Unit switch
                    TextButton(onClick = { useYards = !useYards }) {
                        Text(if (useYards) "YDS" else "MTR", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                    // Plays-Like toggle
                    IconButton(onClick = { isPlaysLikeActive = !isPlaysLikeActive }) {
                        Icon(
                            Icons.Default.Terrain,
                            contentDescription = "Plays Like",
                            tint = if (isPlaysLikeActive) Color(0xFFFDD835) else Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1B5E20))
            )
        },
        bottomBar = {
            BottomAppBar(
                containerColor = Color(0xFF1E1E1E),
                contentPadding = PaddingValues(horizontal = 16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = {
                        onOpenShotTracker(currentHole.id, playerLat, playerLng)
                    }) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Default.TrackChanges, contentDescription = "Shot Tracker", tint = Color.White)
                            Text("Đo gậy", fontSize = 10.sp, color = Color.White)
                        }
                    }

                    IconButton(onClick = onNavigateToLivePlay) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Default.Leaderboard, contentDescription = "LivePlay", tint = Color(0xFFFDD835))
                            Text("LivePlay", fontSize = 10.sp, color = Color(0xFFFDD835))
                        }
                    }

                    Button(
                        onClick = { onNavigateToScoreEntry(currentHole.holeNumber) },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32)),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Nhập điểm", fontWeight = FontWeight.Bold)
                    }

                    IconButton(onClick = onNavigateToScorecard) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Default.TableChart, contentDescription = "Scorecard", tint = Color.White)
                            Text("Bảng điểm", fontSize = 10.sp, color = Color.White)
                        }
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(Color(0xFF121212))
        ) {
            // Hole Navigation Banner
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF1E1E1E))
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { if (currentHoleIndex > 0) currentHoleIndex-- },
                    enabled = currentHoleIndex > 0
                ) {
                    Icon(Icons.Default.ChevronLeft, contentDescription = "Hố trước", tint = Color.White)
                }

                Text(
                    text = "HỐ ${currentHole.holeNumber} OF ${holes.size}",
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = Color.White
                )

                IconButton(
                    onClick = { if (currentHoleIndex < holes.size - 1) currentHoleIndex++ },
                    enabled = currentHoleIndex < holes.size - 1
                ) {
                    Icon(Icons.Default.ChevronRight, contentDescription = "Hố sau", tint = Color.White)
                }
            }

            // F-M-B Distance Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1E1E))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    if (isPlaysLikeActive) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .background(Color(0xFF332900), RoundedCornerShape(8.dp))
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Icon(Icons.Default.Terrain, contentDescription = null, tint = Color(0xFFFDD835), modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("PLAYS LIKE ACTIVE (+6 yds độ dốc)", color = Color(0xFFFDD835), fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                    }

                    // Main Middle Pin Distance
                    Text(
                        text = "$dispCenter",
                        fontSize = 72.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White,
                        lineHeight = 72.sp
                    )
                    Text(
                        text = "CENTER GREEN ($unitLabel)",
                        fontSize = 13.sp,
                        color = Color(0xFF81C784),
                        fontWeight = FontWeight.SemiBold
                    )

                    Spacer(modifier = Modifier.height(20.dp))
                    HorizontalDivider(color = Color(0xFF2C2C2C))
                    Spacer(modifier = Modifier.height(16.dp))

                    // Front & Back Columns
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = "FRONT", fontSize = 12.sp, color = Color.Gray, fontWeight = FontWeight.Medium)
                            Text(text = "$dispFront $unitLabel", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        }

                        VerticalDivider(modifier = Modifier.height(36.dp), color = Color(0xFF2C2C2C))

                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = "BACK", fontSize = 12.sp, color = Color.Gray, fontWeight = FontWeight.Medium)
                            Text(text = "$dispBack $unitLabel", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        }
                    }
                }
            }

            // Caddie Recommendation Card
            if (recommendedClub != null) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF0D2818))
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.SportsGolf,
                            contentDescription = null,
                            tint = Color(0xFF81C784),
                            modifier = Modifier.size(28.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                "GỢI Ý GẬY CADDIE",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF81C784)
                            )
                            Text(
                                "${recommendedClub.customName ?: recommendedClub.clubType} • TB: ${(recommendedClub.averageDistanceYards).roundToInt()} yds",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Golf Map Arc Simulation Placeholder
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .padding(horizontal = 16.dp)
                    .background(Color(0xFF1E281E), RoundedCornerShape(16.dp)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Default.Map,
                        contentDescription = null,
                        tint = Color(0xFF4CAF50),
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "Bản đồ Vector & Cung khoảng cách 150/200/250y",
                        color = Color.LightGray,
                        fontSize = 13.sp
                    )
                    Text(
                        "Hố ${currentHole.holeNumber} • Green Center: (${currentHole.greenCenterLat ?: 21.03}, ${currentHole.greenCenterLng ?: 105.85})",
                        color = Color.Gray,
                        fontSize = 11.sp
                    )
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
