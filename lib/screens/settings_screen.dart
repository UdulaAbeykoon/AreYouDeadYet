import 'package:death_app/providers/check_in_provider.dart';
import 'package:death_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SETTINGS", style: AppTheme.bigHeaderStyle),
              Text("configurations",
                  style:
                      AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // I AM Section
              Text("I AM...",
                  style: AppTheme.headerStyle
                      .copyWith(fontSize: 20, color: Colors.grey[600])),
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.person,
                text: provider.userName.toUpperCase(),
              ),
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.email,
                text: provider.userEmail.toUpperCase(),
              ),
              const SizedBox(height: 25),

              // ALERTS Section
              Text("ALERTS",
                  style: AppTheme.headerStyle
                      .copyWith(fontSize: 20, color: Colors.grey[600])),
              const SizedBox(height: 10),
              _buildContainer(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text("ALERT AFTER MISSING FOR",
                          style: AppTheme.headerStyle.copyWith(fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.green),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: provider.alertThresholdDays,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                          style: AppTheme.headerStyle.copyWith(fontSize: 16),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text("1 DAYS")),
                            DropdownMenuItem(value: 2, child: Text("2 DAYS")),
                            DropdownMenuItem(value: 3, child: Text("3 DAYS")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              context.read<CheckInProvider>().setAlertThreshold(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // LANGUAGE Section
              Text("LANGUAGE",
                  style: AppTheme.headerStyle
                      .copyWith(fontSize: 20, color: Colors.grey[600])),
              const SizedBox(height: 10),
              _buildContainer(
                child: Row(
                  children: [
                    const Icon(Icons.translate, size: 30),
                    const SizedBox(width: 10),
                    Text("ENGLISH", style: AppTheme.headerStyle),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Debug button to simulate skipping days and send test emails
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sending emergency emails...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    final result = await provider.debugSimulateSkipDays();
                    
                    if (context.mounted) {
                      final success = result['success'] == true;
                      final message = result['message'] ?? 'Unknown status';
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'DEBUG: $message'
                                : 'ERROR: $message'
                          ),
                          duration: const Duration(seconds: 5),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "DEBUG: SIMULATE SKIP DAYS & SEND EMAILS", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.resetAllData();
                    // Optionally pop or show message
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App data has been reset.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("RESET APP DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return _buildContainer(
      child: Row(
        children: [
          Icon(icon, size: 35),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: AppTheme.headerStyle.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9), // Light Grey background from image
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }
}
