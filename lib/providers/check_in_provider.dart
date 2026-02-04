import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/contact.dart';

class CheckInProvider with ChangeNotifier {
  static const String keyLastCheckIn = 'last_check_in';
  static const String keyStreakStart = 'streak_start';
  static const String keyAlertThreshold = 'alert_threshold';
  static const String keyContacts = 'contacts';
  static const String keyDaysAlive = 'days_alive_count';
  static const String keyMessage = 'user_message';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyIsManuallyAuthenticated = 'is_manually_authenticated';

  DateTime _lastCheckIn = DateTime.now();
  DateTime _streakStart = DateTime.now(); // Kept for internal logic if needed
  int _alertThresholdDays = 1;
  int _daysAlive = 0; // New counter
  String _message = "please come check on me."; // Default message
  List<Contact> _contacts = [];
  bool _isHighAlert = false;
  String _userName = "";
  String _userEmail = "";
  bool _isManuallyAuthenticated = false; // New flag for bypassing strict auth

  StreamSubscription<AuthState>? _authSubscription;

  CheckInProvider() {
    _loadData();
    _initSupabaseListener();
  }

  void _initSupabaseListener() {
    _updateUserFromSupabase(Supabase.instance.client.auth.currentUser);
    
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      // Only update from Supabase if we aren't manually authenticated (or if Supabase actually logs in)
      if (session != null) {
         _isManuallyAuthenticated = false; // Real auth takes precedence
         _updateUserFromSupabase(session.user);
      } else if (!_isManuallyAuthenticated) {
         _updateUserFromSupabase(null);
      }
    });
  }

  void _updateUserFromSupabase(User? user) {
    if (user != null) {
      _userEmail = user.email ?? "No Email";
      _userName = user.userMetadata?['name'] ?? "User";
    } else if (!_isManuallyAuthenticated) {
       // Only reset if we aren't manually logged in
      _userName = "";
      _userEmail = "";
    }
    notifyListeners();
  }
  
  // New method to force "login" state locally and persist it
  Future<void> loginManually(String name, String email) async {
    _userName = name;
    _userEmail = email;
    _isManuallyAuthenticated = true;
    
    // Save to SharedPreferences so it persists
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserName, name);
    await prefs.setString(keyUserEmail, email);
    await prefs.setBool(keyIsManuallyAuthenticated, true);
    
    notifyListeners();
  }

  // Check if user is effectively logged in (Real or Manual)
  bool get isAuthenticated => _isManuallyAuthenticated || Supabase.instance.client.auth.currentSession != null;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  DateTime get lastCheckIn => _lastCheckIn;
  int get alertThresholdDays => _alertThresholdDays;
  List<Contact> get contacts => _contacts;
  bool get isHighAlert => _isHighAlert;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get message => _message;

  int get daysAlive => _daysAlive;
  
  Future<void> updateMessage(String newMessage) async {
    _message = newMessage;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyMessage, _message);
    
    // Also save to Supabase database
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        await supabase.from('user_messages').upsert({
          'user_id': user.id,
          'message': newMessage,
        });
        print('✓ Message synced to database');
      }
    } catch (e) {
      print('⚠ Could not sync message to database: $e');
    }
    
    notifyListeners();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastCheckInStr = prefs.getString(keyLastCheckIn);
    if (lastCheckInStr != null) {
      _lastCheckIn = DateTime.parse(lastCheckInStr);
    } else {
      _lastCheckIn = DateTime.now();
      await prefs.setString(keyLastCheckIn, _lastCheckIn.toIso8601String());
    }

    _daysAlive = prefs.getInt(keyDaysAlive) ?? 0;
    _alertThresholdDays = prefs.getInt(keyAlertThreshold) ?? 1;
    _message = prefs.getString(keyMessage) ?? "please come check on me."; // Load saved message

    // Load saved user credentials
    _userName = prefs.getString(keyUserName) ?? "";
    _userEmail = prefs.getString(keyUserEmail) ?? "";
    _isManuallyAuthenticated = prefs.getBool(keyIsManuallyAuthenticated) ?? false;

    final contactsJson = prefs.getStringList(keyContacts);
    if (contactsJson != null) {
      _contacts = contactsJson
          .map((c) => Contact.fromJson(jsonDecode(c)))
          .toList();
    }
    
    _checkStatus();
    notifyListeners();
  }

  void _checkStatus() {
    final now = DateTime.now();
    final difference = now.difference(_lastCheckIn).inDays;
    
    if (difference >= _alertThresholdDays) {
      _isHighAlert = true;
      _triggerEmergencyProtocol();
    } else {
      _isHighAlert = false;
    }
    notifyListeners();
  }

  // ... inside CheckInProvider class ...

  // Helper to know if we are allowed to click (24h cooldown)
  bool get canCheckIn {
    if (_daysAlive == 0) return true; // Always allow first click
    final timeSinceLast = DateTime.now().difference(_lastCheckIn);
    return timeSinceLast.inHours >= 24;
  }

  Duration get timeUntilNextCheckIn {
    if (canCheckIn) return Duration.zero;
    final nextCheckInTime = _lastCheckIn.add(const Duration(hours: 24));
    return nextCheckInTime.difference(DateTime.now());
  }

  Future<void> checkIn() async {
    if (!canCheckIn) return; // Prevent early check-in

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Increment the counter
    _daysAlive++;
    await prefs.setInt(keyDaysAlive, _daysAlive);

    // Update time
    _lastCheckIn = now;
    _isHighAlert = false;
    await prefs.setString(keyLastCheckIn, _lastCheckIn.toIso8601String());
    notifyListeners();
  }

  Future<void> setAlertThreshold(int days) async {
    _alertThresholdDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyAlertThreshold, days);
    _checkStatus();
    notifyListeners();
  }

  Future<void> addContact(Contact contact) async {
    _contacts.add(contact);
    await _saveContacts();
    
    // Also save to Supabase database
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        await supabase.from('contacts').insert({
          'user_id': user.id,
          'contact_name': contact.name,
          'contact_email': contact.email,
          'relationship': contact.relationship,
        });
        print('✓ Contact synced to database: ${contact.name}');
      }
    } catch (e) {
      print('⚠ Could not sync contact to database: $e');
      // Continue anyway - contact is saved locally
    }
    
    notifyListeners();
  }

  Future<void> removeContact(String id) async {
    final contact = _contacts.firstWhere((c) => c.id == id);
    _contacts.removeWhere((c) => c.id == id);
    await _saveContacts();
    
    // Also remove from Supabase database
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        await supabase
            .from('contacts')
            .delete()
            .eq('user_id', user.id)
            .eq('contact_email', contact.email);
        print('✓ Contact removed from database: ${contact.name}');
      }
    } catch (e) {
      print('⚠ Could not remove contact from database: $e');
    }
    
    notifyListeners();
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = _contacts
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await prefs.setStringList(keyContacts, contactsJson);
  }

  void _triggerEmergencyProtocol() {
    print("SENDING EMERGENCY EMAILS TO ${_contacts.map((c) => c.email).join(', ')}");
    // Attempt to send emails (will fail gracefully if not authenticated/offline)
    _sendDebugEmails().then((result) {
      if (result['success'] == true) {
        print("✓ Emergency emails sent successfully.");
      } else {
        print("⚠ Failed to auto-send emergency emails: ${result['message']}");
      }
    });
  }

  // Debug/Test helper
  Future<void> debugSetLastCheckInPast(int daysAgo) async {
    _lastCheckIn = DateTime.now().subtract(Duration(days: daysAgo));
     final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLastCheckIn, _lastCheckIn.toIso8601String());
    _checkStatus();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _daysAlive = 0;
    _lastCheckIn = DateTime.now();
    _contacts = [];
    _userName = "";
    _userEmail = "";
    _isManuallyAuthenticated = false;
    // Sign out from supabase too if possible
    await Supabase.instance.client.auth.signOut();
    notifyListeners();
  }

  // Debug method to simulate skipping days and send test emails
  Future<Map<String, dynamic>> debugSimulateSkipDays() async {
    // Set last check-in to the past based on alert threshold
    _lastCheckIn = DateTime.now().subtract(Duration(days: _alertThresholdDays));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLastCheckIn, _lastCheckIn.toIso8601String());
    
    // Trigger high alert status
    _isHighAlert = true;
    
    // Send test emails to all contacts
    final result = await _sendDebugEmails();
    
    _checkStatus();
    notifyListeners();

    return result;
  }

  Future<Map<String, dynamic>> _sendDebugEmails() async {
    if (_contacts.isEmpty) {
      print("DEBUG: No contacts to send emails to");
      return {'success': false, 'message': 'No contacts to send emails to. Add contacts in the People tab.'};
    }

    if (_userEmail.isEmpty || _userName.isEmpty) {
      print("ERROR: User email or name not set. Please sign in first.");
      return {'success': false, 'message': 'User email or name not set. Please sign in first.'};
    }

    // Explicit check for manual authentication (Offline Mode)
    if (_isManuallyAuthenticated && Supabase.instance.client.auth.currentSession == null) {
       print("ERROR: Cannot send emails in Offline/Bypass Mode.");
       return {
         'success': false, 
         'message': 'Cannot send emails in Offline Mode. The email service requires a valid server session. Please Sign Out and Log In properly.'
       };
    }

    print("Sending test emails via Supabase Edge Function...");
    
    try {
      final supabase = Supabase.instance.client;
      
      // Get the current session token
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        print('✗ Not authenticated. Please sign in first.');
        return {'success': false, 'message': 'Not authenticated with server. Please sign in.'};
      }
      
      // Call the send-emergency-email Edge Function with proper auth
      final response = await supabase.functions.invoke(
        'send-emergency-email',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );
      
      if (response.status == 200) {
        final data = response.data;
        print('✓ ${data['message']}');
        print('  Emails sent: ${data['emailsSent']}/${data['totalContacts']}');
        
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          print('⚠ Some emails failed:');
          for (var error in data['errors']) {
            print('  - ${error['contact']}: ${error['error']}');
          }
           return {
            'success': true, 
             'message': 'Sent ${data['emailsSent']} email(s). Some failed.',
             'details': data
           };
        }
        
        return {
          'success': true, 
          'message': 'Successfully sent emergency emails to ${data['emailsSent']} contact(s).'
        };

      } else {
        print('✗ Failed to send emails: ${response.data}');
         final errorMsg = response.data.toString();
         if (errorMsg.contains("resend") && errorMsg.contains("domain")) {
            return {
              'success': false, 
              'message': 'Resend Error: Test domain restricted. You can ONLY email yourself. Verify domain at resend.com to email others.'
            };
         }
         return {'success': false, 'message': 'Server error: $errorMsg'};
      }
    } catch (e) {
      print('✗ Error calling Edge Function: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
