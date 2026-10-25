package com.techgolf.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.techgolf.app.ui.navigation.AppNavigation
import com.techgolf.app.ui.theme.TechGolfTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TechGolfTheme {
                AppNavigation()
            }
        }
    }
}
