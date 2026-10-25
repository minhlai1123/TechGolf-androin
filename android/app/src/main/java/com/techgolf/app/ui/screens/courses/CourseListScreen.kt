package com.techgolf.app.ui.screens.courses

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GolfCourse
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.techgolf.app.data.models.Course
import com.techgolf.app.data.repository.CourseRepository

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CourseListScreen(
    onSelectCourseForRound: (courseId: String) -> Unit,
    onNavigateToStats: () -> Unit
) {
    val courseRepo = remember { CourseRepository() }
    var courses by remember { mutableStateOf<List<Course>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var searchQuery by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        isLoading = true
        courses = try {
            courseRepo.getCourses()
        } catch (_: Exception) {
            emptyList()
        }
        isLoading = false
    }

    val filtered = courses.filter {
        it.name.contains(searchQuery, ignoreCase = true) ||
        it.city.contains(searchQuery, ignoreCase = true)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Danh sách Sân Golf", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                ),
                actions = {
                    TextButton(onClick = onNavigateToStats) {
                        Text("Stats/WHS", color = Color.White)
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                label = { Text("Tìm kiếm sân hoặc thành phố...") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (filtered.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Không tìm thấy sân golf nào", color = Color.Gray)
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(filtered) { course ->
                        CourseCard(
                            course = course,
                            onPlayClick = { onSelectCourseForRound(course.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun CourseCard(
    course: Course,
    onPlayClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onPlayClick() },
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.GolfCourse,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(40.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = course.name,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.LocationOn,
                        contentDescription = null,
                        tint = Color.Gray,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${course.city}, ${course.country} • ${course.totalHoles} hố",
                        fontSize = 13.sp,
                        color = Color.Gray
                    )
                }
            }

            IconButton(onClick = onPlayClick) {
                Icon(
                    Icons.Default.PlayArrow,
                    contentDescription = "Chơi",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}
