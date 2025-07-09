import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase/firebase_messaging_service.dart';
import '../../controllers/notification/notification_settings_controller.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        Provider.of<NotificationSettingsController>(context, listen: false);
    _getToken();
  }

  Future<void> _getToken() async {
    final messagingService =
        Provider.of<FirebaseMessagingService>(context, listen: false);
    await _controller.getToken(context, messagingService);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
      ),
      body: Consumer<NotificationSettingsController>(
          builder: (context, controller, _) {
        return Padding(
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
              controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.fcmToken ?? 'Token tidak tersedia',
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
                    const authToken = 'your_auth_token';

                    final success = await controller.sendTokenToServer(
                        context, messagingService, authToken);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Token berhasil dikirim ke server')),
                      );
                    } else if (controller.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(controller.errorMessage!)),
                      );
                    }
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
                    if (controller.fcmToken != null) {
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
        );
      }),
    );
  }
}
