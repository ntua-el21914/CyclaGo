import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trip_map_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  String _selectedIsland = 'Select island';
  DateTime? _startDate;
  DateTime? _endDate;
  
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

  Future<void> _selectDateRange() async {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    DateTime displayedMonth = DateTime.now();
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            const primaryBlue = Color(0xFF1269C7);
            
            List<Widget> _buildCalendarDays() {
              final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
              final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
              final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
              final daysInMonth = lastDayOfMonth.day;
              
              List<Widget> dayWidgets = [];
              
              // Empty cells for days before month starts
              for (int i = 0; i < firstWeekday; i++) {
                dayWidgets.add(const SizedBox());
              }
              
              // Day cells
              for (int day = 1; day <= daysInMonth; day++) {
                final currentDate = DateTime(displayedMonth.year, displayedMonth.month, day);
                final isToday = currentDate.year == DateTime.now().year &&
                    currentDate.month == DateTime.now().month &&
                    currentDate.day == DateTime.now().day;
                final isPast = currentDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                final isStartDate = tempStartDate != null &&
                    currentDate.year == tempStartDate!.year &&
                    currentDate.month == tempStartDate!.month &&
                    currentDate.day == tempStartDate!.day;
                final isEndDate = tempEndDate != null &&
                    currentDate.year == tempEndDate!.year &&
                    currentDate.month == tempEndDate!.month &&
                    currentDate.day == tempEndDate!.day;
                final isInRange = tempStartDate != null &&
                    tempEndDate != null &&
                    currentDate.isAfter(tempStartDate!) &&
                    currentDate.isBefore(tempEndDate!);
                
                dayWidgets.add(
                  GestureDetector(
                    onTap: isPast ? null : () {
                      setDialogState(() {
                        if (tempStartDate == null || tempEndDate != null) {
                          tempStartDate = currentDate;
                          tempEndDate = null;
                        } else if (currentDate.isBefore(tempStartDate!)) {
                          tempStartDate = currentDate;
                        } else {
                          tempEndDate = currentDate;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isStartDate || isEndDate) ? primaryBlue : (isInRange ? primaryBlue.withOpacity(0.2) : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(color: primaryBlue, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: GoogleFonts.hammersmithOne(
                            color: isPast ? Colors.grey : ((isStartDate || isEndDate) ? Colors.white : Colors.black),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              return dayWidgets;
            }
            
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: primaryBlue, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Month navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: primaryBlue),
                          onPressed: () {
                            setDialogState(() {
                              displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
                            });
                          },
                        ),
                        Text(
                          '${_getMonthName(displayedMonth.month)} ${displayedMonth.year}',
                          style: GoogleFonts.hammersmithOne(fontSize: 20, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: primaryBlue),
                          onPressed: () {
                            setDialogState(() {
                              displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Weekday headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map((d) => SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(d, style: GoogleFonts.hammersmithOne(color: primaryBlue, fontSize: 14)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    // Calendar grid
                    SizedBox(
                      height: 200,
                      child: GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _buildCalendarDays(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Selected range display
                    Text(
                      tempStartDate != null && tempEndDate != null
                          ? '${_formatDate(tempStartDate!)} - ${_formatDate(tempEndDate!)}'
                          : tempStartDate != null
                              ? '${_formatDate(tempStartDate!)} - Select end'
                              : 'Select dates',
                      style: GoogleFonts.hammersmithOne(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 15),
                    // Confirm button
                    GestureDetector(
                      onTap: () {
                        if (tempStartDate != null && tempEndDate != null) {
                          Navigator.pop(context, DateTimeRange(start: tempStartDate!, end: tempEndDate!));
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (tempStartDate != null && tempEndDate != null) ? primaryBlue : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          _startDate = result.start;
          _endDate = result.end;
        });
      }
    });
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
      // Header bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Color(0xFF1269C7),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Text(
                    'Trip Planner',
                    style: GoogleFonts.hammersmithOne(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
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

              // Island name dropdown
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: primaryBlue, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _islands.contains(_selectedIsland) ? _selectedIsland : null,
                            hint: Text(
                              'Select island',
                              style: GoogleFonts.hammersmithOne(
                                color: const Color(0xFF737373),
                                fontSize: 20,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 24),
                            items: _islands.map((island) => DropdownMenuItem(
                              value: island,
                              child: Text(
                                island,
                                style: GoogleFonts.hammersmithOne(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            )).toList(),
                            onChanged: (value) {
                              setState(() => _selectedIsland = value!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 13),

              // Date range picker
              GestureDetector(
                onTap: _selectDateRange,
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: primaryBlue, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateRangeText,
                            style: GoogleFonts.hammersmithOne(
                              color: _startDate != null ? Colors.black : const Color(0xFF737373),
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),

              // Submit button
              GestureDetector(
                onTap: () {
                  // Navigate to trip map screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripMapScreen(
                        tripName: _tripNameController.text.isEmpty 
                            ? 'My Trip' 
                            : _tripNameController.text,
                        islandName: _selectedIsland,
                      ),
                    ),
                  );
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
    );
  }
}
