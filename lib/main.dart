import 'package:death_app/providers/check_in_provider.dart';
import 'package:death_app/screens/main_scaffold.dart';
import 'package:death_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
      ],
      child: MaterialApp(
        title: 'Are You Dead Yet?',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainScaffold(),
      ),
    );
  }
}
