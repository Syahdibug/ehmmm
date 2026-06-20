import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── COLOR SCHEME (sama persis dengan DashboardPage) ─────────────────────────
class _C {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const gold = Color(0xFFFFD447);
  static const danger = Color(0xFFFF4D6D);
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const greenG1 = Color(0xFF25D366);
  static const greenG2 = Color(0xFF18a84c);
  static const blueG1 = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const roleVip = Color(0xFFFFD700);
  static const roleReseller = Color(0xFF229ED9);
  static const roleOwner = Color(0xFF9C27B0);
  static const roleFounder = Color(0xFFE91E63);
  static const roleHighAdmin = Color(0xFFFF5722);
  static const roleModerator = Color(0xFF00BCD4);
  static const roleMember = Color(0xFF4CAF50);
}

// ── ADMIN PAGE ───────────────────────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // --- State Variables ---
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = [
    'vip',
    'reseller',
    'owner',
    'high admin',
    'moderator',
    'member',
    'founder',
  ];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 50;
  bool isLoading = false;

  // --- Controllers ---
  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> _fetchUsers() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/user/listUsers?key=$sessionKey',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _showSnackBar(
          data['message'] ?? 'Tidak diizinkan melihat daftar user.',
          isError: true,
        );
      }
    } catch (_) {
      _showSnackBar("Gagal memuat user list.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    if (filteredList.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser(String username) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/user/deleteUser?key=$sessionKey&username=$username',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showSnackBar("User '${data['user']['username']}' telah dihapus.");
        _fetchUsers();
      } else {
        _showSnackBar(
          data['message'] ?? 'Gagal menghapus user.',
          isError: true,
        );
      }
    } catch (_) {
      _showSnackBar("Tidak dapat menghubungi server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showSnackBar("Semua field wajib diisi.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    Navigator.pop(context);
    try {
      final url = Uri.parse(
        'http://104.207.64.203:2001/api/user/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showSnackBar("Akun '${data['user']['username']}' berhasil dibuat.");
        _fetchUsers();
      } else {
        _showSnackBar(data['message'] ?? 'Gagal membuat akun.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Gagal menghubungi server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: _C.text, fontSize: 13)),
        backgroundColor: _C.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? _C.danger.withOpacity(0.4)
                : _C.accent.withOpacity(0.4),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'vip':
        return _C.roleVip;
      case 'reseller':
        return _C.roleReseller;
      case 'moderator':
        return _C.roleModerator;
      case 'high admin':
        return _C.roleHighAdmin;
      case 'owner':
        return _C.roleOwner;
      case 'founder':
        return _C.roleFounder;
      default:
        return _C.roleMember;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg2,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.accent.withOpacity(0.25)),
              ),
              child: Icon(
                FontAwesomeIcons.userShield,
                color: _C.accent,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN PANEL',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                Text(
                  'User Management',
                  style: TextStyle(fontSize: 10, color: _C.muted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _fetchUsers,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border2),
                ),
                child: Icon(Icons.refresh, color: _C.muted, size: 16),
              ),
            ),
          ),
        ],
        iconTheme: IconThemeData(color: _C.text),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: isLoading && fullUserList.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _C.accent,
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 16),
                _buildActionCards(),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 16),
                Expanded(child: _buildUserTable()),
              ],
            ),
    );
  }

  // ── Action Cards ──────────────────────────────────────────────────────────
  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              'CREATE USER',
              _C.greenG1,
              _C.greenG2,
              FontAwesomeIcons.userPlus,
              () => _showCreateUserDialog(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              'DELETE USER',
              _C.danger,
              const Color(0xFFcc2244),
              FontAwesomeIcons.userMinus,
              () => _showDeleteUserDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    String label,
    Color g1,
    Color g2,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [g1, g2]),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: -10,
              child: Icon(icon, size: 60, color: Colors.white.withOpacity(0.1)),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: roleOptions.map((role) {
          final isSelected = selectedRole == role;
          final chipColor = _getRoleColor(role);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                selectedRole = role;
                _filterAndPaginate();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? chipColor.withOpacity(0.15) : _C.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? chipColor.withOpacity(0.5) : _C.border2,
                    width: 1,
                  ),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? chipColor : _C.muted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 10,
                    fontFamily: 'MADEEvolveSansEVO',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── User Table ────────────────────────────────────────────────────────────
  Widget _buildUserTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.users, color: _C.accent, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'USER LIST (${filteredList.length})',
                    style: TextStyle(
                      color: _C.text,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MADEEvolveSansEVO',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // List
            _buildCompactListView(),
            // Pagination
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactListView() {
    if (filteredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_off, color: _C.muted2, size: 40),
              const SizedBox(height: 12),
              Text(
                'Tidak ada user dengan role ini.',
                style: TextStyle(color: _C.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _getCurrentPageData().length,
        separatorBuilder: (context, index) =>
            Divider(color: _C.border2, height: 1),
        itemBuilder: (context, index) {
          final user = _getCurrentPageData()[index];
          final roleColor = _getRoleColor(user['role'] ?? 'member');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FontAwesomeIcons.user,
                    color: roleColor,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    user['username'] ?? 'N/A',
                    style: TextStyle(
                      color: _C.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'ShareTechMono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      (user['role'] ?? 'N/A').toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MADEEvolveSansEVO',
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    user['parent'] ?? 'SYSTEM',
                    style: TextStyle(
                      color: _C.muted2,
                      fontSize: 10,
                      fontFamily: 'ShareTechMono',
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showDeleteConfirmationDialog(user['username']),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: _C.danger.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 1 ? () => setState(() => currentPage--) : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentPage > 1 ? _C.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: currentPage > 1 ? _C.border2 : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.chevron_left,
                color: currentPage > 1 ? _C.text : _C.muted2,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: TextStyle(
                color: _C.accent,
                fontWeight: FontWeight.bold,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: currentPage < totalPages
                ? () => setState(() => currentPage++)
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentPage < totalPages
                    ? _C.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: currentPage < totalPages
                      ? _C.border2
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.chevron_right,
                color: currentPage < totalPages ? _C.text : _C.muted2,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showCreateUserDialog() {
    createUsernameController.clear();
    createPasswordController.clear();
    createDayController.clear();
    newUserRole = 'member';
    showDialog(context: context, builder: (_) => _buildCreateUserDialog());
  }

  Widget _buildCreateUserDialog() {
    return Dialog(
      backgroundColor: _C.surface.withOpacity(0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _C.accent.withOpacity(0.3), width: 1),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.userPlus,
                    color: _C.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'CREATE USER',
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'MADEEvolveSansEVO',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _dialogTextField(
              controller: createUsernameController,
              label: 'Username',
              icon: Icons.person,
            ),
            const SizedBox(height: 14),
            _dialogTextField(
              controller: createPasswordController,
              label: 'Password',
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 14),
            _dialogTextField(
              controller: createDayController,
              label: 'Duration (days)',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            // Role dropdown
            Container(
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border2),
              ),
              child: DropdownButtonFormField<String>(
                value: newUserRole,
                dropdownColor: _C.card,
                style: TextStyle(color: _C.text, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: _C.muted, fontSize: 12),
                  prefixIcon: Icon(
                    Icons.admin_panel_settings,
                    color: _C.muted,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: roleOptions
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(color: _C.text, fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => newUserRole = val ?? 'member'),
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: _C.muted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _createAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _C.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CREATE',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog() {
    deleteController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.danger.withOpacity(0.3), width: 1),
        ),
        insetPadding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FontAwesomeIcons.userMinus,
                      color: _C.danger,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'DELETE USER',
                    style: TextStyle(
                      color: _C.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MADEEvolveSansEVO',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _dialogTextField(
                controller: deleteController,
                label: 'Username',
                icon: Icons.person,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.border2),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: _C.muted, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _deleteUser(deleteController.text.trim());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _C.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'DELETE',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String username) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.danger.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: _C.danger,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Delete',
              style: TextStyle(
                color: _C.text,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus user "$username" secara permanen?',
          style: TextStyle(color: _C.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _C.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(username);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: _C.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: _C.text, fontSize: 14),
        cursorColor: _C.accent,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _C.muted, fontSize: 12),
          prefixIcon: Icon(icon, color: _C.muted, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }
}
