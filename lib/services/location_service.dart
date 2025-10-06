import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/location.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  List<Location>? _locations;
  Map<String, Location>? _locationMap;

  Future<List<Location>> loadLocations() async {
    if (_locations != null) {
      return _locations!;
    }

    try {
      print('📄 Loading locations.json from assets...');
      final String jsonString =
          await rootBundle.loadString('assets/locations.json');
      print('✅ JSON loaded, length: ${jsonString.length} characters');

      final List<dynamic> jsonList = json.decode(jsonString);
      print('✅ JSON parsed, found ${jsonList.length} locations');

      _locations = jsonList.map((json) => Location.fromJson(json)).toList();
      _locationMap = {
        for (var location in _locations!) location.name: location
      };
      print('✅ Locations processed successfully');

      return _locations!;
    } catch (e) {
      print('❌ Error loading locations: $e');
      print('🔄 Falling back to default locations');
      // Return default locations if file loading fails
      return _getDefaultLocations();
    }
  }

  Location? getLocation(String name) {
    return _locationMap?[name];
  }

  List<Location> getAllLocations() {
    return _locations ?? [];
  }

  List<Location> getLocationsByTown(String town) {
    return _locations?.where((location) => location.town == town).toList() ??
        [];
  }

  List<String> getAllTowns() {
    final towns = <String>{};
    for (final location in _locations ?? []) {
      if (location.town != null) {
        towns.add(location.town!);
      }
    }
    return towns.toList();
  }

  List<Location> _getDefaultLocations() {
    // Fallback default locations if JSON fails to load
    return [
      Location(
        name: "Abandoned Gas Station",
        description:
            "You are at an abandoned gas station on the outskirts of Riverside. Broken windows and overturned fuel pumps tell a story of chaos. A few abandoned cars sit in the parking lot, their doors hanging open. One looks like it might be repairable.",
        actions: [
          LocationAction(
              name: "Look around",
              description: "Search the area for useful items and clues"),
          LocationAction(
              name: "Move to nearby location",
              description: "Travel to another location in Riverside"),
          LocationAction(
              name: "Search for fuel",
              description: "Look for gasoline or diesel fuel"),
          LocationAction(
              name: "Check abandoned cars",
              description: "Search the vehicles for supplies or keys"),
          LocationAction(
              name: "Repair vehicle",
              description: "Try to fix a car for long-distance travel"),
          LocationAction(
              name: "Rest here",
              description: "Take a short rest to recover some energy"),
        ],
        town: "Riverside",
        nearbyShort: [
          "Riverside Sporting Goods",
          "Riverside Supermarket",
          "Riverside Town Square",
          "Riverside Cemetery"
        ],
        items: [
          "energy drink",
          "road map",
          "flashlight",
          "motor oil",
          "car battery",
          "tire iron",
          "crowbar"
        ],
        partsNeeded: ["car battery", "spark plugs", "motor oil"],
        hasRepairableVehicle: true,
        fuelAvailable: true,
        zombieChance: 0.2,
        shelter: false,
        restBonus: 5,
      ),
      Location(
        name: "Riverside Sporting Goods",
        description:
            "A sporting goods store in downtown Riverside. The front windows are smashed, but the interior still holds promise. Camping gear and hunting equipment are scattered about.",
        actions: [
          LocationAction(
              name: "Look around",
              description: "Search for weapons and outdoor gear"),
          LocationAction(
              name: "Move to nearby location",
              description: "Travel to another location in Riverside"),
          LocationAction(
              name: "Search weapon section",
              description: "Look for firearms and ammunition"),
          LocationAction(
              name: "Check camping gear",
              description: "Search for survival equipment"),
          LocationAction(
              name: "Search storage room",
              description: "Check the back room for supplies"),
        ],
        town: "Riverside",
        nearbyShort: [
          "Abandoned Gas Station",
          "Riverside Supermarket",
          "Riverside Police Station"
        ],
        items: [
          "hunting knife",
          "camping backpack",
          "sleeping bag",
          "compass",
          "binoculars",
          "spark plugs",
          "baseball bat"
        ],
        zombieChance: 0.3,
        shelter: false,
      ),
      Location(
        name: "Riverside Supermarket",
        description:
            "A large supermarket that has been thoroughly looted. Empty shelves and scattered debris fill the aisles. The pharmacy section might still have some useful supplies.",
        actions: [
          LocationAction(
              name: "Look around",
              description: "Search the store for remaining supplies"),
          LocationAction(
              name: "Move to nearby location",
              description: "Travel to another location in Riverside"),
          LocationAction(
              name: "Search pharmacy",
              description: "Look for medical supplies"),
          LocationAction(
              name: "Check storage areas",
              description: "Search employee areas and storage rooms"),
          LocationAction(
              name: "Search produce section",
              description: "Look for any remaining food"),
        ],
        town: "Riverside",
        nearbyShort: [
          "Abandoned Gas Station",
          "Riverside Sporting Goods",
          "Riverside Town Square"
        ],
        items: [
          "canned food",
          "water bottle",
          "first aid kit",
          "bandages",
          "pain medication",
          "energy bar"
        ],
        zombieChance: 0.25,
        shelter: false,
      ),
    ];
  }
}
