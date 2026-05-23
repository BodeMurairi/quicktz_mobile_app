import 'package:flutter/material.dart';

/// Global key for the ShellRoute scaffold.
/// Use [appShellKey.currentState?.openDrawer()] from any shell-child screen
/// to slide out the app-wide navigation drawer.
final appShellKey = GlobalKey<ScaffoldState>();
