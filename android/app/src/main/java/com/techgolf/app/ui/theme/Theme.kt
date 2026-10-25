package com.techgolf.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val GolfGreenPrimary = Color(0xFF1B5E20)
val GolfGreenLight = Color(0xFF4CAF50)
val GolfGreenDark = Color(0xFF003300)
val GolfAccentGold = Color(0xFFFDD835)
val GolfBunkerYellow = Color(0xFFFFF59D)
val GolfWaterBlue = Color(0xFF0288D1)

val DarkBackground = Color(0xFF121212)
val DarkSurface = Color(0xFF1E1E1E)
val DarkSurfaceVariant = Color(0xFF2C2C2C)

private val DarkColorScheme = darkColorScheme(
    primary = GolfGreenLight,
    onPrimary = Color.Black,
    primaryContainer = GolfGreenDark,
    onPrimaryContainer = Color.White,
    secondary = GolfAccentGold,
    onSecondary = Color.Black,
    background = DarkBackground,
    surface = DarkSurface,
    surfaceVariant = DarkSurfaceVariant,
    onBackground = Color.White,
    onSurface = Color.White
)

private val LightColorScheme = lightColorScheme(
    primary = GolfGreenPrimary,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFC8E6C9),
    onPrimaryContainer = GolfGreenDark,
    secondary = Color(0xFFF57F17),
    onSecondary = Color.White,
    background = Color(0xFFF9FBE7),
    surface = Color.White,
    onBackground = Color(0xFF1B1B1B),
    onSurface = Color(0xFF1B1B1B)
)

@Composable
fun TechGolfTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(),
        content = content
    )
}
