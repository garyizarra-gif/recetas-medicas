# Resumen del proyecto: app de recetas y exámenes médicos

## 1. Objetivo
App Android, en español, que funciona como "enfermero de bolsillo" y archivo personal de salud.
- Evita que se pierdan las recetas (clínica, EsSalud, MINSA) y permite mostrarlas al médico si vuelve el mismo malestar.
- Recuerda a qué hora tomar cada medicamento y guarda el historial de tomas.
- Guarda exámenes (colesterol, glucosa, triglicéridos, etc.) y muestra su evolución.

## 2. Usuario
Personas comunes, cada una con sus propios datos, sin cuentas ni servidor central de datos. Producto que se ofrece a terceros.
Modelo de cobro: gratis con funciones básicas; las funciones con IA se pagan o tienen cupo (límite por decidir).
Primera versión solo Android. Respaldo y cambio de celular vía Google Drive del usuario.

## 3. Flujo
1. Registrar receta: foto (lectura con IA, opcional) o manual.
2. El usuario revisa y confirma lo leído (medicamento, dosis, frecuencia, duración, vía, fecha, clínica, diagnóstico).
3. Indicación que no es horario fijo: se pide completar a mano; si no, queda como nota sin aviso.
4. La app calcula horas y programa notificaciones (sin internet).
5. Notificación normal a la hora de toma; el usuario marca "tomado".
6. Pasado un tiempo (por defecto ~2 h, ajustable) la dosis sin marcar queda "no registrada".
7. Al terminar los días de la receta el tratamiento se cierra y los avisos se detienen.
8. Archivo de recetas y consultas ordenado por fecha y por malestar/diagnóstico.
9. Exámenes: foto o manual (nombre, valor, unidad, fecha, rango del informe); lista y gráfico de evolución; marca dentro/fuera de rango según el propio informe.

## 4. Reglas
- La app solo ejecuta la receta: sin recomendaciones médicas, efectos secundarios, interacciones ni alertas de dosis.
- Diccionario de medicamentos: solo "para qué sirve", generado por IA al consultar, con aviso "Información orientativa, confirma con tu médico". Requiere internet.
- Nada se programa sin confirmación del usuario.
- Ingreso manual por defecto; IA opcional y con consentimiento explícito (la foto sale del celular).
- Avisos y cálculo de horas no dependen de internet.
- Idioma: español. Marca visible: "Elaborado por SystemIA, cel. 965754455" con letras parpadeantes (preferible parpadeo suave).

## 5. Alcance por versión
- V1: solo horarios fijos ("cada X horas por Y días"); resto como nota.
- V2: "si hay dolor", dosis que cambian, uso continuo.

## 6. Criterios de calidad
- Peor fallo: que la alarma no suene. Debe dispararse con la app cerrada, el celular en reposo o reiniciado.
- Guiar al usuario para desactivar el ahorro de batería (Xiaomi, Samsung, Huawei).
- Horas calculadas coinciden con la receta.

## 7. Pendientes y riesgos
- Notificación normal es fácil de ignorar: considerar tono propio y vibración.
- Lectura de letra manuscrita y diccionario por IA pueden equivocarse: confirmación obligatoria y aviso.
- Privacidad y aspectos legales (datos personales y de salud en Perú, requisitos de Google Play).
- Límite gratis/pago y costo por lectura de IA: sin decidir.
- Falta un informe de laboratorio de ejemplo.
- La receta de ejemplo usada en el desarrollo (no incluida en el repositorio) es manuscrita y está girada; sirve como caso de prueba difícil.

## 8. Decisiones tomadas
- Tecnología: **Flutter** (Android primero, iPhone posible después).
- Se construye solo el **MVP (Etapas 0 y 1)** y se muestra antes de seguir con exámenes, Google Drive e IA.

## 9. Plan por etapas
- **Etapa 0:** entorno (Flutter, Android Studio, SDK de Android) y proyecto `recetas_medicas`.
- **Etapa 1 (MVP):** base de datos local (SQLite); registro manual de receta; pantalla de confirmación; cálculo de horas y notificaciones exactas sin internet que sobrevivan al reinicio, con tono propio y vibración; pantalla "Hoy" con botón "Tomado"; dosis sin marcar pasa a "no registrada" (2 h, ajustable); cierre automático del tratamiento; historial y archivo por fecha y diagnóstico; guía de ahorro de batería y permiso de alarmas exactas; indicaciones no soportadas como nota sin aviso; marca SystemIA con parpadeo suave; pruebas automáticas del cálculo de horas.
- **Etapa 2:** exámenes con rangos y gráficos; respaldo y restauración con Google Drive.
- **Etapa 3:** lectura de fotos con IA y diccionario "para qué sirve" (requiere servidor intermedio para proteger la clave de la IA); límites de uso.
- **Fuera de alcance por ahora:** iPhone, dosis que cambian, uso continuo, cobro.

