package com.techgolf.app

import android.app.Application
import com.techgolf.app.core.supabase.SupabaseClientManager

class TechGolfApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SupabaseClientManager.initialize(this)
    }
}
