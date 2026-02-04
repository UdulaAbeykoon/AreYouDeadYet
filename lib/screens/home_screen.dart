import 'package:death_app/providers/check_in_provider.dart';
import 'package:death_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:async'; // Add import for Timer

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlert();
    });
    // Update UI every second/minute
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkAlert() {
    // ... existing alert logic ...
    final provider = context.read<CheckInProvider>();
    if (provider.isHighAlert) {
        // ... (keep existing dialog logic) ...
         showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.errorColor,
          title: Text("HIGH ALERT", style: AppTheme.headerStyle.copyWith(color: Colors.white)),
          content: const Text(
            "You have missed your check-in!\nEmergency emails are sending soon.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.checkIn(); // Checking in resolves it
              },
              style: TextButton.styleFrom(backgroundColor: Colors.white),
              child: const Text("I'M ALIVE!", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();
    final canCheckIn = provider.canCheckIn;
    final timeLeft = provider.timeUntilNextCheckIn;

    return SafeArea(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "ARE YOU\nDEAD YET?",
                textAlign: TextAlign.center,
                style: AppTheme.bigHeaderStyle.copyWith(fontSize: 56, height: 0.9),
              ),
            ),
            
            const Spacer(),
            
            GestureDetector(
              onTap: canCheckIn 
                  ? () => context.read<CheckInProvider>().checkIn()
                  : null,
              child: Opacity(
                opacity: canCheckIn ? 1.0 : 0.5,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: canCheckIn ? AppTheme.primaryColor : Colors.grey,
                    borderRadius: BorderRadius.circular(200),
                    boxShadow: [
                      BoxShadow(
                        color: (canCheckIn ? AppTheme.primaryColor : Colors.grey).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/ghost_heart.png',
                      width: 120,
                      errorBuilder: (ctx, _, __) => const Icon(Icons.favorite, size: 100, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (!canCheckIn)
              Text(
                "NEXT CHECK-IN:\n${_formatDuration(timeLeft)}",
                textAlign: TextAlign.center,
                style: AppTheme.headerStyle.copyWith(color: Colors.grey),
              ),

             if (canCheckIn)
               const SizedBox(height: 48), // Spacing to match height

            const SizedBox(height: 20),
            
            Text(
              "${provider.daysAlive}",
              style: AppTheme.bigHeaderStyle.copyWith(fontSize: 80),
            ),
            Text(
              "DAYS ALIVE",
              style: AppTheme.headerStyle.copyWith(letterSpacing: 2),
            ),
            
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
