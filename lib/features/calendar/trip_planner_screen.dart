import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cyclago/core/trip_service.dart';
import 'trip_map_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  final String? tripId;
  final String? existingTripName;
  final String? existingIsland;
  final DateTime? existingStartDate;
  final DateTime? existingEndDate;

  const TripPlannerScreen({
    super.key,
    this.tripId,
    this.existingTripName,
    this.existingIsland,
    this.existingStartDate,
    this.existingEndDate,
  });

  bool get isEditMode => tripId != null;

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  String? _selectedIsland;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isIslandDropdownOpen = false;
  bool _isDatePickerOpen = false;
  DateTime _displayedMonth = DateTime(2026, 7);

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing existing trip
    if (widget.isEditMode) {
      _tripNameController.text = widget.existingTripName ?? '';
      _selectedIsland = widget.existingIsland;
      _startDate = widget.existingStartDate;
      _endDate = widget.existingEndDate;
      if (_startDate != null) {
        _displayedMonth = DateTime(_startDate!.year, _startDate!.month);
      }
    }
  }
  
  final List<String> _islands = [
    'Amorgos',
    'Anafi',
    'Antiparos',
    'Delos',
    'Donoussa',
    'Folegandros',
    'Ios',
    'Iraklia',
    'Kea',
    'Kimolos',
    'Koufonisia',
    'Kythnos',
    'Milos',
    'Mykonos',
    'Naxos',
    'Paros',
    'Santorini',
    'Schinoussa',
    'Serifos',
    'Sifnos',
    'Sikinos',
    'Syros',
    'Tinos',
  ];

  String get _dateRangeText {
    if (_startDate == null || _endDate == null) {
      return '__/__/__ - __/__/__';
    }
    return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildCalendarGrid() {
    // Get first day of month and days in month
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    
    // Monday = 1, Sunday = 7 (ISO weekday)
    // We need offset: if Monday (1), offset = 0; if Wednesday (3), offset = 2, etc.
    final firstWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final startOffset = firstWeekday - 1;
    
    // Days from previous month
    final prevMonthDays = DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;
    
    // Build calendar cells - start with day headers
    List<Widget> cells = [];
    const primaryBlue = Color(0xFF1269C7);
    
    // Day headers (M T W T F S S)
    const dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var header in dayHeaders) {
      cells.add(
        Container(
          width: 38,
          height: 30,
          child: Center(
            child: Text(
              header,
              textAlign: TextAlign.center,
              style: GoogleFonts.hammersmithOne(
                color: primaryBlue,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
    
    // Previous month days (grey) - only add if startOffset > 0
    for (int i = 0; i < startOffset; i++) {
      final day = prevMonthDays - startOffset + 1 + i;
      cells.add(_buildDayCell(day, isCurrentMonth: false));
    }
    
    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected = (_startDate != null && _isSameDay(_startDate!, date)) ||
                         (_endDate != null && _isSameDay(_endDate!, date));
      final isInRange = _startDate != null && _endDate != null &&
                        date.isAfter(_startDate!) && date.isBefore(_endDate!);
      cells.add(_buildDayCell(day, isCurrentMonth: true, date: date, isSelected: isSelected, isInRange: isInRange));
    }
    
    // Next month days (grey) to fill remaining cells in last row
    final totalDayCells = cells.length - 7; // Subtract header row
    final remainingCells = (7 - (totalDayCells % 7)) % 7;
    for (int day = 1; day <= remainingCells; day++) {
      cells.add(_buildDayCell(day, isCurrentMonth: false));
    }
    
    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 38 / 32,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }


  Widget _buildDayCell(int day, {bool isCurrentMonth = true, DateTime? date, bool isSelected = false, bool isInRange = false}) {
    const primaryBlue = Color(0xFF1269C7);
    
    // Check if date is in the past (before today)
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isPast = isCurrentMonth && date != null && date.isBefore(todayOnly);
    
    return GestureDetector(
      onTap: isCurrentMonth && date != null && !isPast ? () {
        setState(() {
          if (_startDate == null || (_startDate != null && _endDate != null)) {
            // Start new selection
            _startDate = date;
            _endDate = null;
          } else if (date.isBefore(_startDate!)) {
            // Selected before start, swap
            _endDate = _startDate;
            _startDate = date;
          } else {
            // Set end date
            _endDate = date;
          }
        });
      } : null,
      child: Container(
        width: 38,
        height: 40,
        decoration: isSelected
            ? BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              )
            : isInRange
                ? BoxDecoration(
                    color: primaryBlue.withOpacity(0.2),
                  )
                : null,
        child: Center(
          child: Text(
            day.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isPast
                      ? const Color(0xFFBBBBBB) // Light grey for past dates
                      : isCurrentMonth
                          ? Colors.black
                          : const Color(0xFF737373),
              fontSize: 20,
              fontFamily: 'Hammersmith One',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showIslandPicker() async {
    const primaryBlue = Color(0xFF1269C7);
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            height: 410,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 3,
                  color: Color(0xFF1269C7),
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Stack(
              children: [
                // Trip name input field
                Positioned(
                  left: 15,
                  top: 16,
                  child: Container(
                    width: 270,
                    height: 50,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFF1269C7),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12,
                          top: 13,
                          child: SizedBox(
                            width: 183,
                            height: 24,
                            child: Text(
                              'Trip name...',
                              style: const TextStyle(
                                color: Color(0xFF737373),
                                fontSize: 20,
                                fontFamily: 'Hammersmith One',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Island name header + list container
                Positioned(
                  left: 15,
                  top: 79,
                  child: Container(
                    width: 270,
                    height: 200,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFF1269C7),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Island name header
                        Container(
                          width: 270,
                          height: 50,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(width: 1, color: primaryBlue),
                            ),
                          ),
                          child: Stack(
                            children: [
                              const Positioned(
                                left: 5,
                                top: 10,
                                child: Icon(Icons.location_on_outlined, color: primaryBlue, size: 30),
                              ),
                              Positioned(
                                left: 39,
                                top: 13,
                                child: SizedBox(
                                  width: 183,
                                  height: 24,
                                  child: Text(
                                    'Island name',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: 'Hammersmith One',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                left: 232,
                                top: 10,
                                child: Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 30),
                              ),
                            ],
                          ),
                        ),
                        // Scrollable island list
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _islands.length,
                            itemBuilder: (context, index) {
                              final island = _islands[index];
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, island),
                                child: Container(
                                  width: 270,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: index < _islands.length - 1
                                          ? const BorderSide(width: 1, color: primaryBlue)
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 16,
                                        top: 13,
                                        child: SizedBox(
                                          width: 103,
                                          height: 24,
                                          child: Text(
                                            island,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontFamily: 'Hammersmith One',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Date range field
                Positioned(
                  left: 15,
                  top: 292,
                  child: Container(
                    width: 270,
                    height: 50,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFF1269C7),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 7,
                          top: 10,
                          child: Icon(Icons.calendar_today_outlined, color: primaryBlue, size: 30),
                        ),
                        Positioned(
                          left: 41,
                          top: 13,
                          child: SizedBox(
                            width: 220,
                            height: 24,
                            child: Text(
                              '__/__/__ - __/__/__',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'Hammersmith One',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Submit button
                Positioned(
                  left: 130,
                  top: 355,
                  child: Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF1269C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    if (selected != null) {
      setState(() => _selectedIsland = selected);
    }
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      // Header bar - matching calendar screen style
      appBar: AppBar(
        title: Text(
          'Trip Planner',
          style: GoogleFonts.hammersmithOne(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: primaryBlue,
            height: 2,
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe right to go back (positive velocity)
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Center(
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          padding: const EdgeInsets.all(15),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 3,
                color: Color(0xFF1269C7),
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trip name input
              Container(
                width: 270,
                height: 50,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFF1269C7),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: TextField(
                  controller: _tripNameController,
                  decoration: InputDecoration(
                    hintText: 'Trip name...',
                    hintStyle: GoogleFonts.hammersmithOne(
                      color: const Color(0xFF737373),
                      fontSize: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.hammersmithOne(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 13),

              // Island name dropdown (inline expandable)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 270,
                height: _isIslandDropdownOpen ? 200 : 50,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFF1269C7),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    // Header row (always visible)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isIslandDropdownOpen = !_isIslandDropdownOpen;
                          if (_isIslandDropdownOpen) _isDatePickerOpen = false;
                        });
                      },
                      child: Container(
                        width: 270,
                        height: 48,
                        decoration: _isIslandDropdownOpen
                            ? const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(width: 1, color: primaryBlue),
                                ),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: primaryBlue, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedIsland ?? 'Island name',
                                  style: GoogleFonts.hammersmithOne(
                                    color: _selectedIsland != null ? Colors.black : Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Icon(
                                _isIslandDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: primaryBlue,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Expanded list (only visible when open)
                    if (_isIslandDropdownOpen)
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _islands.length,
                          itemBuilder: (context, index) {
                            final island = _islands[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIsland = island;
                                  _isIslandDropdownOpen = false;
                                });
                              },
                              child: Container(
                                width: 270,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: index < _islands.length - 1
                                        ? const BorderSide(width: 1, color: primaryBlue)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      island,
                                      style: GoogleFonts.hammersmithOne(
                                        color: Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // Date range picker (inline expandable)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 270,
                height: _isDatePickerOpen ? 300 : 50,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFF1269C7),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    // Header row (always visible)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDatePickerOpen = !_isDatePickerOpen;
                          if (_isDatePickerOpen) _isIslandDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: 270,
                        height: 48,
                        decoration: _isDatePickerOpen
                            ? const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(width: 1, color: primaryBlue),
                                ),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: primaryBlue, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dateRangeText,
                                  style: GoogleFonts.hammersmithOne(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Expanded calendar (only visible when open)
                    if (_isDatePickerOpen)
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              setState(() {
                                if (details.primaryVelocity! < 0) {
                                  // Swipe left - next month
                                  _displayedMonth = DateTime(
                                    _displayedMonth.year,
                                    _displayedMonth.month + 1,
                                  );
                                } else if (details.primaryVelocity! > 0) {
                                  // Swipe right - previous month
                                  _displayedMonth = DateTime(
                                    _displayedMonth.year,
                                    _displayedMonth.month - 1,
                                  );
                                }
                              });
                            }
                          },
                          child: Column(
                            children: [
                              // Month header with navigation
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
                                      style: GoogleFonts.hammersmithOne(
                                        color: Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _displayedMonth = DateTime(
                                            _displayedMonth.year,
                                            _displayedMonth.month - 1,
                                          );
                                        });
                                      },
                                      child: const Icon(Icons.chevron_left, color: primaryBlue, size: 24),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _displayedMonth = DateTime(
                                            _displayedMonth.year,
                                            _displayedMonth.month + 1,
                                          );
                                        });
                                      },
                                      child: const Icon(Icons.chevron_right, color: primaryBlue, size: 24),
                                    ),
                                  ],
                                ),
                              ),
                              // Calendar grid
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0),
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      side: const BorderSide(width: 1, color: primaryBlue),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _buildCalendarGrid(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // Submit button
              GestureDetector(
                onTap: () async {
                  // Validate required fields
                  if (_tripNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a trip name')),
                    );
                    return;
                  }
                  if (_selectedIsland == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an island')),
                    );
                    return;
                  }
                  if (_startDate == null || _endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select dates')),
                    );
                    return;
                  }

                  try {
                    String tripId;
                    
                    if (widget.isEditMode) {
                      // Update existing trip
                      await TripService.updateTrip(
                        tripId: widget.tripId!,
                        tripName: _tripNameController.text,
                        island: _selectedIsland!,
                        startDate: _startDate!,
                        endDate: _endDate!,
                      );
                      tripId = widget.tripId!;
                    } else {
                      // Create new trip
                      tripId = await TripService.saveTrip(
                        tripName: _tripNameController.text,
                        island: _selectedIsland!,
                        startDate: _startDate!,
                        endDate: _endDate!,
                      );
                    }

                    // Navigate to trip map screen
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripMapScreen(
                            tripId: tripId,
                            tripName: _tripNameController.text,
                            islandName: _selectedIsland!,
                            startDate: _startDate!,
                            endDate: _endDate!,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving trip: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
