import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/recent_activity_controller.dart';
import '../../models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load activities when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentActivityController>().loadRecentActivities();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final controller = context.read<RecentActivityController>();
      if (!controller.isLoading && controller.hasMoreData) {
        controller.loadMoreActivities();
      }
    }
  }

  Widget _buildHistoryItem(HistoryModel activity) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(activity.actionDate);
    final formattedTime = DateFormat('HH:mm').format(activity.actionDate);

    return Container(
      width: double.infinity,
      height: 73,
      margin: const EdgeInsets.only(bottom: 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
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
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
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
                    'Asset ID: ${activity.assetInfo.assetCode}',
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
                    child: Text(
                      activity.message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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

  Widget _buildMonthSection(String monthYear, List<HistoryModel> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 16),
          child: Text(
            monthYear,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF213268),
              height: 0.75,
            ),
          ),
        ),
        ...activities.map((activity) => _buildHistoryItem(activity)).toList(),
      ],
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
                ],
              ),
            ),
            // History items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
                child: Consumer<RecentActivityController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading && controller.activities.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF213268),
                        ),
                      );
                    }

                    if (controller.error != null &&
                        controller.activities.isEmpty) {
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

                    // Group activities by month
                    final byMonth = controller.activitiesByMonth;
                    final months = byMonth.keys.toList()
                      ..sort((a, b) {
                        // Sort from newest to oldest
                        final aDate = DateFormat('MMMM yyyy').parse(a);
                        final bDate = DateFormat('MMMM yyyy').parse(b);
                        return bDate.compareTo(aDate);
                      });

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: months.length +
                          (controller.isLoading &&
                                  controller.activities.isNotEmpty
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index < months.length) {
                          final month = months[index];
                          return _buildMonthSection(month, byMonth[month]!);
                        } else {
                          // Loading indicator at the bottom
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF213268),
                              ),
                            ),
                          );
                        }
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
