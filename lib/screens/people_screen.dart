import 'package:death_app/models/contact.dart';
import 'package:death_app/providers/check_in_provider.dart';
import 'package:death_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  void _showAddPersonModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddPersonSheet(),
    );
  }

  void _showEditMessageDialog(BuildContext context, String currentMessage) {
    final controller = TextEditingController(text: currentMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Alert Message", style: AppTheme.headerStyle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter message...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CheckInProvider>().updateMessage(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text("Save", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();
    final contacts = provider.contacts;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PEOPLE", style: AppTheme.bigHeaderStyle),
                    Text("that rely on you", style: AppTheme.bodyStyle.copyWith(color: Colors.grey[700])),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _showAddPersonModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("ADD PERSON"),
                )
              ],
            ),
          ),
          
          Expanded(
            child: contacts.isEmpty 
              ? Center(child: Text("No contacts yet.", style: AppTheme.bodyStyle))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: contacts.length,
                  itemBuilder: (ctx, index) {
                    final contact = contacts[index];
                    return _ContactCard(contact: contact);
                  },
                ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("MESSAGE", style: AppTheme.headerStyle),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                      onPressed: () => _showEditMessageDialog(context, provider.message),
                      tooltip: "Edit Message",
                    )
                  ],
                ),
                const SizedBox(height: 5), // Reduced height slightly
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.message, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.message, // Use dynamic message
                          style: AppTheme.bodyStyle,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contact.relationship.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                Text(contact.name, style: AppTheme.headerStyle.copyWith(fontSize: 22)),
                Text(contact.email, style: AppTheme.bodyStyle.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("Nudged ${contact.name} to check in!")),
               );
            },
            icon: Image.asset(
              'assets/images/nudge_hand.png',
               width: 32,
               errorBuilder: (ctx, _, __) => const Icon(Icons.touch_app, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }
}

class AddPersonSheet extends StatefulWidget {
  const AddPersonSheet({super.key});

  @override
  State<AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<AddPersonSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();

  void _submit() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) return;

    final contact = Contact(
      id: DateTime.now().toString(),
      name: _nameController.text,
      email: _emailController.text,
      relationship: _relationshipController.text.isEmpty ? 'FRIEND' : _relationshipController.text,
    );

    context.read<CheckInProvider>().addContact(contact);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ADD PERSON", style: AppTheme.bigHeaderStyle),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "E-mail",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _relationshipController,
            decoration: const InputDecoration(
              labelText: "Relationship (e.g. FRIEND)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Add"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
