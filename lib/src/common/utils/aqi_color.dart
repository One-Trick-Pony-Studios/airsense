import 'package:flutter/material.dart';

Color getAqiColor(double value) {
  if (value <= 50) {
    return Colors.green;
  } else if (value <= 100) {
    return Colors.yellow;
  } else if (value <= 150) {
    return Colors.orange; // Added orange for consistency
  } else {
    return Colors.red;
  }
}
