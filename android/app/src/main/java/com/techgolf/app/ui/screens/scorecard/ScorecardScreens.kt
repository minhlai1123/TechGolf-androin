package com.techgolf.app.ui.screens.scorecard

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import com.techgolf.app.data.models.Hole
import com.techgolf.app.data.models.RoundPlayer
import com.techgolf.app.data.models.RoundScore
import com.techgolf.app.data.repository.RoundRepository
import com.techgolf.app.domain.GameModeEngine
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RoundSetupScreen(
    courseId: String,
    currentUserId: String,
    onStartRound: (roundId: String) -> Unit,
    onBack: () -> Unit
) {
    val roundRepo = remember { RoundRepository() }
    val scope = rememberCoroutineScope()

    var selectedMode by remember { mutableStateOf(GameModeEngine.Mode.STROKE_PLAY) }
    var players by remember { mutableStateOf(listOf("Tôi (Golfer)", "Golfer 2")) }
    var newPlayerName by remember { mutableStateOf("") }
    var isStarting by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Thiết lập Vòng Đấu", fontWeight = FontWeight.Bold) },
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
                .padding(20.dp)
        ) {
            Text("1. Chọn Chế độ chơi", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(10.dp))

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                GameModeEngine.Mode.values().forEach { mode ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                if (selectedMode == mode) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                                RoundedCornerShape(10.dp)
                            )
                            .clickable { selectedMode = mode }
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selectedMode == mode,
                            onClick = { selectedMode = mode }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(mode.displayName, fontWeight = FontWeight.SemiBold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
            Text("2. Người chơi trong Flight (${players.size}/4)", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(10.dp))

            players.forEachIndexed { index, name ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("${index + 1}. $name", fontSize = 15.sp)
                    if (index > 0) {
                        IconButton(onClick = {
                            players = players.filterIndexed { i, _ -> i != index }
                        }) {
                            Icon(Icons.Default.Delete, contentDescription = "Remove", tint = Color.Red)
                        }
                    }
                }
            }

            if (players.size < 4) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = newPlayerName,
                        onValueChange = { newPlayerName = it },
                        label = { Text("Tên người chơi mới") },
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(onClick = {
                        if (newPlayerName.isNotBlank()) {
                            players = players + newPlayerName.trim()
                            newPlayerName = ""
                        }
                    }) {
                        Text("Thêm")
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Button(
                onClick = {
                    isStarting = true
                    scope.launch {
                        val result = roundRepo.createRound(
                            courseId = courseId,
                            gameMode = selectedMode.code,
                            playerNames = players,
                            creatorId = currentUserId
                        )
                        isStarting = false
                        result.onSuccess { r -> onStartRound(r.id) }
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
                    Text("Bắt đầu Vòng đấu", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScoreEntryScreen(
    roundId: String,
    holeNumber: Int,
    holes: List<Hole>,
    players: List<RoundPlayer>,
    onFinishHole: () -> Unit,
    onBack: () -> Unit
) {
    val roundRepo = remember { RoundRepository() }
    val scope = rememberCoroutineScope()

    var selectedPlayerIndex by remember { mutableIntStateOf(0) }
    val currentHole = holes.firstOrNull { it.holeNumber == holeNumber } ?: return
    val currentPlayer = players.getOrNull(selectedPlayerIndex) ?: return

    var grossScore by remember { mutableIntStateOf(currentHole.par) }
    var putts by remember { mutableIntStateOf(2) }
    var penalties by remember { mutableIntStateOf(0) }
    var fairwayHit by remember { mutableStateOf<String?>("STRAIGHT") }
    var gir by remember { mutableStateOf<Boolean?>(true) }
    var isSaving by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ghi điểm • Hố $holeNumber (Par ${currentHole.par})") },
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
                .padding(20.dp)
        ) {
            // Player Tabs
            if (players.size > 1) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    players.forEachIndexed { idx, p ->
                        FilterChip(
                            selected = selectedPlayerIndex == idx,
                            onClick = { selectedPlayerIndex = idx },
                            label = { Text(p.playerName) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Gross Score Stepper
            ScoreStepper(
                label = "Gross Score",
                value = grossScore,
                onValueChange = { grossScore = maxOf(1, it) }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Putts Stepper
            ScoreStepper(
                label = "Putts",
                value = putts,
                onValueChange = { putts = it.coerceIn(0, grossScore) }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Penalties Stepper
            ScoreStepper(
                label = "Penalties",
                value = penalties,
                onValueChange = { penalties = maxOf(0, it) }
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Fairway Hit
            Text("Fairway Hit (FIR):", fontWeight = FontWeight.Bold, fontSize = 14.sp)
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("LEFT" to "Trái", "STRAIGHT" to "Trúng", "RIGHT" to "Phải").forEach { (code, lbl) ->
                    OutlinedButton(
                        onClick = { fairwayHit = if (fairwayHit == code) null else code },
                        colors = ButtonDefaults.outlinedButtonColors(
                            containerColor = if (fairwayHit == code) MaterialTheme.colorScheme.primaryContainer else Color.Transparent
                        ),
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(lbl)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // GIR Toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Greens in Regulation (GIR)", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                Switch(
                    checked = gir == true,
                    onCheckedChange = { gir = it }
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            Button(
                onClick = {
                    isSaving = true
                    scope.launch {
                        roundRepo.saveScore(
                            roundId = roundId,
                            playerId = currentPlayer.id,
                            holeId = currentHole.id,
                            gross = grossScore,
                            putts = putts,
                            penalties = penalties,
                            fairwayHit = fairwayHit,
                            gir = gir
                        )
                        isSaving = false
                        onFinishHole()
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
                    Text("Lưu điểm Hố $holeNumber", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun ScoreStepper(
    label: String,
    value: Int,
    onValueChange: (Int) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(label, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { onValueChange(value - 1) }) {
                    Icon(Icons.Default.Remove, contentDescription = "Minus")
                }
                Text(
                    text = "$value",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 12.dp)
                )
                IconButton(onClick = { onValueChange(value + 1) }) {
                    Icon(Icons.Default.Add, contentDescription = "Plus")
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScorecardScreen(
    roundId: String,
    holes: List<Hole>,
    players: List<RoundPlayer>,
    onBack: () -> Unit
) {
    val roundRepo = remember { RoundRepository() }
    var scores by remember { mutableStateOf<List<RoundScore>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(roundId) {
        isLoading = true
        scores = try {
            roundRepo.getRoundScores(roundId)
        } catch (_: Exception) {
            emptyList()
        }
        isLoading = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Bảng Điểm Scorecard", fontWeight = FontWeight.Bold) },
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
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(12.dp)
            ) {
                item {
                    // Header Row
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFF1B5E20), RoundedCornerShape(8.dp))
                            .padding(10.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("HỐ", color = Color.White, fontWeight = FontWeight.Bold, modifier = Modifier.width(36.dp))
                        Text("PAR", color = Color.White, fontWeight = FontWeight.Bold, modifier = Modifier.width(36.dp))
                        players.forEach { p ->
                            Text(p.playerName.take(8), color = Color.White, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                        }
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                }

                items(holes) { hole ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(if (hole.holeNumber % 2 == 0) Color(0xFF1E1E1E) else Color(0xFF2C2C2C))
                            .padding(10.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("${hole.holeNumber}", color = Color.White, fontWeight = FontWeight.Bold, modifier = Modifier.width(36.dp))
                        Text("${hole.par}", color = Color.LightGray, modifier = Modifier.width(36.dp))
                        players.forEach { p ->
                            val s = scores.firstOrNull { it.playerId == p.id && it.holeId == hole.id }
                            val gross = s?.grossScore
                            val diff = if (gross != null) gross - hole.par else null
                            val color = when {
                                diff == null -> Color.Gray
                                diff < 0 -> Color(0xFF81C784) // Birdie or better (green)
                                diff == 0 -> Color.White // Par
                                diff == 1 -> Color(0xFFFFB74D) // Bogey (orange)
                                else -> Color(0xFFE57373) // Double bogey or worse (red)
                            }
                            Text(
                                text = gross?.toString() ?: "-",
                                color = color,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }

                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    // Totals Row
                    val totalPar = holes.sumOf { it.par }
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF1B5E20))
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("TỔNG (Par $totalPar):", color = Color.White, fontWeight = FontWeight.Bold)
                            players.forEach { p ->
                                val totalGross = scores.filter { it.playerId == p.id }.sumOf { it.grossScore }
                                Text("${p.playerName}: $totalGross", color = Color.White, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }
}
