import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/recent_activity_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load activities when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentActivityController>().loadRecentActivities();
    });
  }

  Widget _buildHistoryItem(String date, String time, String assetId,
      String fromStatus, String toStatus) {
    return Container(
      width: double.infinity,
      height: 73,
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Blue line on the left
          Container(
            width: 8,
            height: 73,
            decoration: const BoxDecoration(
              color: Color(0xFF25B1FF),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          // Date and time
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 73,
            color: const Color(0xFFCAC4D0),
          ),
          // Asset info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetId,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: RichText(
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(text: 'You change status from '),
                          TextSpan(
                            text: fromStatus,
                            style: TextStyle(
                              color: fromStatus == 'Available'
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFA726),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' to '),
                          TextSpan(
                            text: toStatus,
                            style: TextStyle(
                              color: toStatus == 'Available'
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFA726),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<RecentActivityController>().loadRecentActivities(),
        child: Column(
          children: [
            // Title and subtitle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 27, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'History',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF213268),
                        height: 0.56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Display all your activities',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'March',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF213268),
                        height: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // History items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
                child: Consumer<RecentActivityController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF213268),
                        ),
                      );
                    }

                    if (controller.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                controller.clearError();
                                controller.loadRecentActivities();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF213268),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.activities.isEmpty) {
                      return const Center(
                        child: Text(
                          'No activities found',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Color(0xFF757575),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.activities.length,
                      itemBuilder: (context, index) {
                        final activity = controller.activities[index];
                        return _buildHistoryItem(
                          activity.date,
                          activity.time,
                          'Asset ID: ${activity.assetId}',
                          activity.oldStatus,
                          activity.newStatus,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
