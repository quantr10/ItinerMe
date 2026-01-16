import 'package:flutter/material.dart';

enum TransportationType { busMetro, car, motorcycle }

extension TransportationTypeX on TransportationType {
  String get label {
    switch (this) {
      case TransportationType.busMetro:
        return 'Bus/Metro';
      case TransportationType.car:
        return 'Car';
      case TransportationType.motorcycle:
        return 'Motorcycle';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportationType.busMetro:
        return Icons.directions_bus;
      case TransportationType.car:
        return Icons.directions_car;
      case TransportationType.motorcycle:
        return Icons.motorcycle;
    }
  }

  String get googleMode {
    switch (this) {
      case TransportationType.car:
        return 'driving';
      case TransportationType.motorcycle:
        return 'two_wheeler';
      case TransportationType.busMetro:
        return 'transit';
    }
  }
}
