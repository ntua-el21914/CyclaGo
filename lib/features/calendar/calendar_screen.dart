import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cyclago/core/trip_service.dart';
import 'trip_planner_screen.dart';
import 'trip_view_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header matching Island Pass style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(width: 1, color: primaryBlue)),
              ),
              child: Center(
                child: Text(
                  'My Trips',
                  style: GoogleFonts.hammersmithOne(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Body content
            Expanded(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Create new plan card
            Container(
              width: 384,
              height: 140,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 2,
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
                  Positioned(
                    left: 36,
                    top: 21,
                    child: Text(
                      'Create new plan',
                      style: GoogleFonts.hammersmithOne(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 164,
                    top: 70,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TripPlannerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 55,
                        height: 55,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 2,
                              color: Color(0xFF1269C7),
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF1269C7),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Trips list from Firebase
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: TripService.getTripsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading trips',
                      style: GoogleFonts.hammersmithOne(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                
                final trips = snapshot.data?.docs ?? [];
                
                if (trips.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'No trips planned yet',
                      style: GoogleFonts.hammersmithOne(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: trips.map((doc) {
                    final data = doc.data();
                    final tripName = data['tripName'] ?? 'My Trip';
                    final island = data['island'] ?? '';
                    final startDate = (data['startDate'] as Timestamp?)?.toDate();
                    final endDate = (data['endDate'] as Timestamp?)?.toDate();
                    
                    String dateText = '';
                    if (startDate != null && endDate != null) {
                      dateText = '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
                    }
                    
                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text('Delete Trip', style: GoogleFonts.hammersmithOne()),
                            content: Text('Delete "$tripName"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF1269C7))),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (direction) {
                        TripService.deleteTrip(doc.id);
                      },
                      child: GestureDetector(
                        onTap: () {
                          if (startDate != null && endDate != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripViewScreen(
                                  tripId: doc.id,
                                  tripName: tripName,
                                  islandName: island,
                                  startDate: startDate,
                                  endDate: endDate,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 384,
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 2,
                                color: Color(0xFF1269C7),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tripName,
                                      style: GoogleFonts.hammersmithOne(
                                        color: Colors.black,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: primaryBlue, size: 20),
                                        const SizedBox(width: 5),
                                        Text(
                                          island,
                                          style: GoogleFonts.hammersmithOne(
                                            color: primaryBlue,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: primaryBlue, size: 18),
                                        const SizedBox(width: 5),
                                        Text(
                                          dateText,
                                          style: GoogleFonts.hammersmithOne(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text('Delete Trip', style: GoogleFonts.hammersmithOne()),
                                      content: Text('Delete "$tripName"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, false),
                                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF1269C7))),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    TripService.deleteTrip(doc.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
