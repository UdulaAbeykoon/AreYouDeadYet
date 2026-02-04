import 'package:death_app/providers/check_in_provider.dart';
import 'package:death_app/screens/settings_screen.dart';
import 'package:death_app/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsAuthWrapper extends StatelessWidget {
  const SettingsAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to see if we are authenticated (Real or Manual)
    final provider = context.watch<CheckInProvider>();
    
    if (provider.isAuthenticated) {
      return const SettingsScreen();
    } else {
      return const SignUpScreen();
    }
  }
}
