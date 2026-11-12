const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];
const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

String dos(int n) => n.toString().padLeft(2, '0');

String fechaCorta(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

String horaTexto(DateTime d) => '${dos(d.hour)}:${dos(d.minute)}';

String fechaHora(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]} ${horaTexto(d)}';

String diaLargo(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]} ${d.year}';

/// 95.0 -> "95"; 187.5 -> "187.5"
String numTexto(double n) =>
    n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
