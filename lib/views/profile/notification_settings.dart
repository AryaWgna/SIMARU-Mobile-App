import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_messaging_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    setState(() {
      _isLoading = true;
    });

    final messagingService =
        Provider.of<FirebaseMessagingService>(context, listen: false);

    setState(() {
      _fcmToken = messagingService.token;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Token Notifikasi Firebase',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _fcmToken ?? 'Token tidak tersedia',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text(
              'Pengaturan Notifikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Kirim Token ke Server'),
              subtitle: const Text(
                  'Kirim token notifikasi ke server untuk mendapatkan notifikasi'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final messagingService =
                      Provider.of<FirebaseMessagingService>(context,
                          listen: false);

                  // You should get the auth token from your auth service
                  // This is just an example, replace with your actual auth token
                  final authToken = 'your_auth_token';

                  await messagingService.sendFcmTokenToServer(authToken);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Token berhasil dikirim ke server')),
                  );
                },
                child: const Text('Kirim'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Salin Token'),
              subtitle: const Text('Salin token notifikasi ke clipboard'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (_fcmToken != null) {
                    // Copy to clipboard logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Token disalin ke clipboard')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
