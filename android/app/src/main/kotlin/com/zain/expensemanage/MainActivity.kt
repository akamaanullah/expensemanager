package com.zain.expensemanage

import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    // FlutterFragmentActivity extends FragmentActivity
    // This is required for local_auth package to work properly
    // Using FlutterFragmentActivity instead of FlutterActivity resolves the biometric issue
}

