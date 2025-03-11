import 'package:flutter/material.dart';
import 'package:swap/operations/agence/dashboard/dashboard.dart';
import 'package:swap/operations/agence/lease/screen/leasePayment.dart';
import 'package:swap/operations/agence/swap/battery_swap_screen.dart';
import 'package:swap/operations/authentication/login.dart';
import 'package:swap/operations/distributeur/dashboard/dashboard.dart';
import 'package:swap/operations/entrepot/dashboard/dashboard.dart';
import 'package:swap/operations/entrepot/swap%20screen/swap%20type/swap_type.dart';
import 'package:swap/operations/entrepot/swap%20screen/swap_screen.dart';

import 'operations/agence/history agence/history_agence.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWAP',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellowAccent),
        useMaterial3: true,
      ),
      home: LoginScreen(),
      routes: {
        '/agenceDashboard': (context)=> DashboardAgence(),
        '/entrepotDashboard': (context)=> DashboardEntrepot(),
        '/disDashboard': (context)=> DashboardDistributeur(loggedInUser: {},),
        '/entrepotswap' : (context) => EntrepotSwap(selectedSwapType: '', uniqueId: '', loggedInUser: {}, agenceUniqueId: '', idEntrepot: '', distributeurId: '',),

        '/agenceswap': (context)=> AgenceSwapPage(agenceId: '', uniqueId: '', email: '', location: '', userType: '',),
        '/historique-agence': (context) =>  HistoryAgence(uniqueId: ''),
        '/login': (context) => const LoginScreen(),

      },
    );
  }
}

