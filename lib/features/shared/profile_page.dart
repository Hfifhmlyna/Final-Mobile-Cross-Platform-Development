import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: _roleColor(user?.role),
                    backgroundImage: user?.fotoUrl != null ? NetworkImage(user!.fotoUrl!) : null,
                    child: user?.fotoUrl == null
                        ? Text(
                            (user?.nama ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 16, color: _roleColor(user?.role)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.nama ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(user?.role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role.value ?? '',
                style: TextStyle(color: _roleColor(user?.role), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Info cards
            _InfoCard(icon: Icons.email, label: 'Email', value: user?.email ?? '-'),
            if (user?.kelasId != null)
              _InfoCard(icon: Icons.class_, label: 'Kelas', value: user!.kelasId!),
            const SizedBox(height: 24),

            // Actions
            _ActionTile(
              icon: Icons.lock_outline,
              title: 'Ganti Password',
              onTap: () => _showChangePasswordDialog(context, auth),
            ),
            _ActionTile(
              icon: Icons.notifications_outlined,
              title: 'Pengaturan Notifikasi',
              onTap: () {},
            ),
            _ActionTile(
              icon: Icons.help_outline,
              title: 'Bantuan',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, auth),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Keluar', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole? role) => switch (role) {
        UserRole.siswa => AppTheme.siswaColor,
        UserRole.guruMapel => AppTheme.guruColor,
        UserRole.waliKelas => AppTheme.waliColor,
        UserRole.guruBK => AppTheme.bkColor,
        UserRole.guruPiket => AppTheme.piketColor,
        _ => AppTheme.primary,
      };

  void _showChangePasswordDialog(BuildContext context, AuthService auth) {
    final emailCtrl = TextEditingController(text: auth.currentUser?.email);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Link reset password akan dikirim ke email:'),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await auth.resetPassword(emailCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email reset password dikirim!')),
                );
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              auth.logout(context);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
