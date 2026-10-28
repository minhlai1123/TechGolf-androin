package com.techgolf.app.core.supabase

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.storage.Storage

object SupabaseClientManager {
    private const val TAG = "SupabaseClientManager"
    private const val PREF_NAME = "techgolf_supabase_prefs"
    private const val KEY_URL = "supabase_url"
    private const val KEY_ANON_KEY = "supabase_anon_key"

    private var prefs: SharedPreferences? = null
    private var _client: SupabaseClient? = null

    val client: SupabaseClient?
        get() = _client

    val isConfigured: Boolean
        get() = _client != null && getSavedUrl() != SupabaseConfig.DEFAULT_SUPABASE_URL

    fun initialize(context: Context) {
        try {
            prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val url = prefs?.getString(KEY_URL, SupabaseConfig.DEFAULT_SUPABASE_URL) ?: SupabaseConfig.DEFAULT_SUPABASE_URL
            val anonKey = prefs?.getString(KEY_ANON_KEY, SupabaseConfig.DEFAULT_SUPABASE_ANON_KEY) ?: SupabaseConfig.DEFAULT_SUPABASE_ANON_KEY
            buildClient(url, anonKey)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing SupabaseClientManager: ${e.message}", e)
        }
    }

    fun updateCredentials(url: String, anonKey: String) {
        try {
            prefs?.edit()
                ?.putString(KEY_URL, url)
                ?.putString(KEY_ANON_KEY, anonKey)
                ?.apply()
            buildClient(url, anonKey)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating credentials: ${e.message}", e)
        }
    }

    fun getSavedUrl(): String = prefs?.getString(KEY_URL, SupabaseConfig.DEFAULT_SUPABASE_URL) ?: SupabaseConfig.DEFAULT_SUPABASE_URL
    fun getSavedAnonKey(): String = prefs?.getString(KEY_ANON_KEY, SupabaseConfig.DEFAULT_SUPABASE_ANON_KEY) ?: SupabaseConfig.DEFAULT_SUPABASE_ANON_KEY

    private fun buildClient(url: String, anonKey: String) {
        try {
            _client = createSupabaseClient(
                supabaseUrl = url,
                supabaseKey = anonKey
            ) {
                install(Auth)
                install(Postgrest)
                install(Realtime)
                install(Storage)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Supabase client: ${e.message}", e)
            _client = null
        }
    }
}
