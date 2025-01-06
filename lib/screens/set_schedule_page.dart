import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SetSchedulePage extends StatefulWidget {
  const SetSchedulePage({super.key});

  @override
  _SetSchedulePageState createState() => _SetSchedulePageState();
}

class _SetSchedulePageState extends State<SetSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<DateTime, TextEditingController> _scheduleControllers = {};
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  User? _currentUser;
  TimeOfDay? _physicalStartTime;
  TimeOfDay? _physicalEndTime;
  TimeOfDay? _onlineStartTime;
  TimeOfDay? _onlineEndTime;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _scheduleControllers[_selectedDate] = TextEditingController();
    _fetchExistingSchedules();
  }

  void _fetchExistingSchedules() async {
    if (_currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_currentUser!.email!)
          .collection('schedules')
          .get();

      setState(() {
        for (var doc in snapshot.docs) {
          final DateTime date = DateTime.parse(doc.id);
          final data = doc.data();
          if (data['physical_schedule'] != null) {
            final String physicalSchedule = data['physical_schedule'];
            _scheduleControllers[date]?.text = physicalSchedule;
          }
          if (data['online_schedule'] != null) {
            final String onlineSchedule = data['online_schedule'];
            _scheduleControllers[date]?.text += "\nOnline: $onlineSchedule";
          }
        }
      });
    }
  }

  void _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser != null &&
          _physicalStartTime != null &&
          _physicalEndTime != null &&
          _onlineStartTime != null &&
          _onlineEndTime != null) {
        final String physicalScheduleText =
            '${_physicalStartTime!.format(context)} - ${_physicalEndTime!.format(context)}';
        final String onlineScheduleText =
            '${_onlineStartTime!.format(context)} - ${_onlineEndTime!.format(context)}';

        await FirebaseFirestore.instance
            .collection('doctor_schedules')
            .doc(_currentUser!.email!)
            .collection('schedules')
            .doc(_selectedDate.toIso8601String().split('T').first)
            .set({
          'physical_schedule': physicalScheduleText,
          'online_schedule': onlineScheduleText,
        });

        setState(() {
          _scheduleControllers[_selectedDate]?.text =
              'Physical: $physicalScheduleText\nOnline: $onlineScheduleText';
          _physicalStartTime = null;
          _physicalEndTime = null;
          _onlineStartTime = null;
          _onlineEndTime = null;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Your schedules have been saved successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Please select all start and end times.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPhysical, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPhysical) {
          if (isStartTime) {
            _physicalStartTime = picked;
          } else {
            _physicalEndTime = picked;
          }
        } else {
          if (isStartTime) {
            _onlineStartTime = picked;
          } else {
            _onlineEndTime = picked;
          }
        }
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      if (!_scheduleControllers.containsKey(selectedDay)) {
        _scheduleControllers[selectedDay] = TextEditingController();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _selectedDate = focusedDay;
                },
              ),
              const SizedBox(height: 20.0),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Schedule for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 18.0),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectTime(context, true, true),
                          child: const Text('Set Physical Start Time'),
                        ),
                        const SizedBox(width: 10.0),
                        if (_physicalStartTime != null)
                          Text('Start: ${_physicalStartTime!.format(context)}'),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectTime(context, true, false),
                          child: const Text('Set Physical End Time'),
                        ),
                        const SizedBox(width: 10.0),
                        if (_physicalEndTime != null)
                          Text('End: ${_physicalEndTime!.format(context)}'),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectTime(context, false, true),
                          child: const Text('Set Online Start Time'),
                        ),
                        const SizedBox(width: 10.0),
                        if (_onlineStartTime != null)
                          Text('Start: ${_onlineStartTime!.format(context)}'),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectTime(context, false, false),
                          child: const Text('Set Online End Time'),
                        ),
                        const SizedBox(width: 10.0),
                        if (_onlineEndTime != null)
                          Text('End: ${_onlineEndTime!.format(context)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSchedule,
                child: const Text('Save Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
