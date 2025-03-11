// lib/features/agence_swap/services/battery_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'battery.dart';

class BatteryService {
  static const String baseUrl = 'http://57.128.178.119:3010/api';

  Future<List<Battery>> fetchOutgoingBatteries(String agenceId) async {
    final url = '$baseUrl/agenceswapbatteries/$agenceId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return (data['batteries'] as List)
              .map((battery) => Battery.fromJson(battery))
              .toList();
        }
      }
      return [];
    } catch (error) {
      print('❌ [ERROR] Exception while fetching batteries: $error');
      return [];
    }
  }

  Future<double?> fetchBatterySOC(String macId) async {
    final url = '$baseUrl/batteries/soc/$macId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['SOC'] != null
            ? double.parse(data['SOC'].toString().replaceAll('%', ''))
            : null;
      }
      return null;
    } catch (error) {
      print('❌ Error fetching SOC: $error');
      return null;
    }
  }
}