import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_mutation.dart';
import 'asset_depreciation.dart';
import 'asset_details.dart';

class AssetSchedule extends StatefulWidget {
  const AssetSchedule({super.key});

  @override
  State<AssetSchedule> createState() => _AssetScheduleState();
}

class _AssetScheduleState extends State<AssetSchedule> {
  DateTime _focusedDay =
      DateTime(2025, 3, 1); // Sesuai dengan gambar (March 2025)
  final CalendarController _calendarController = CalendarController();

  // Nama bulan dalam Bahasa Inggris (sesuai gambar)
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  // Navigasi bulan
  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      _calendarController.displayDate = _focusedDay;
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      _calendarController.displayDate = _focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(context, 'schedule'),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Ukur tinggi status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
          // Warna biru tua untuk AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 82 + statusBarHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF213268),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF56C5F1),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // AppBar Content
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 82,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 32),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AssetDetails(qrData: '')),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Image.asset(
                        'images/Logo_RS_UMMI_white.png',
                        width: 208.14,
                        height: 55,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Calendar Section
          _buildCalendarSection(),

          // Schedule List
          _buildScheduleList(),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      children: [
        // Month/Year Header with Navigation
        _buildMonthYearHeader(),

        // SyncFusion Calendar with swipe gesture
        _buildCalendar(),
      ],
    );
  }

  Widget _buildMonthYearHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  months[_focusedDay.month - 1],
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF252525),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_focusedDay.year}',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF252525),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _prevMonth,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      height: 300,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Geser ke kanan untuk bulan sebelumnya
          if (details.primaryVelocity! > 0) {
            _prevMonth();
          }
          // Geser ke kiri untuk bulan berikutnya
          else if (details.primaryVelocity! < 0) {
            _nextMonth();
          }
        },
        child: SfCalendar(
          controller: _calendarController,
          view: CalendarView.month,
          headerHeight: 0,
          viewHeaderHeight: 30,
          initialDisplayDate: _focusedDay,
          initialSelectedDate: _focusedDay,
          showCurrentTimeIndicator: false,
          todayHighlightColor: Colors.black,
          cellBorderColor: Colors.transparent,
          monthViewSettings: const MonthViewSettings(
            numberOfWeeksInView: 6,
            dayFormat: 'EEE',
            showAgenda: false,
            monthCellStyle: MonthCellStyle(
              textStyle: TextStyle(
                fontFamily: 'Lato',
                fontSize: 12,
                color: Colors.black,
              ),
              trailingDatesTextStyle: TextStyle(
                fontFamily: 'Lato',
                fontSize: 12,
                color: Colors.grey,
              ),
              leadingDatesTextStyle: TextStyle(
                fontFamily: 'Lato',
                fontSize: 12,
                color: Colors.grey,
              ),
              todayTextStyle: TextStyle(
                fontFamily: 'Lato',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            appointmentDisplayCount: 1,
            showTrailingAndLeadingDates: true,
          ),
          viewHeaderStyle: const ViewHeaderStyle(
            dayTextStyle: TextStyle(
              fontFamily: 'Lato',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          selectionDecoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          dataSource: _getCalendarDataSource(),
          cellEndPadding: 2,
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView(
          children: [
            _buildScheduleItem(
              'Asset Name',
              'Title',
              'Due Date: 06/03/25',
              'Scheduled',
              const Color(0xFF25B1FF),
              icon: Icons.schedule,
              iconColor: const Color(0xFF213268),
            ),
            const SizedBox(height: 12),
            _buildScheduleItem(
              'Asset Name',
              'Title',
              'Due Date: 06/03/25',
              'In Progress',
              const Color(0xFFACC3EF),
              icon: Icons.refresh,
              iconColor: const Color(0xFF25B1FF),
            ),
            const SizedBox(height: 12),
            _buildScheduleItem(
              'Asset Name',
              'Title',
              'Due Date: 06/03/25',
              'Completed',
              const Color(0xFFDAAE0F),
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildScheduleItem(
              'Asset Name',
              'Title',
              'Due Date: 06/03/25',
              'Canceled',
              const Color(0xFFDAAE0F),
              icon: Icons.cancel,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // Calendar Data Source
  _AppointmentDataSource _getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[
      // Tanggal 1
      Appointment(
        startTime: DateTime(2025, 3, 1),
        endTime: DateTime(2025, 3, 1).add(const Duration(hours: 1)),
        subject: 'Review Task',
        color: const Color(0xFFDAAE0F),
        isAllDay: true,
      ),
      // Tanggal 3
      Appointment(
        startTime: DateTime(2025, 3, 3),
        endTime: DateTime(2025, 3, 3).add(const Duration(hours: 1)),
        subject: 'Meeting',
        color: const Color(0xFF25B1FF),
        isAllDay: true,
      ),
      // Tanggal 5-6
      Appointment(
        startTime: DateTime(2025, 3, 5),
        endTime: DateTime(2025, 3, 6).add(const Duration(hours: 1)),
        subject: 'Task Due',
        color: const Color(0xFF25B1FF),
        isAllDay: true,
      ),
      // Tanggal 9
      Appointment(
        startTime: DateTime(2025, 3, 9),
        endTime: DateTime(2025, 3, 9).add(const Duration(hours: 1)),
        subject: 'Maintenance',
        color: const Color(0xFFACC3EF),
        isAllDay: true,
      ),
      // Tanggal 15 - Untuk hari ini (black background)
      Appointment(
        startTime: DateTime(2025, 3, 15),
        endTime: DateTime(2025, 3, 15).add(const Duration(hours: 1)),
        subject: 'Today',
        color: Colors.black,
        isAllDay: true,
      ),
      // Tanggal 20-21
      Appointment(
        startTime: DateTime(2025, 3, 20),
        endTime: DateTime(2025, 3, 21).add(const Duration(hours: 1)),
        subject: 'Inspection',
        color: const Color(0xFF25B1FF),
        isAllDay: true,
      ),
      // Tanggal 24-26
      Appointment(
        startTime: DateTime(2025, 3, 24),
        endTime: DateTime(2025, 3, 26).add(const Duration(hours: 1)),
        subject: 'Calibration',
        color: const Color(0xFF25B1FF),
        isAllDay: true,
      ),
      // Tanggal 28
      Appointment(
        startTime: DateTime(2025, 3, 28),
        endTime: DateTime(2025, 3, 28).add(const Duration(hours: 1)),
        subject: 'Inspection',
        color: const Color(0xFFACC3EF),
        isAllDay: true,
      ),
      // Tanggal 31
      Appointment(
        startTime: DateTime(2025, 3, 31),
        endTime: DateTime(2025, 3, 31).add(const Duration(hours: 1)),
        subject: 'Test Run',
        color: const Color(0xFFDAAE0F),
        isAllDay: true,
      ),
    ];

    return _AppointmentDataSource(appointments);
  }

  Widget _buildScheduleItem(
    String assetName,
    String title,
    String dueDate,
    String status,
    Color statusColor, {
    IconData icon = Icons.schedule,
    Color iconColor = Colors.grey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vertical status bar
          Container(
            width: 5,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(8)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    assetName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueDate,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, String activePage) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.folder,
            'Document',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetDocument()),
            ),
          ),
          _buildNavItem(
            Icons.history,
            'History',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetHistory()),
            ),
          ),
          _buildNavItem(
            Icons.calendar_today,
            'Schedule',
            activePage == 'schedule',
            () {},
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetMutation()),
            ),
          ),
          _buildNavItem(
            Icons.trending_down,
            'Depreciation',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AssetDepreciation()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF213268) : const Color(0xFF757575),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF213268)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kelas untuk mengelola sumber data kalender
class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
