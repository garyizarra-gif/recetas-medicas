import 'package:flutter/material.dart';

/// Marca del autor con parpadeo suave (se desvanece y reaparece).
class MarcaSystemIA extends StatefulWidget {
  const MarcaSystemIA({super.key});

  @override
  State<MarcaSystemIA> createState() => _EstadoMarca();
}

class _EstadoMarca extends State<MarcaSystemIA>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Text(
        'Elaborado por SystemIA · cel. 965754455',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
