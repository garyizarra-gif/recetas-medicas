import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'datos/base_datos.dart';
import 'pantallas/ajustes.dart';
import 'pantallas/examenes.dart';
import 'pantallas/historial.dart';
import 'pantallas/nuevo_examen.dart';
import 'pantallas/hoy.dart';
import 'pantallas/marca.dart';
import 'pantallas/nueva_receta.dart';
import 'pantallas/recetas.dart';
import 'servicios/avisos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  baseDatos = await BaseDatos.abrir();
  await Avisos.iniciar();
  await Avisos.reprogramarFuturos();
  runApp(const AplicacionRecetas());
}

class AplicacionRecetas extends StatelessWidget {
  const AplicacionRecetas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recetas Médicas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Inicio(),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _EstadoInicio();
}

class _EstadoInicio extends State<Inicio> {
  int _pestana = 0;

  void _nuevaReceta() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PantallaNuevaReceta()),
      );

  void _nuevoExamen() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PantallaNuevoExamen()),
      );

  @override
  Widget build(BuildContext context) {
    final titulos = ['Hoy', 'Mis recetas', 'Exámenes', 'Historial de tomas'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[_pestana]),
        actions: [
          IconButton(
            tooltip: 'Ajustes y ayuda',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PantallaAjustes()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _pestana,
              children: [
                PantallaHoy(alAgregar: _nuevaReceta),
                const PantallaRecetas(),
                const PantallaExamenes(),
                const PantallaHistorial(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: MarcaSystemIA(),
          ),
        ],
      ),
      floatingActionButton: _pestana == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: _pestana == 2 ? _nuevoExamen : _nuevaReceta,
              icon: const Icon(Icons.add),
              label: Text(_pestana == 2 ? 'Nuevo resultado' : 'Nueva receta'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Hoy'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined), label: 'Recetas'),
          NavigationDestination(
              icon: Icon(Icons.science_outlined), label: 'Exámenes'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Tomas'),
        ],
      ),
    );
  }
}
