import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _favoriteController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _favoriteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      _nameController.text = provider.user.name;
      _emailController.text = provider.user.email;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  // Latihan 5: Menambahkan Validasi Keamanan pada _saveProfile()
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final nameInput = _nameController.text.trim();
      final emailInput = _emailController.text.trim();
      final provider = context.read<UserProvider>();

      // Latihan 5: (b) Cek apakah nama mengandung karakter berbahaya (misalnya <script>)
      final dangerousPattern = RegExp(r'[<>/\\{}]|script', caseSensitive: false);
      if (dangerousPattern.hasMatch(nameInput)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peringatan Keamanan: Nama mengandung karakter berbahaya atau skrip!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Latihan 5: (a) Cek apakah email sudah digunakan (simulasi dengan SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      // Jika user belum login (baru mendaftar) dan email yang dimasukkan sama dengan email tersimpan
      if (!provider.user.isLoggedIn &&
          savedEmail != null &&
          savedEmail.isNotEmpty &&
          savedEmail.toLowerCase() == emailInput.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validasi Gagal: Email sudah pernah terdaftar di perangkat ini!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Jika lolos semua validasi keamanan:
      final updatedUser = provider.user.copyWith(
        name: nameInput,
        email: emailInput,
        isLoggedIn: true,
      );
      await provider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserProvider>().logout();
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Latihan 4: Menggunakan Consumer<UserProvider>
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              if (provider.user.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.deepPurple,
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama tidak boleh kosong';
                                  }
                                  // Validasi inline karakter berbahaya
                                  if (RegExp(r'[<>/\\{}]|script', caseSensitive: false)
                                      .hasMatch(value)) {
                                    return 'Nama mengandung karakter berbahaya (<script>)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  final emailRegex =
                                      RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('Simpan Profil'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Fitur Latihan 3: Daftar Hobi
                        const Row(
                          children: [
                            Icon(Icons.interests, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              'Daftar Hobi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _favoriteController,
                                decoration: const InputDecoration(
                                  labelText: 'Tambah hobi',
                                  hintText: 'Contoh: Coding, Membaca',
                                  prefixIcon: Icon(Icons.sports_esports),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onFieldSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    provider.addFavorite(val.trim());
                                    _favoriteController.clear();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () {
                                if (_favoriteController.text.trim().isNotEmpty) {
                                  provider.addFavorite(_favoriteController.text.trim());
                                  _favoriteController.clear();
                                }
                              },
                              icon: const Icon(Icons.add),
                              tooltip: 'Tambah Hobi',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (provider.favorites.isEmpty)
                          const Text(
                            'Belum ada hobi yang disimpan.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: provider.favorites.map((item) {
                              return Chip(
                                label: Text(item),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => provider.removeFavorite(item),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),
                        Card(
                          color: Colors.amber[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.amber[800]),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Catatan Keamanan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Data disimpan di SharedPreferences (plaintext). '
                                  'Jangan simpan password atau data sensitif di sini. '
                                  'Gunakan secure storage untuk data sensitif.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

