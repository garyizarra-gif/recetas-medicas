import 'package:flutter_test/flutter_test.dart';
import 'package:recetas_medicas/datos/base_datos.dart';

Examen _e(double valor, {double? min, double? max, String nombre = 'Glucosa'}) =>
    Examen(
      nombre: nombre,
      valor: valor,
      unidad: 'mg/dL',
      fecha: DateTime(2026, 10, 3),
      refMin: min,
      refMax: max,
    );

void main() {
  group('Examen.posicion (rango que trae el informe)', () {
    test('dentro del rango, incluidos los extremos', () {
      expect(_e(95, min: 70, max: 100).posicion, PosicionRango.dentro);
      expect(_e(70, min: 70, max: 100).posicion, PosicionRango.dentro);
      expect(_e(100, min: 70, max: 100).posicion, PosicionRango.dentro);
    });

    test('por encima y por debajo', () {
      expect(_e(101, min: 70, max: 100).posicion, PosicionRango.alto);
      expect(_e(69.9, min: 70, max: 100).posicion, PosicionRango.bajo);
    });

    test('rango con solo máximo (ej. triglicéridos hasta 150)', () {
      expect(_e(140, max: 150).posicion, PosicionRango.dentro);
      expect(_e(180, max: 150).posicion, PosicionRango.alto);
    });

    test('rango con solo mínimo', () {
      expect(_e(50, min: 40).posicion, PosicionRango.dentro);
      expect(_e(35, min: 40).posicion, PosicionRango.bajo);
    });

    test('sin rango en el informe no se marca nada', () {
      expect(_e(95).posicion, isNull);
    });
  });

  test('clave agrupa el mismo examen sin importar mayúsculas ni espacios', () {
    expect(_e(1, nombre: ' Glucosa ').clave, _e(2, nombre: 'glucosa').clave);
  });
}
