import 'package:flutter/material.dart';
import 'package:gpa_calculator/courses.dart';

class gpaCalcHome extends StatefulWidget {
  final List<Courses> initialCourses;
  final double previousCgpa;
  final int previousCrdHrs;

  const gpaCalcHome({super.key, required this.initialCourses, required this.previousCgpa, required this.previousCrdHrs});

  @override
  State<gpaCalcHome> createState() => _gpaCalcHomeState();
}

class _gpaCalcHomeState extends State<gpaCalcHome> with SingleTickerProviderStateMixin {
  
  late List<Courses> courses;
  bool hasChanged = false;
  final TextEditingController creditHoursController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  double _otherSemestersPoints = 0.0;
  int _otherSemestersCrdHrs = 0;
  
  @override
  void initState() {
    super.initState();
    courses = List.from(widget.initialCourses); // Create a copy
    
    _calculateOtherSemesters();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    creditHoursController.dispose();
    super.dispose();
  }

  // Calculate what the other semesters contribute (total - current semester)
  void _calculateOtherSemesters() {
    double totalPoints = widget.previousCgpa * widget.previousCrdHrs;
    int totalCrdHrs = widget.previousCrdHrs;
    
    double currentPoints = 0.0;
    int currentCrdHrs = 0;
    
    for (var course in widget.initialCourses) {
      currentPoints += _gradeToPoint(course.grade) * course.crdHrs;
      currentCrdHrs += course.crdHrs;
    }
    
    _otherSemestersPoints = totalPoints - currentPoints;
    _otherSemestersCrdHrs = totalCrdHrs - currentCrdHrs;
  }

  List<String> gradeOptions = [
    'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F',
  ];

  void _showAddCourseDialog() {
    String? selectedGrade;
    String creditHoursText = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add Course'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Select Grade"),
                    value: selectedGrade,
                    items: gradeOptions.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text(grade),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedGrade = value;
                      });
                    },
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: "Credit Hours"),
                    onChanged: (value) {
                      creditHoursText = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final parsed = int.tryParse(creditHoursText);
                    if (selectedGrade != null && parsed != null && parsed > 0) {
                      setState(() {
                        courses.add(Courses(grade: selectedGrade!, crdHrs: parsed));
                        hasChanged = true;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (hasChanged) {
            Navigator.pop(context, {
              'courses': courses,
              'cgpa': _calculateOverallCGPA(),
            });
          } else {
            Navigator.pop(context);
          }
          return false;
        },
        child: Scaffold(
          appBar: _appBar(),
          backgroundColor: Colors.black,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: courses.isEmpty
                ? Center(
                    child: Text(
                      'No Courses Yet! Press +',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) => _buildCourseTile(courses[index]),
                  ),
          ),
          floatingActionButton: _floatingActionButton(),
        ),
      ),
    );
  }

  // Calculate overall CGPA including all semesters
  double _calculateOverallCGPA() {
    // Current semester's contribution
    double currentPoints = 0.0;
    int currentCrdHrs = 0;
    
    for (var course in courses) {
      currentPoints += _gradeToPoint(course.grade) * course.crdHrs;
      currentCrdHrs += course.crdHrs;
    }
    
    // Total = Other semesters + Current semester
    double totalPoints = _otherSemestersPoints + currentPoints;
    int totalCrdHrs = _otherSemestersCrdHrs + currentCrdHrs;
    
    // Handle edge case: no courses at all
    if (totalCrdHrs == 0) return 0.0;
    
    return totalPoints / totalCrdHrs;
  }

  double _gradeToPoint(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return 4.00;
      case 'A-':
        return 3.67;
      case 'B+':
        return 3.33;
      case 'B':
        return 3.00;
      case 'B-':
        return 2.67;
      case 'C+':
        return 2.33;
      case 'C':
        return 2.00;
      case 'C-':
        return 1.67;
      case 'D+':
        return 1.33;
      case 'D':
        return 1.00;
      case 'D-':
        return 0.67;
      case 'F':
        return 0.00;
      default:
        return 0.00;
    }
  }

  int totalCreditHours() {
    int totalCrdHrs = 0;
    for (var course in courses) {
      totalCrdHrs += course.crdHrs;
    }
    return totalCrdHrs;
  }

  double _calculateCurrentGPA() {
    double totalPoints = 0.00;
    int totalCrdHrs = totalCreditHours();

    for (var course in courses) {
      totalPoints += _gradeToPoint(course.grade) * course.crdHrs;
    }

    if (totalCrdHrs == 0) return 0.0;
    
    return totalPoints / totalCrdHrs;
  }

  Widget _buildCourseTile(Courses course) {
    int index = courses.indexOf(course);

    return Dismissible(
      key: UniqueKey(),
      background: Container(color: Colors.red.withOpacity(0.8)),
      onDismissed: (_) {
        final removedCourse = course;
        final removedIndex = index;

        setState(() {
          courses.removeAt(removedIndex);
          hasChanged = true;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  courses.insert(removedIndex, removedCourse);
                  hasChanged = true;
                });
              },
            ),
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade800,
        child: ListTile(
          title: Text('Grade: ${course.grade}', style: TextStyle(fontSize: 18, color: Colors.white)),
          subtitle: Text('Credit Hours: ${course.crdHrs}', style: TextStyle(color: Colors.white)),
          trailing: Icon(Icons.menu_book_outlined, color: Colors.amber),
        ),
      ),
    );
  }

  FloatingActionButton _floatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddCourseDialog,
      heroTag: null,
      backgroundColor: Colors.amber,
      icon: Icon(Icons.add),
      label: Text("Add Course"),
    );
  }

  AppBar _appBar() {
    double overallCGPA = _calculateOverallCGPA();
    double currentGPA = _calculateCurrentGPA();
    
    return AppBar(
      backgroundColor: Colors.amber,
      centerTitle: true,
      title: Column(
        children: [
          Text(overallCGPA.isNaN ? 'CGPA: 0.00' : 'CGPA: ${overallCGPA.toStringAsFixed(2)}'),
          Text('GPA: ${currentGPA.toStringAsFixed(2)} \t\t\t CrdHrs: ${totalCreditHours()}'),
        ],   
      ),
    );
  }
}