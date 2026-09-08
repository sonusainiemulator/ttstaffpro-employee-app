package com.ttstaffpro.faceattendance

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth needs a FragmentActivity to host BiometricPrompt — a plain
// FlutterActivity fails every authenticate() call (native lock never shows).
class MainActivity : FlutterFragmentActivity()
