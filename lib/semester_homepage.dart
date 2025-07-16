import 'package:flutter/material.dart';
import 'package:gpa_calculator/courses.dart';
import 'package:gpa_calculator/gpa_homePage.dart';
import 'package:hive/hive.dart';

class SemesterHomepage extends StatefulWidget {
  const SemesterHomepage({super.key});

  @override
  State<SemesterHomepage> createState() => _SemesterHomepageState();
}

class _SemesterHomepageState extends State<SemesterHomepage>
    with SingleTickerProviderStateMixin {
  double cgpa = 0.00;
  int crdHrs = 0;
  int semcount = 0;
  late Box<List> semestersBox;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    semestersBox = Hive.box<List>('semestersBox');
    _loadSemestersFromHive();

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
    super.dispose();
  }

  void _loadSemestersFromHive() {
    setState(() {
      allSemesters =
          semestersBox.values
              .map((list) => List<Courses>.from(list.cast<Courses>()))
              .toList();
      semcount = allSemesters.length;
      cgpa = _calculateCGPA();
      crdHrs = totalCreditHours();
    });
  }

  List<List<Courses>> allSemesters = [];

  void _showTargetCgpaDialog() {
    final TextEditingController currentCgpaController = TextEditingController();
    final TextEditingController currentCrdHrsController =TextEditingController();
    final TextEditingController targetCgpaController = TextEditingController();
    final TextEditingController nextSemCrdHrsController =TextEditingController();

    String resultMessage = '';
    String difficulty = '';
    late double reqGPA;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Target CGPA Calculator"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
                TextButton(
                  onPressed: () {
                    double? currCgpa = double.tryParse(
                      currentCgpaController.text,
                    );
                    int? currCrdHrs = int.tryParse(
                      currentCrdHrsController.text,
                    );
                    double? targetCgpa = double.tryParse(
                      targetCgpaController.text,
                    );
                    int? nextCrdHrs = int.tryParse(
                      nextSemCrdHrsController.text,
                    );

                    if (currCgpa == null ||
                        currCrdHrs == null ||
                        targetCgpa == null ||
                        nextCrdHrs == null ||
                        currCgpa < 0 ||
                        currCgpa > 4 ||
                        targetCgpa < 0 ||
                        targetCgpa > 4 ||
                        currCrdHrs <= 0 ||
                        nextCrdHrs <= 0) {
                      setStateDialog(() {
                        resultMessage = "Please enter valid numeric values.";
                      });
                      return;
                    }

                    double requiredGPA = _getReqGPA(
                      currCgpa,
                      currCrdHrs,
                      targetCgpa,
                      nextCrdHrs,
                    );
                    difficulty = _getDifficulty(requiredGPA);
                    setStateDialog(() {
                      reqGPA = _getReqGPA(currCgpa, currCrdHrs, targetCgpa, nextCrdHrs);
                      if (requiredGPA > 4.0) {
                        resultMessage =
                            "❌ It's not possible to reach your target CGPA with the given credit hours.";
                      } else if (requiredGPA < 0) {
                        resultMessage = "You're already above the target CGPA!";
                      } else {
                        resultMessage =
                            "✅ You need a GPA of ${requiredGPA.toStringAsFixed(2)} next semester to reach your target CGPA.";
                      }
                    });
                  },
                  child: Text("Calculate"),
                ),
              ],
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentCgpaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Current CGPA"),
                    ),
                    TextField(
                      controller: currentCrdHrsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Current Credits"),
                    ),
                    TextField(
                      controller: targetCgpaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Target CGPA"),
                    ),
                    TextField(
                      controller: nextSemCrdHrsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Additional Credits",
                      ),
                    ),
                    SizedBox(height: 20),
                    if (resultMessage.isNotEmpty)
                      Text(
                        'Diffculty: $difficulty \n $resultMessage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getColorDiffculty(reqGPA),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _appBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child:
              allSemesters.isEmpty
                  ? Center(
                    child: Text(
                      'No Semesters Yet! Press +',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  )
                  : ListView.builder(
                    itemCount: allSemesters.length,
                    itemBuilder: (context, index) {
                      return _buildSemesterTile(index);
                    },
                  ),
        ),
        floatingActionButton: _floatingActionButton(),
      ),
    );
  }

  Widget _buildSemesterTile(int index) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(color: Colors.red.withOpacity(0.8)),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        final removed = allSemesters[index];
        final currentCGPA = cgpa;
        final currentCrdHrs = crdHrs;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Semester ${index + 1} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  allSemesters.insert(index, removed);
                  cgpa = currentCGPA;
                  crdHrs = currentCrdHrs;
                });
              },
            ),
          ),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              allSemesters.removeAt(index);
              semestersBox.delete('sem_$index');
              cgpa = _calculateCGPA();
              crdHrs = totalCreditHours();
            });

            Future.microtask(() => _reorderBoxKeys());
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade800,
        child: ListTile(
          title: Text(
            'Semester ${index + 1}',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          trailing: Icon(Icons.school, color: Colors.amberAccent),
          onTap: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 400),
                pageBuilder:
                    (context, animation, secondaryAnimation) => gpaCalcHome(
                      initialCourses: allSemesters[index],
                      previousCgpa: cgpa,
                      previousCrdHrs: totalCreditHours(),
                    ),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
                settings: RouteSettings(
                  // This disables automatic Hero transitions
                  name: 'no-hero',
                ),
              ),
            );
            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                allSemesters[index] = result['courses'];
                semestersBox.put('sem_$index', result['courses']);
                cgpa = result['cgpa'];
                crdHrs = totalCreditHours();
              });
            }
          },
        ),
      ),
    );
  }

  void _reorderBoxKeys() {
    semestersBox.clear();
    for (int i = 0; i < allSemesters.length; i++) {
      semestersBox.put('sem_$i', allSemesters[i]);
    }
  }

  double _getReqGPA(double? currCgpa, int? currCrdHrs, double? targetCgpa, int? nextCrdHrs,) {
    
    if (currCgpa == null || currCrdHrs == null || targetCgpa == null || nextCrdHrs == null) {
    throw ArgumentError("All input values must be non-null.");
    }

    double currPoints = currCgpa * currCrdHrs;
    double expPoints = (targetCgpa * (currCrdHrs + nextCrdHrs) - currPoints);

    return (expPoints / nextCrdHrs);
  }

  String _getDifficulty(double reqGPA) {
    if(reqGPA >= 4.00) {
      return 'Cooked';
    }else if (reqGPA >= 3.75) {
      return 'Challenging';
    } else if (reqGPA >= 3.00) {
      return 'Moderate';
    } else {
      return 'Achievable';
    }
  }

  Color _getColorDiffculty(double reqGPA) {
    if (reqGPA >= 3.75) {
      return Colors.red;
    } else if (reqGPA >= 3.00) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
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

    for (var semesterCourses in allSemesters) {
      for (var course in semesterCourses) {
        totalCrdHrs += course.crdHrs;
      }
    }

    return totalCrdHrs;
  }

  double _calculateCGPA() {
    double totalPoints = 0.00;
    int totalCrdHrs = totalCreditHours();

    for (var semesterCourses in allSemesters) {
      for (var course in semesterCourses) {
        totalPoints += _gradeToPoint(course.grade) * course.crdHrs;
      }
    }

    if (totalCrdHrs == 0) return 0.0;

    return totalPoints / totalCrdHrs;
  }

  Column _floatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: _showTargetCgpaDialog,
          heroTag: null,
          backgroundColor: Colors.amber,
          icon: Icon(Icons.access_time),
          label: Text("Plan CGPA"),
        ),
        SizedBox(height: 20),
        FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              allSemesters.add([]);
              semestersBox.put('sem_$semcount', []);
              semcount = allSemesters.length;
            });
          },
          heroTag: null,
          backgroundColor: Colors.amber,
          icon: Icon(Icons.add),
          label: Text("Add Semester"),
        ),
      ],
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.amber,
      centerTitle: true,
      title: Column(
        children: [
          Text(cgpa.isNaN ? 'CGPA: 0.00' : 'CGPA: ${cgpa.toStringAsFixed(2)}'),
          Text('Credit Hours: $crdHrs'),
        ],
      ),
    );
  }
}