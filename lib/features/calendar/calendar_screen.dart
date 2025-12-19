import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trip_planner_screen.dart';

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
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: GoogleFonts.hammersmithOne(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // This makes centering work!
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
                              width: 3,
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
          ],
        ),
      ),
      ),
    );
  }
}