## 10. Dónde quedamos (11-nov-2026)
- **Etapa 0 completa:** Flutter 3.47.9 en `C:\src\flutter`, Android Studio y SDK de Android 36 instalados; `flutter doctor` en verde para Android (el aviso de Visual Studio no aplica). Proyecto `recetas_medicas` creado en esta carpeta (solo Android).
- **Etapa 1 (MVP) escrita y compilada:** APK de depuración generado en `build/app/outputs/flutter-apk/app-debug.apk`. `flutter analyze` sin problemas y 12 pruebas del cálculo de horarios (`test/calculador_tomas_test.dart`) pasan.
  - `lib/dominio/`: cálculo de tomas, estados y cierre del tratamiento.
  - `lib/datos/base_datos.dart`: SQLite (recetas, medicamentos, tomas, ajustes).
  - `lib/servicios/avisos.dart`: notificaciones programadas exactas, sin internet; zona horaria America/Lima; se reprograman al abrir la app; receptor de reinicio en el manifiesto.
  - `lib/pantallas/`: Hoy, Recetas (archivo con búsqueda y detalle), Historial, Nueva receta con confirmación, Ajustes y ayuda (guía de batería, prueba de aviso en 1 minuto, tolerancia), marca SystemIA con parpadeo suave.
- **Foto de la receta (añadido):** se puede tomar con la cámara o elegir de la galería al registrar una receta; se guarda en la memoria privada de la app (`servicios/fotos.dart`), aparece como miniatura en el archivo y a pantalla completa con zoom en el detalle. La base de datos pasó a la versión 2 (columna `foto`, con migración). La lectura automática del texto de la foto sigue en la Etapa 3; por ahora el usuario completa los datos mirando la foto. La foto no se respalda todavía en Drive (Etapa 2). Se añadió `kotlin.incremental=false` en `android/gradle.properties` porque el proyecto está en `G:` y las librerías en `C:`.
- **Exámenes de laboratorio (adelantado desde la Etapa 2):** pestaña "Exámenes" con ingreso manual (nombre con sugerencias: glucosa, colesterol total/HDL/LDL, triglicéridos, hemoglobina, creatinina, ácido úrico; valor, unidad, fecha, rango del informe opcional, foto del informe opcional y nota). Lista agrupada por examen, detalle con gráfico de evolución (`pantallas/examenes.dart`) y marca "dentro/por debajo/por encima del rango del informe" (sin recomendaciones). Base de datos versión 3 (tabla `examenes`, con migración). Pruebas del rango en `test/examen_test.dart` (18 pruebas en total, todas pasan). Falta: lectura automática de la foto con IA (Etapa 3) y respaldo en Drive (Etapa 2).
- **NO probado en un aparato.** No hay celular conectado ni emulador, así que no está verificado que los avisos suenen, que sobrevivan al reinicio ni cómo se ve la interfaz. La prioridad número uno (que la alarma suene) sigue sin comprobarse.
- Configuración Android: `compileSdk = 37` y `android.suppressUnsupportedCompileSdk=37` (las dependencias lo exigen); desugaring activado. Plataformas Android 36 y 37.0 instaladas.
- Notas: `C:\src\flutter\bin` no está en el PATH de Windows. Sin tono propio todavía (usa el sonido por defecto con importancia máxima y vibración larga). No hay pruebas de pantallas ni de base de datos.

## 11. Siguiente acción
1. **Probar en un celular Android real:** activar opciones de desarrollador y depuración USB, conectarlo, y ejecutar `flutter run`; o instalar el APK. Verificar: aviso de prueba con la app cerrada y pantalla bloqueada, receta de ejemplo, reinicio del celular, "Tomado", paso a "no registrada".
2. Corregir lo que falle en esa prueba (especialmente avisos en celulares con ahorro de batería agresivo).
3. Decidir tono propio para los avisos y generar un APK de lanzamiento firmado cuando esté validado.
4. Mostrar el MVP antes de la Etapa 2 (exámenes, Google Drive).
5. Pendiente tuyo cuando quieras: un informe de laboratorio de ejemplo para la Etapa 2.
