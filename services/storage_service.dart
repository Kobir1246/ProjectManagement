import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/event.dart';

class StorageService {
  static const String _projectsKey = 'teamflow_projects';
  static const String _eventsKey = 'teamflow_events';
  static const String _onboardingShownKey = 'teamflow_onboarding_shown';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Project>> loadProjects() async {
    final String? data = _prefs.getString(_projectsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data) as List<dynamic>;
    return jsonList
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProjects(List<Project> projects) async {
    final String data = json.encode(projects.map((p) => p.toJson()).toList());
    await _prefs.setString(_projectsKey, data);
  }

  Future<List<Event>> loadEvents() async {
    final String? data = _prefs.getString(_eventsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data) as List<dynamic>;
    return jsonList
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEvents(List<Event> events) async {
    final String data = json.encode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_eventsKey, data);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_projectsKey);
    await _prefs.remove(_eventsKey);
  }

  Future<bool> hasShownOnboarding() async {
    return _prefs.getBool(_onboardingShownKey) ?? false;
  }

  Future<void> setOnboardingShown() async {
    await _prefs.setBool(_onboardingShownKey, true);
  }
}
