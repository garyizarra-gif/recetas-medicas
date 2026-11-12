/// Estado de una toma programada.
enum EstadoToma { pendiente, tomada, noRegistrada }

/// Una toma programada de un medicamento.
class Toma {
  final DateTime hora;
  final DateTime? horaRegistro; // cuándo marcó "tomado", si lo hizo
  const Toma(this.hora, {this.horaRegistro});

  Toma marcarTomada(DateTime ahora) => Toma(hora, horaRegistro: ahora);
}

/// Tolerancia por defecto antes de pasar una dosis a "no registrada".
const Duration toleranciaPorDefecto = Duration(hours: 2);

/// Genera las horas de toma para un horario fijo: "cada [cadaHoras] horas
/// por [dias] días", comenzando en [primeraToma].
///
/// Ejemplo: cada 8 h por 7 días desde las 08:00 => 21 tomas
/// (08:00, 16:00, 00:00, ...). El tratamiento termina en [dias] x 24 horas
/// desde la primera toma; no se programa ninguna toma fuera de ese lapso.
List<DateTime> generarHorasDeToma({
  required DateTime primeraToma,
  required int cadaHoras,
  required int dias,
}) {
  if (cadaHoras <= 0 || cadaHoras > 24) {
    throw ArgumentError.value(cadaHoras, 'cadaHoras', 'Debe estar entre 1 y 24');
  }
  if (dias <= 0) {
    throw ArgumentError.value(dias, 'dias', 'Debe ser mayor que 0');
  }
  final total = (dias * 24) ~/ cadaHoras;
  return List.generate(
    total,
    (i) => primeraToma.add(Duration(hours: cadaHoras * i)),
  );
}

/// Estado de una toma en el instante [ahora].
EstadoToma estadoDeToma(
  Toma toma,
  DateTime ahora, {
  Duration tolerancia = toleranciaPorDefecto,
}) {
  if (toma.horaRegistro != null) return EstadoToma.tomada;
  if (ahora.isAfter(toma.hora.add(tolerancia))) return EstadoToma.noRegistrada;
  return EstadoToma.pendiente;
}

/// El tratamiento termina cuando pasó la última toma (+ tolerancia).
bool tratamientoTerminado(
  List<DateTime> horas,
  DateTime ahora, {
  Duration tolerancia = toleranciaPorDefecto,
}) {
  if (horas.isEmpty) return true;
  return ahora.isAfter(horas.last.add(tolerancia));
}
