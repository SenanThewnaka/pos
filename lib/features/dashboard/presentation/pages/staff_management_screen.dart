import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/auth_dao.dart';
import '../../../../core/logic/firebase_service.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/logic/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class StaffManagementScreen extends StatefulWidget {
  final AppDatabase db;
  final SyncService syncService;

  const StaffManagementScreen({Key? key, required this.db, required this.syncService}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await widget.db.authDao.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String role = 'CASHIER';
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text("ADD NEW OFFICER", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl, 
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Username", labelStyle: TextStyle(color: Colors.grey))
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pinCtrl, 
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Password", labelStyle: TextStyle(color: Colors.grey)), 
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: role,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardColor,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: "CASHIER", child: Text("Cashier")),
                      DropdownMenuItem(value: "MANAGER", child: Text("Manager")),
                    ],
                    onChanged: (v) => setDialogState(() => role = v!),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                  onPressed: isDialogLoading ? null : () async {
                    if (nameCtrl.text.isEmpty || pinCtrl.text.length < 6) {
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 chars")));
                       return;
                    }
                    
                    setDialogState(() => isDialogLoading = true);
                    
                    try {
                      final storeId = widget.syncService.storeId;
                      if (storeId == null) throw "Store ID not found. Try restarting app.";

                      final auth = AuthService(widget.db);
                      final hash = auth.hashPin(pinCtrl.text.trim());

                      // 1. Create in Cloud (Send Hash as 'pin')
                      await FirebaseService().createCloudUser(
                        storeId: storeId,
                        name: nameCtrl.text.trim(),
                        pin: hash, 
                        role: role
                      );
                      
                      // 2. Sync Down
                      await widget.syncService.syncUsers();

                      if (mounted) {
                        Navigator.pop(context); // Close dialog
                        _loadUsers(); // Refresh list
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Staff Added Successfully")));
                      }
                    } catch (e) {
                      setDialogState(() => isDialogLoading = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: isDialogLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("AUTHORIZE"),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("PERSONNEL DATABASE", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        onPressed: _showAddStaffDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = _users[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'OWNER' ? Colors.purple.withOpacity(0.2) : AppTheme.accentColor.withOpacity(0.2),
                    child: Icon(
                      user.role == 'OWNER' ? Icons.security : Icons.badge_outlined, 
                      color: user.role == 'OWNER' ? Colors.purple[300] : AppTheme.accentColor
                    ),
                  ),
                  title: Text(user.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Role: ${user.role}", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: user.role == "OWNER" 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text("COMMANDER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple[300])),
                        ) 
                      : IconButton(
                          icon: Icon(Icons.delete_outline, color: AppTheme.dangerColor.withOpacity(0.8)), 
                          onPressed: () {
                          // TODO: Implement Delete
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deletion not implemented yet")));
                        }),
                ),
              );
            },
        ),
    );
  }
}
