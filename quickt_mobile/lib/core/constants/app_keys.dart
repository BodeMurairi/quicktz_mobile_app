import 'package:flutter/material.dart';

/// Global key for the ShellRoute scaffold.
/// Use [appShellKey.currentState?.openDrawer()] from any shell-child screen
/// to slide out the app-wide navigation drawer.
final appShellKey = GlobalKey<ScaffoldState>();

/// Global key so background pollers (e.g. new-message watcher) can show a
/// SnackBar from anywhere, regardless of which screen is currently active.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
