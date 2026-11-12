import 'package:flutter_test/flutter_test.dart';
import 'package:recetas_medicas/dominio/calculador_tomas.dart';

void main() {
  group('generarHorasDeToma', () {
    test('cada 8 h por 7 días desde las 08:00 genera 21 tomas', () {
      final horas = generarHorasDeToma(
        primeraToma: DateTime(2026, 10, 3, 8),
        cadaHoras: 8,
        dias: 7,
      );
      expect(horas.length, 21);
      expect(horas[0], DateTime(2026, 10, 3, 8));
      expect(horas[1], DateTime(2026, 10, 3, 16));
      expect(horas[2], DateTime(2026, 10, 4, 0));
      expect(horas.last, DateTime(2026, 10, 10, 0));
    });

    test('cada 12 h por 5 días genera 10 tomas', () {
      final horas = generarHorasDeToma(
        primeraToma: DateTime(2026, 10, 3, 7),
        cadaHoras: 12,
        dias: 5,
      );
      expect(horas.length, 10);
      expect(horas[1], DateTime(2026, 10, 3, 19));
    });

    test('cada 24 h por 3 días genera 3 tomas', () {
      final horas = generarHorasDeToma(
        primeraToma: DateTime(2026, 10, 3, 21),
        cadaHoras: 24,
        dias: 3,
      );
      expect(horas.length, 3);
    });

    test('cada 6 h por 1 día genera 4 tomas', () {
      final horas = generarHorasDeToma(
        primeraToma: DateTime(2026, 10, 3, 6),
        cadaHoras: 6,
        dias: 1,
      );
      expect(horas.length, 4);
    });

    test('cada 5 h por 1 día no excede las 24 h (4 tomas)', () {
      final horas = generarHorasDeToma(
        primeraToma: DateTime(2026, 10, 3, 8),
        cadaHoras: 5,
        dias: 1,
      );
      expect(horas.length, 4);
      expect(
        horas.last.isBefore(DateTime(2026, 10, 3, 8).add(const Duration(days: 1))),
        isTrue,
      );
    });

    test('rechaza valores inválidos', () {
      final base = DateTime(2026, 10, 3, 8);
      expect(() => generarHorasDeToma(primeraToma: base, cadaHoras: 0, dias: 3),
          throwsArgumentError);
      expect(() => generarHorasDeToma(primeraToma: base, cadaHoras: 25, dias: 3),
          throwsArgumentError);
      expect(() => generarHorasDeToma(primeraToma: base, cadaHoras: 8, dias: 0),
          throwsArgumentError);
    });
  });

  group('estadoDeToma', () {
    final toma = Toma(DateTime(2026, 10, 3, 8));

    test('pendiente antes de la hora y dentro de la tolerancia', () {
      expect(estadoDeToma(toma, DateTime(2026, 10, 3, 7)), EstadoToma.pendiente);
      expect(estadoDeToma(toma, DateTime(2026, 10, 3, 9, 59)), EstadoToma.pendiente);
    });

    test('pasa a no registrada después de 2 h sin marcar', () {
      expect(estadoDeToma(toma, DateTime(2026, 10, 3, 10, 1)),
          EstadoToma.noRegistrada);
    });

    test('tolerancia ajustable', () {
      expect(
        estadoDeToma(toma, DateTime(2026, 10, 3, 8, 31),
            tolerancia: const Duration(minutes: 30)),
        EstadoToma.noRegistrada,
      );
    });

    test('marcada como tomada se mantiene tomada', () {
      final marcada = toma.marcarTomada(DateTime(2026, 10, 3, 8, 5));
      expect(estadoDeToma(marcada, DateTime(2026, 10, 5)), EstadoToma.tomada);
    });
  });

  group('tratamientoTerminado', () {
    final horas = generarHorasDeToma(
      primeraToma: DateTime(2026, 10, 3, 8),
      cadaHoras: 8,
      dias: 7,
    );

    test('activo mientras faltan tomas', () {
      expect(tratamientoTerminado(horas, DateTime(2026, 10, 8)), isFalse);
    });

    test('terminado cuando pasó la última toma más la tolerancia', () {
      expect(tratamientoTerminado(horas, DateTime(2026, 10, 10, 2, 1)), isTrue);
    });
  });
}
