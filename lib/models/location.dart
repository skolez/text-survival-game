class LocationAction {
  final String name;
  final String description;

  LocationAction({
    required this.name,
    required this.description,
  });

  factory LocationAction.fromJson(Map<String, dynamic> json) {
    return LocationAction(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class Location {
  final String name;
  final String description;
  final List<LocationAction> actions;
  final String? town;
  final List<String> nearbyShort;
  final List<String> nearbyLong;
  final List<String> items;
  final List<String> partsNeeded;
  final bool hasRepairableVehicle;
  final bool fuelAvailable;
  final double zombieChance;
  final bool shelter;
  final int restBonus;

  Location({
    required this.name,
    required this.description,
    required this.actions,
    this.town,
    this.nearbyShort = const [],
    this.nearbyLong = const [],
    this.items = const [],
    this.partsNeeded = const [],
    this.hasRepairableVehicle = false,
    this.fuelAvailable = false,
    this.zombieChance = 0.0,
    this.shelter = false,
    this.restBonus = 0,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      actions: (json['actions'] as List<dynamic>?)
          ?.map((action) => LocationAction.fromJson(action))
          .toList() ?? [],
      town: json['town'],
      nearbyShort: List<String>.from(json['nearby_short'] ?? []),
      nearbyLong: List<String>.from(json['nearby_long'] ?? []),
      items: List<String>.from(json['items'] ?? []),
      partsNeeded: List<String>.from(json['parts_needed'] ?? []),
      hasRepairableVehicle: json['has_repairable_vehicle'] ?? false,
      fuelAvailable: json['fuel_available'] ?? false,
      zombieChance: (json['zombie_chance'] ?? 0.0).toDouble(),
      shelter: json['shelter'] ?? false,
      restBonus: json['rest_bonus'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'actions': actions.map((action) => action.toJson()).toList(),
      'town': town,
      'nearby_short': nearbyShort,
      'nearby_long': nearbyLong,
      'items': items,
      'parts_needed': partsNeeded,
      'has_repairable_vehicle': hasRepairableVehicle,
      'fuel_available': fuelAvailable,
      'zombie_chance': zombieChance,
      'shelter': shelter,
      'rest_bonus': restBonus,
    };
  }

  List<String> getAllNearbyLocations() {
    return [...nearbyShort, ...nearbyLong];
  }

  bool canTravelTo(String locationName) {
    return getAllNearbyLocations().contains(locationName);
  }
}
