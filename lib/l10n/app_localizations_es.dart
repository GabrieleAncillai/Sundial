// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Mane';

  @override
  String get today => 'Hoy';

  @override
  String get week => 'Semana';

  @override
  String get calendar => 'Calendario';

  @override
  String get settings => 'Ajustes';

  @override
  String get tags => 'Etiquetas';

  @override
  String get shifts => 'Turnos';

  @override
  String get about => 'Acerca de';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Añadir';

  @override
  String get edit => 'Editar';

  @override
  String get addEntry => 'Añadir una entrada';

  @override
  String get addSomething => 'Añadir algo';

  @override
  String get addOnThisDay => 'Añadir en este día';

  @override
  String get noPlanToday => 'No hay nada previsto para hoy.';

  @override
  String get noPlanTodayHint => 'No pasa nada. Si falta algo, añádelo ahora.';

  @override
  String get nothingPlanned => 'Nada previsto';

  @override
  String get shiftsSection => 'Turnos';

  @override
  String couldNotLoadDay(String error) {
    return 'No se pudo cargar tu día: $error';
  }

  @override
  String couldNotLoadShifts(String error) {
    return 'No se pudieron cargar los turnos: $error';
  }

  @override
  String get allDay => 'Todo el día';

  @override
  String get overnightSuffix => '(+1 día)';

  @override
  String get importedEvent => 'Evento de calendario importado';

  @override
  String get readOnlyNotice => 'Este evento viene de un calendario importado y es de solo lectura.';

  @override
  String get newEntry => 'Nueva entrada';

  @override
  String get editEntry => 'Editar entrada';

  @override
  String get titleQuestion => '¿Qué es?';

  @override
  String get titleRequired => 'Ponle un nombre';

  @override
  String get space => 'Espacio';

  @override
  String get type => 'Tipo';

  @override
  String get date => 'Fecha';

  @override
  String get starts => 'Empieza';

  @override
  String get ends => 'Termina';

  @override
  String get repeat => 'Repetir';

  @override
  String get repeatNever => 'Nunca';

  @override
  String get repeatDaily => 'Cada día';

  @override
  String get repeatWeekly => 'Cada semana';

  @override
  String get repeatMonthly => 'Cada mes';

  @override
  String get repeatYearly => 'Cada año';

  @override
  String get repeatAfterCompletion => 'Repetir al completar';

  @override
  String get repeatAfterCompletionSubtitle => 'Programa la siguiente desde el día que termines.';

  @override
  String get daysRequired => 'Usa un número de días mayor que cero.';

  @override
  String daysValue(int count) {
    return '$count días';
  }

  @override
  String get repeatAfterDaysLabel => 'Días entre tareas';

  @override
  String couldNotComplete(String error) {
    return 'No se pudo completar: $error';
  }

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get deleteEntryQuestion => '¿Eliminar esta entrada?';

  @override
  String get deleteEntryBody => 'Desaparecerá de tu plan.';

  @override
  String get endAfterStartError => 'La hora de fin tiene que ser posterior a la de inicio.';

  @override
  String couldNotSave(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String couldNotDelete(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String timesDefinedIn(String timeZone) {
    return 'Las horas se definen en $timeZone';
  }

  @override
  String markAsDone(String title) {
    return 'Marcar $title como hecho';
  }

  @override
  String get entryKindTask => 'Tarea';

  @override
  String get entryKindEvent => 'Evento';

  @override
  String get entryKindObligation => 'Obligación';

  @override
  String get entryKindDeadline => 'Plazo';

  @override
  String get recurrenceEveryDay => 'Cada día';

  @override
  String recurrenceEveryNDays(int count) {
    return 'Cada $count días';
  }

  @override
  String get recurrenceEveryWeek => 'Cada semana';

  @override
  String recurrenceEveryNWeeks(int count) {
    return 'Cada $count semanas';
  }

  @override
  String recurrenceOnDays(String days) {
    return 'Cada semana los $days';
  }

  @override
  String recurrenceEveryNWeeksOnDays(int count, String days) {
    return 'Cada $count semanas los $days';
  }

  @override
  String get recurrenceEveryMonth => 'Cada mes';

  @override
  String recurrenceEveryNMonths(int count) {
    return 'Cada $count meses';
  }

  @override
  String recurrenceEveryNMonthsOnDay(int count, int day) {
    return 'Cada $count meses el día $day';
  }

  @override
  String recurrenceOnDayOfMonth(int day) {
    return 'Cada mes el día $day';
  }

  @override
  String get recurrenceEveryYear => 'Cada año';

  @override
  String recurrenceEveryNYears(int count) {
    return 'Cada $count años';
  }

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousWeek => 'Semana anterior';

  @override
  String get nextWeek => 'Semana siguiente';

  @override
  String get jumpToToday => 'Ir a hoy';

  @override
  String get monthView => 'Mes';

  @override
  String get weekView => 'Semana';

  @override
  String get selectedDay => 'Día seleccionado';

  @override
  String get noEntriesOnDay => 'No hay nada previsto este día.';

  @override
  String calendarDaySemantics(String date, int count) {
    return '$date, $count elementos';
  }

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get weekStartsOn => 'La semana empieza en';

  @override
  String get weekStartMonday => 'Lunes';

  @override
  String get weekStartSaturday => 'Sábado';

  @override
  String get weekStartSunday => 'Domingo';

  @override
  String get hideWorkSpace => 'Ocultar el espacio Trabajo';

  @override
  String get hideWorkSpaceSubtitle => 'Mantén el trabajo fuera de Hoy, Semana y Calendario.';

  @override
  String get defaultReminders => 'Recordatorios por defecto';

  @override
  String get defaultRemindersSubtitle => 'Se marcan al añadir una entrada.';

  @override
  String get reminderAtTime => 'A la hora de inicio';

  @override
  String reminderMinutesBefore(int count) {
    return '$count minutos antes';
  }

  @override
  String reminderHoursBefore(int count) {
    return '$count horas antes';
  }

  @override
  String reminderDaysBefore(int count) {
    return '$count días antes';
  }

  @override
  String get reminders => 'Recordatorios';

  @override
  String get addReminder => 'Añadir un recordatorio';

  @override
  String get removeReminder => 'Quitar recordatorio';

  @override
  String get remindersOff => 'Sin recordatorios';

  @override
  String get notificationPermissionDenied =>
      'Las notificaciones están desactivadas. Actívalas en los ajustes del sistema para que te lleguen los recordatorios.';

  @override
  String couldNotLoadReminders(String error) {
    return 'No se pudieron cargar los recordatorios: $error';
  }

  @override
  String get remindersUnavailable => 'No se pudieron leer los recordatorios, así que se dejaron sin cambios.';

  @override
  String get dataAndBackup => 'Datos y copia de seguridad';

  @override
  String get exportBackup => 'Exportar una copia';

  @override
  String get exportBackupSubtitle => 'Guarda un archivo JSON con todos tus datos.';

  @override
  String get importBackup => 'Importar una copia';

  @override
  String get importBackupSubtitle => 'Sustituye tus datos con una copia validada.';

  @override
  String get importCalendar => 'Importar un calendario';

  @override
  String get importCalendarSubtitle =>
      'Lee un archivo .ics local. Los eventos importados son de solo lectura.';

  @override
  String get importCalendarSpace => 'Importar en';

  @override
  String importCalendarDone(int imported, int updated, int skipped) {
    return '$imported importados, $updated actualizados y $skipped duplicados o no compatibles omitidos.';
  }

  @override
  String get importCalendarEmpty => 'No se han encontrado eventos en este archivo.';

  @override
  String importCalendarFailed(String error) {
    return 'La importación del calendario ha fallado: $error';
  }

  @override
  String get importCompanion => 'Importar una exportación de una app compañera';

  @override
  String get importCompanionSubtitle => 'Lee un horario JSON local exportado por otra app.';

  @override
  String importCompanionDone(int imported, int skipped) {
    return '$imported eventos importados. $skipped duplicados o filas no válidas omitidos.';
  }

  @override
  String get importCompanionEmpty => 'No se han encontrado eventos en este archivo.';

  @override
  String importCompanionFailed(String error) {
    return 'La importación de la app compañera ha fallado: $error';
  }

  @override
  String backupExported(String path) {
    return 'Copia guardada en $path';
  }

  @override
  String get backupImported => 'Copia restaurada.';

  @override
  String backupFailed(String error) {
    return 'Error de copia: $error';
  }

  @override
  String get backupInvalid => 'Este archivo no es una copia válida de Mane.';

  @override
  String get backupFuture => 'Esta copia viene de una versión más reciente de Mane.';

  @override
  String get importConfirmTitle => '¿Sustituir tus datos?';

  @override
  String get importConfirmBody =>
      'La copia sustituye todas las entradas, turnos, etiquetas y ajustes de este dispositivo.';

  @override
  String get syncAndAgent => 'Sincronización y agente local';

  @override
  String get syncEnabled => 'Sincronización LAN';

  @override
  String get syncOffInfo =>
      'Desactivada por defecto. Solo automática entre dispositivos vinculados en la misma red.';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get mcpEnabled => 'Endpoint MCP local';

  @override
  String get mcpOffInfo =>
      'Desactivado por defecto. Permite que un agente de escritorio lea el plan por loopback.';

  @override
  String get aboutSubtitle => 'Licencia, créditos y versión';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get plannerSection => 'Planificador';

  @override
  String get librarySection => 'Biblioteca';

  @override
  String get privacySection => 'Privacidad';

  @override
  String get notSet => 'Ninguno';

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get basedOnGymMane => 'Basado en GymMane de InlitX';

  @override
  String get basedOnStreak => 'Basado en Streak de InlitX';

  @override
  String get basedOnMane => 'Basado en Mane por los colaboradores de Mane';

  @override
  String version(String version) {
    return 'Versión $version';
  }

  @override
  String get license => 'Licencia';

  @override
  String get licenseBody =>
      'Mane es software libre bajo GPL-3.0-only. Se ofrece sin garantía. Consulta LICENSE y ADDITIONAL_TERMS.md en el repositorio.';

  @override
  String get credits => 'Créditos';

  @override
  String get creditsBody =>
      'Creado tomando como referencia GymMane y Streak de InlitX. Basado en Mane por los colaboradores de Mane.';

  @override
  String get tagsManager => 'Etiquetas';

  @override
  String get homeInventory => 'Inventario del hogar';

  @override
  String get homeInventorySubtitle => 'Cantidades, lugares y niveles de reposición.';

  @override
  String get shoppingList => 'Lista de la compra';

  @override
  String get shoppingListSubtitle => 'Comida y productos para la casa.';

  @override
  String get addHomeItem => 'Añadir un artículo';

  @override
  String get editHomeItem => 'Editar artículo';

  @override
  String get itemName => 'Artículo';

  @override
  String get category => 'Categoría';

  @override
  String get location => 'Lugar';

  @override
  String get quantity => 'Cantidad';

  @override
  String get unit => 'Unidad';

  @override
  String get reorderLevel => 'Reponer en';

  @override
  String get lowStock => 'Queda poco';

  @override
  String get inStock => 'Hay existencias';

  @override
  String get addToShoppingList => 'Añadir a la compra';

  @override
  String get addLowStockItems => 'Añadir artículos bajos';

  @override
  String get noLowStock => 'Nada está por debajo de su nivel de reposición.';

  @override
  String get homeInventoryEmpty => 'Todavía no hay artículos en casa.';

  @override
  String get shoppingListEmpty => 'La lista de la compra está vacía.';

  @override
  String get addShoppingItem => 'Añadir a la lista';

  @override
  String get editShoppingItem => 'Editar artículo de la lista';

  @override
  String get linkedItem => 'Artículo del inventario';

  @override
  String get noLink => 'Ninguno';

  @override
  String get note => 'Nota';

  @override
  String get archiveItemQuestion => '¿Archivar este artículo?';

  @override
  String get archiveItemBody => 'Desaparece del inventario pero se conserva en las copias.';

  @override
  String shoppingProgress(int done, int total) {
    return '$done de $total comprados';
  }

  @override
  String get sleepWindow => 'Ventana de sueño';

  @override
  String get sleepWindowSubtitle =>
      'Un bloque suave desde el último compromiso de hoy hasta el primero de mañana.';

  @override
  String get sleepBuffers => 'Márgenes de sueño';

  @override
  String sleepBuffersSummary(int commute, int windDown, int wake) {
    return '$commute desplazamiento · $windDown relax · $wake despertar';
  }

  @override
  String get commute => 'Desplazamiento (minutos)';

  @override
  String get windDown => 'Relax (minutos)';

  @override
  String get wakeBuffer => 'Margen al despertar (minutos)';

  @override
  String sleepBedtime(String time) {
    return 'Acostarse sobre las $time';
  }

  @override
  String sleepWake(String time) {
    return 'Despertar sobre las $time';
  }

  @override
  String get sleepWarning => 'Este plan deja poco margen para dormir.';

  @override
  String get sleepNoEarlyStart => 'Mañana no hay un inicio temprano.';

  @override
  String minutesValue(int count) {
    return '$count min';
  }

  @override
  String get tagsManagerSubtitle => 'Separa trabajos en Trabajo y personas o grupos en Personal.';

  @override
  String get shiftPatterns => 'Patrones de turnos';

  @override
  String get shiftPatternsSubtitle => 'Ciclos, tramos por día y excepciones de fecha.';

  @override
  String get addTag => 'Añadir una etiqueta';

  @override
  String get editTag => 'Editar etiqueta';

  @override
  String get tagName => 'Nombre';

  @override
  String get tagColor => 'Color';

  @override
  String get tagSpace => 'Espacio';

  @override
  String get tagSpaceAny => 'Cualquier espacio';

  @override
  String get noTags => 'Todavía no hay etiquetas.';

  @override
  String get deleteTagQuestion => '¿Eliminar esta etiqueta?';

  @override
  String get deleteTagBody => 'Se quitará de todas las entradas que la usen.';

  @override
  String get tagNameRequired => 'Ponle un nombre a la etiqueta.';

  @override
  String get manageTags => 'Gestionar etiquetas';

  @override
  String get filterByTag => 'Filtrar por etiqueta';

  @override
  String get clearFilters => 'Quitar filtros';

  @override
  String get newShiftPattern => 'Nuevo patrón de turnos';

  @override
  String get editShiftPattern => 'Editar patrón de turnos';

  @override
  String get patternName => 'Nombre del patrón';

  @override
  String get cycleLength => 'Duración del ciclo';

  @override
  String cycleLengthValue(int count) {
    return '$count días';
  }

  @override
  String get anchorDate => 'Fecha de inicio';

  @override
  String get timeZone => 'Zona horaria';

  @override
  String cycleDay(int index) {
    return 'Día $index';
  }

  @override
  String get addSlot => 'Añadir un tramo';

  @override
  String get removeSlot => 'Quitar tramo';

  @override
  String get slotLabel => 'Etiqueta';

  @override
  String get startTime => 'Hora de inicio';

  @override
  String get endTime => 'Hora de fin';

  @override
  String get exceptions => 'Excepciones de fecha';

  @override
  String get addException => 'Añadir excepción';

  @override
  String get exceptionFree => 'Día libre';

  @override
  String get exceptionOverride => 'Sustituir turnos';

  @override
  String get exceptionExtra => 'Turno extra';

  @override
  String get exceptionNote => 'Nota';

  @override
  String get exceptionDate => 'Fecha';

  @override
  String get preview => 'Próximos 28 días';

  @override
  String get conflictsFound => 'Algunos turnos se solapan. Corrígelos antes de guardar.';

  @override
  String get noConflicts => 'No hay turnos solapados.';

  @override
  String get savePattern => 'Guardar patrón';

  @override
  String get deletePatternQuestion => '¿Eliminar este patrón de turnos?';

  @override
  String get deletePatternBody => 'Sus turnos desaparecerán del calendario.';

  @override
  String get invalidTimeZone => 'Usa una zona IANA como Europe/Madrid.';

  @override
  String get patternNameRequired => 'Ponle un nombre al patrón.';

  @override
  String get noShiftPatterns => 'Todavía no hay patrones de turnos.';

  @override
  String get noSlots => 'No hay tramos en este día.';

  @override
  String get noExceptions => 'Sin excepciones.';

  @override
  String get shiftChecklist => 'Lista del turno';

  @override
  String get shiftChecklistSubtitle => 'Tareas para marcar en cada turno de este patrón.';

  @override
  String get addChecklistItem => 'Añadir elemento';

  @override
  String get checklistItemLabel => 'Tarea de la lista';

  @override
  String get noChecklistItems => 'Todavía no hay tareas.';

  @override
  String checklistDone(int done, int total) {
    return '$done de $total hechas';
  }

  @override
  String get devices => 'Dispositivos';

  @override
  String get devicesSubtitle => 'Empareja tus propios dispositivos por la red local.';

  @override
  String get thisDevice => 'Este dispositivo';

  @override
  String get pairingIdentity => 'Identidad de emparejamiento';

  @override
  String get pairingIdentitySubtitle => 'Un usuario y PIN locales. Nunca salen de aquí.';

  @override
  String get username => 'Usuario';

  @override
  String get deviceName => 'Nombre del dispositivo';

  @override
  String get pin => 'PIN';

  @override
  String get pinHint => 'Al menos cuatro dígitos.';

  @override
  String get createIdentity => 'Crear identidad';

  @override
  String get identityCreated => 'Identidad de emparejamiento creada.';

  @override
  String get editIdentity => 'Editar identidad';

  @override
  String get changePin => 'Cambiar PIN';

  @override
  String get currentPin => 'PIN actual';

  @override
  String get newPin => 'PIN nuevo';

  @override
  String get identityRequired => 'Configura un usuario y un PIN antes de emparejar.';

  @override
  String get pairDevice => 'Emparejar un dispositivo';

  @override
  String get showPairingCode => 'Mostrar un código en este dispositivo';

  @override
  String get enterPairingCode => 'Introducir un código de otro dispositivo';

  @override
  String get pairingCode => 'Código de emparejamiento';

  @override
  String get pairingCodeHint => 'En el otro dispositivo, elige «Introducir un código» y escribe este código.';

  @override
  String get pairingExpires => 'Válido durante cinco minutos.';

  @override
  String get newCode => 'Código nuevo';

  @override
  String pairingSucceeded(String name) {
    return 'Emparejado con $name.';
  }

  @override
  String pairingFailed(String error) {
    return 'El emparejamiento ha fallado: $error';
  }

  @override
  String get discoveredOnNetwork => 'Encontrados en esta red';

  @override
  String get noDiscoveredDevices => 'Todavía no se han encontrado otros dispositivos Mane.';

  @override
  String get address => 'Dirección';

  @override
  String get port => 'Puerto';

  @override
  String get code => 'Código';

  @override
  String get pair => 'Emparejar';

  @override
  String get pairedDevices => 'Dispositivos emparejados';

  @override
  String get noPairedDevices => 'Todavía no hay dispositivos emparejados.';

  @override
  String get unpair => 'Desemparejar';

  @override
  String get unpairQuestion => '¿Desemparejar este dispositivo?';

  @override
  String get unpairBody => 'Desaparece de este dispositivo. El otro conserva su propia copia.';

  @override
  String lastSeen(String time) {
    return 'Visto por última vez $time';
  }

  @override
  String get neverReached => 'Todavía sin conexión';

  @override
  String get refreshDevices => 'Actualizar dispositivos';

  @override
  String remoteToday(int entries, int shifts) {
    return '$entries entradas y $shifts turnos hoy';
  }

  @override
  String remoteNextShift(String label) {
    return 'Próximo turno: $label';
  }

  @override
  String remoteShopping(int count) {
    return '$count artículos de compra pendientes';
  }

  @override
  String serverOnPort(int port) {
    return 'Servidor en el puerto $port';
  }

  @override
  String get serverOff => 'Servidor apagado';

  @override
  String get discoveryUnavailable =>
      'El descubrimiento en red no está disponible. Usa la dirección manualmente.';

  @override
  String get identityFingerprint => 'Huella del certificado';

  @override
  String get manualAddress => 'Dirección del dispositivo';

  @override
  String get hostHint => '192.168.1.20';

  @override
  String get mcpEndpoint => 'Endpoint MCP local';

  @override
  String get mcpEndpointSubtitle => 'Solo lectura por defecto, solo loopback y apagado salvo que lo actives.';

  @override
  String get mcpWriteTools => 'Permitir herramientas de escritura';

  @override
  String get mcpWriteToolsSubtitle => 'Deja que el agente local cree y complete entradas.';

  @override
  String get mcpToken => 'Token de acceso';

  @override
  String get mcpTokenHint => 'Úsalo como Bearer token. Al rotarlo se desconectan los agentes existentes.';

  @override
  String get rotateToken => 'Rotar token';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado.';

  @override
  String get mcpLoopbackHint => 'Escucha solo en 127.0.0.1. El agente debe ejecutarse en esta máquina.';

  @override
  String mcpRunning(int port) {
    return 'Escuchando en 127.0.0.1:$port';
  }

  @override
  String get mcpStopped => 'El endpoint MCP está apagado.';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Busca entradas, etiquetas y artículos del hogar';

  @override
  String get searchPrompt => 'Escribe un título, una nota, una etiqueta o un artículo del hogar.';

  @override
  String searchNoResults(String query) {
    return 'Nada coincide con «$query».';
  }

  @override
  String get searchEntries => 'Entradas';

  @override
  String get searchHomeItems => 'Artículos del hogar';

  @override
  String get nextShiftPrefix => 'Próximo: ';

  @override
  String get backupRestoredReminders => 'Los recordatorios se han vuelto a programar.';

  @override
  String get dayView => 'Día';

  @override
  String get shiftTags => 'Etiquetas del trabajo';

  @override
  String get commuteOverride => 'Tiempo de viaje propio';

  @override
  String get windDownOverride => 'Desconexión propia';

  @override
  String get inheritSleepBuffers => 'Déjalo vacío para usar los ajustes de sueño.';

  @override
  String get endDate => 'Termina el';

  @override
  String get multiDayHint => 'Deja la fecha final vacía para un solo día.';

  @override
  String get skipThisOccurrence => 'Omitir esta repetición';

  @override
  String get skippedOccurrences => 'Fechas omitidas';

  @override
  String get recurrenceExceptions => 'Excepciones';

  @override
  String get exportCalendar => 'Exportar calendario (.ics)';

  @override
  String get exportCalendarSubtitle => 'Comparte un archivo de solo lectura. Sin cuenta ni red.';

  @override
  String calendarExported(String path) {
    return 'Calendario exportado a $path';
  }

  @override
  String calendarExportFailed(String error) {
    return 'No se pudo exportar el calendario: $error';
  }

  @override
  String icsUpdated(int count) {
    return '$count actualizadas';
  }

  @override
  String get onlyThisOccurrence => 'Solo esta repetición';

  @override
  String get onlyThisOccurrenceSubtitle => 'Mantén la serie y cambia solo esta fecha.';

  @override
  String get singleDay => 'Un solo día';

  @override
  String get automaticBackups => 'Copias de seguridad locales automáticas';

  @override
  String get automaticBackupsSubtitle =>
      'Una copia JSON diaria en la carpeta de la app. Las copias antiguas se rotan.';

  @override
  String get keepBackups => 'Copias que conservar';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportCsvSubtitle => 'Entradas, compras o inventario.';

  @override
  String get importCsv => 'Importar CSV';

  @override
  String get importCsvSubtitle => 'Entradas, compras o inventario.';

  @override
  String get csvEntries => 'Entradas';

  @override
  String get csvShopping => 'Compras';

  @override
  String get csvInventory => 'Inventario';

  @override
  String csvExported(String path) {
    return 'CSV exportado a $path';
  }

  @override
  String csvExportFailed(String error) {
    return 'No se pudo exportar el CSV: $error';
  }

  @override
  String csvImportDone(int imported, int duplicates, int skipped) {
    return '$imported importadas, $duplicates duplicadas, $skipped omitidas';
  }

  @override
  String get csvImportEmpty => 'No hay filas que importar.';

  @override
  String get gymmaneImport => 'Horario de GymMane';

  @override
  String get gymmaneImportSubtitle =>
      'Bloques semanales de gimnasio de solo lectura desde un respaldo JSON de GymMane.';

  @override
  String gymmaneImportDone(int imported, int timed, int allDay, int skipped) {
    return '$imported bloques importados ($timed con hora, $allDay de todo el día), $skipped omitidos.';
  }

  @override
  String gymmaneImportFailed(String error) {
    return 'No se pudo importar GymMane: $error';
  }

  @override
  String get gymmaneImportEmpty => 'El respaldo no contiene un plan semanal.';

  @override
  String get purchaseHistory => 'Historial de compras';

  @override
  String get purchaseHistoryEmpty => 'Aún no hay compras registradas.';

  @override
  String get increaseQuantity => 'Aumentar cantidad';

  @override
  String get decreaseQuantity => 'Reducir cantidad';

  @override
  String lowStockCount(int count) {
    return '$count productos bajo el umbral';
  }

  @override
  String get maintenance => 'Mantenimiento';

  @override
  String get maintenanceSubtitle => 'Tareas que vencen después del último servicio.';

  @override
  String get maintenanceDue => 'Vence ahora';

  @override
  String get maintenanceUpcoming => 'Próximas';

  @override
  String get maintenanceNone => 'No hay tareas de mantenimiento.';

  @override
  String maintenanceDone(String date) {
    return 'Hecho. Próxima fecha: $date.';
  }

  @override
  String get clearChecked => 'Vaciar comprados';

  @override
  String get clearCheckedBody => '¿Eliminar todas las líneas compradas? No se puede deshacer.';

  @override
  String get shoppingToBuy => 'Por comprar';

  @override
  String get shoppingBought => 'Comprados';

  @override
  String get shoppingOther => 'Otros';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get complete => 'Completar';

  @override
  String get beforeStart => 'Antes del inicio';

  @override
  String get atTimeSection => 'A una hora';

  @override
  String get addTime => 'Añadir hora';

  @override
  String get customReminderHint =>
      'Una hora personalizada se envía el día de la repetición en la zona horaria del dispositivo.';

  @override
  String get workHours => 'Horario laboral';

  @override
  String get workHoursSubtitle =>
      'Oculta las tareas de Trabajo fuera de este horario. Las fechas límite siguen visibles.';

  @override
  String get quietHours => 'Horas de silencio';

  @override
  String get quietHoursSubtitle => 'Pausa las notificaciones durante esta franja.';

  @override
  String get mcpTools => 'Herramientas MCP';

  @override
  String get mcpToolsHint =>
      'Solo loopback. Initialize devuelve una cabecera Mcp-Session-Id; los clientes que aceptan text/event-stream reciben un mensaje SSE por llamada. Las escrituras siguen limitadas por el interruptor de arriba.';

  @override
  String get hoursWindow => 'Configurar franja';

  @override
  String get todayTab => 'Hoy';

  @override
  String get planTab => 'Plan';

  @override
  String get statsTab => 'Estadísticas';

  @override
  String get workTab => 'Trabajo';

  @override
  String get homeTab => 'Casa';

  @override
  String get personalTab => 'Personal';

  @override
  String get workSpace => 'Trabajo';

  @override
  String get homeSpace => 'Casa';

  @override
  String get personalSpace => 'Personal';

  @override
  String get jobs => 'Trabajos';

  @override
  String get homes => 'Casas';

  @override
  String get chooseHome => 'Elige una casa';

  @override
  String get peopleAndGroups => 'Personas y grupos';

  @override
  String get projectsSection => 'Proyectos';

  @override
  String get householdSection => 'Hogar';

  @override
  String get tasksSection => 'Tareas';

  @override
  String get habitsSection => 'Hábitos';

  @override
  String get gadgetsSection => 'Aparatos';

  @override
  String get inventorySection => 'Inventario';

  @override
  String get shoppingSection => 'Compra';

  @override
  String get newJob => 'Nuevo trabajo';

  @override
  String get editJob => 'Editar trabajo';

  @override
  String get newHome => 'Nueva casa';

  @override
  String get editHome => 'Editar casa';

  @override
  String get newPerson => 'Nueva persona o grupo';

  @override
  String get editPerson => 'Editar persona o grupo';

  @override
  String get newProject => 'Nuevo proyecto';

  @override
  String get editProject => 'Editar proyecto';

  @override
  String get jobName => 'Nombre del trabajo';

  @override
  String get homeName => 'Nombre de la casa';

  @override
  String get personName => 'Nombre';

  @override
  String get projectName => 'Nombre del proyecto';

  @override
  String get projectDescription => 'Descripción (opcional)';

  @override
  String get name => 'Nombre';

  @override
  String get descriptionOptional => 'Descripción (opcional)';

  @override
  String get icon => 'Icono';

  @override
  String get color => 'Color';

  @override
  String get image => 'Imagen';

  @override
  String get chooseIcon => 'Elegir un icono';

  @override
  String get searchIcons => 'Buscar iconos';

  @override
  String get noIconsFound => 'Ningún icono coincide con la búsqueda.';

  @override
  String get recommendedIcons => 'Sugeridos';

  @override
  String get allIcons => 'Todos los iconos';

  @override
  String get chooseImage => 'Elegir imagen';

  @override
  String get changeImage => 'Cambiar imagen';

  @override
  String get removeImage => 'Quitar imagen';

  @override
  String get createJob => 'Crear trabajo';

  @override
  String get createHome => 'Crear casa';

  @override
  String get createPerson => 'Crear persona o grupo';

  @override
  String get createProject => 'Crear proyecto';

  @override
  String get noJobs => 'Todavía no hay trabajos.';

  @override
  String get noJobsHint => 'Añade un trabajo para agrupar sus turnos, proyectos y tareas.';

  @override
  String get noHomes => 'Todavía no hay casas.';

  @override
  String get noHomesHint => 'Añade una casa para organizar inventario, aparatos y proyectos.';

  @override
  String get noPeople => 'Todavía no hay personas o grupos.';

  @override
  String get noPeopleHint => 'Usa proyectos para separar el tiempo con cada persona.';

  @override
  String get noProjects => 'Todavía no hay proyectos.';

  @override
  String get noProjectsHint => 'Los proyectos agrupan tareas afines sin crear otro espacio.';

  @override
  String get noHabits => 'Todavía no hay hábitos.';

  @override
  String get noHabitsHint => 'Añade un hábito para seguir una rutina personal.';

  @override
  String get noTasks => 'Aquí todavía no hay nada.';

  @override
  String get noTasksHint => 'Añade una tarea desde esta pantalla o desde Hoy.';

  @override
  String get upcomingTasks => 'Próximas';

  @override
  String get openTasks => 'Tareas abiertas';

  @override
  String get overdueTasks => 'Atrasadas';

  @override
  String get unscheduledTasks => 'Cuando quieras';

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
      zero: 'Sin tareas',
    );
    return '$_temp0';
  }

  @override
  String projectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proyectos',
      one: '1 proyecto',
      zero: 'Sin proyectos',
    );
    return '$_temp0';
  }

  @override
  String habitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos',
      one: '1 hábito',
      zero: 'Sin hábitos',
    );
    return '$_temp0';
  }

  @override
  String addTaskFor(String name) {
    return 'Añadir una tarea para $name';
  }

  @override
  String get jobSummary => 'Turnos, listas y proyectos de trabajo';

  @override
  String get homeSummary => 'Inventario, aparatos y proyectos del hogar';

  @override
  String get personalSummary => 'Proyectos, hábitos y gestiones personales';

  @override
  String get manageJobs => 'Gestionar trabajos';

  @override
  String get manageHomes => 'Gestionar casas';

  @override
  String get managePeople => 'Gestionar personas y grupos';

  @override
  String get noContextsYet => 'Crea uno para empezar.';

  @override
  String get addFirstContext => 'Crear el primero';

  @override
  String get shiftChecklists => 'Listas de turno';

  @override
  String checklistForDay(int day) {
    return 'Lista del día $day';
  }

  @override
  String get allDays => 'Todos los días';

  @override
  String get checklistItemHint => '¿Qué hay que hacer?';

  @override
  String get reorderChecklistHint => 'Arrastra para ordenar. Cada día puede tener una lista distinta.';

  @override
  String get addProject => 'Añadir proyecto';

  @override
  String get addHabit => 'Añadir hábito';

  @override
  String get editHabit => 'Editar hábito';

  @override
  String get habitName => 'Nombre del hábito';

  @override
  String get targetPerWeek => 'Objetivo semanal';

  @override
  String timesPerWeek(int count) {
    return '$count× por semana';
  }

  @override
  String streakDays(int count) {
    return 'Racha de $count días';
  }

  @override
  String streakWeeks(int count) {
    return 'Racha de $count semanas';
  }

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get markHabitDone => 'Marcar hecho';

  @override
  String get habitDone => 'Hecho hoy';

  @override
  String get addGadget => 'Añadir aparato';

  @override
  String get gadgetName => 'Nombre del aparato';

  @override
  String get maintenanceIntervalDays => 'Días entre revisiones';

  @override
  String nextDue(String date) {
    return 'Próxima: $date';
  }

  @override
  String deleteContextQuestion(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get deleteContextBody =>
      'Sus tareas siguen en tu plan pero pierden esta agrupación. Sus turnos, hábitos y vínculos del hogar se eliminan.';

  @override
  String get deleteProjectQuestion => '¿Eliminar este proyecto?';

  @override
  String get deleteProjectBody => 'Las tareas pierden este proyecto pero conservan su espacio y contexto.';

  @override
  String get listView => 'Lista';

  @override
  String get timelineView => 'Horario';

  @override
  String get progressToday => 'Progreso de hoy';

  @override
  String doneOfTotal(int done, int total) {
    return '$done de $total hechas';
  }

  @override
  String get allDone => 'Todo lo de hoy está hecho.';

  @override
  String tasksLeft(int count) {
    return 'Quedan $count para hoy';
  }

  @override
  String get clockIn => 'Fichar entrada';

  @override
  String get clockOut => 'Fichar salida';

  @override
  String get clockedIn => 'En marcha';

  @override
  String get trackedTime => 'Registrado';

  @override
  String trackedTimeValue(String duration) {
    return '$duration registrado';
  }

  @override
  String get deadline => 'Fecha límite';

  @override
  String dueIn(String time) {
    return 'Vence en $time';
  }

  @override
  String get overdue => 'Atrasada';

  @override
  String get anytime => 'Cuando sea';

  @override
  String get priority => 'Prioridad';

  @override
  String get priorityNone => 'Sin prioridad';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get completeTask => 'Completar tarea';

  @override
  String get reopenTask => 'Reabrir tarea';

  @override
  String get plan => 'Plan';

  @override
  String get month => 'Mes';

  @override
  String get day => 'Día';

  @override
  String get collapseCalendar => 'Contraer calendario';

  @override
  String get expandCalendar => 'Expandir calendario';

  @override
  String get desktopWeekHint =>
      'Arrastra los bloques para moverlos, el borde inferior para cambiar la duración o un hueco vacío para crear.';

  @override
  String createEntryAt(String time) {
    return 'Crear a las $time';
  }

  @override
  String get entryMoved => 'Entrada movida.';

  @override
  String couldNotMoveEntry(String error) {
    return 'No se pudo mover la entrada: $error';
  }

  @override
  String get stats => 'Estadísticas';

  @override
  String get overview => 'Resumen';

  @override
  String get completionRate => 'Tasa de finalización';

  @override
  String get tasksCompleted => 'Tareas completadas';

  @override
  String get overdueDeadlines => 'Fechas límite atrasadas';

  @override
  String get bySpace => 'Por espacio';

  @override
  String get byProject => 'Por proyecto';

  @override
  String get byDay => 'Por día';

  @override
  String get habitConsistency => 'Constancia de hábitos';

  @override
  String get rangeWeek => 'Semana';

  @override
  String get rangeMonth => 'Mes';

  @override
  String get rangeQuarter => 'Trimestre';

  @override
  String get rangeYear => 'Año';

  @override
  String get exportReport => 'Exportar informe';

  @override
  String get exportSummaryReport => 'Informe resumido (PDF)';

  @override
  String get exportDetailedReport => 'Informe detallado (PDF)';

  @override
  String get exportReportCsv => 'Informe (CSV)';

  @override
  String get reportExported => 'Informe guardado.';

  @override
  String reportFailed(String error) {
    return 'No se pudo exportar el informe: $error';
  }

  @override
  String get totalTracked => 'Total registrado';

  @override
  String get shareOfTotal => 'Porcentaje';

  @override
  String get noTrackedTime => 'No hay tiempo registrado en este rango.';

  @override
  String get completed => 'Completadas';

  @override
  String get openLabel => 'Abiertas';

  @override
  String get deadlineLoad => 'Fechas límite';

  @override
  String get settingsSearch => 'Buscar ajustes';

  @override
  String get generalSection => 'General';

  @override
  String get noSettingsFound => 'Ningún ajuste coincide con la búsqueda.';

  @override
  String get appearanceSubtitle => 'Tema, color, fondo y tamaño del texto';

  @override
  String get preferencesSubtitle => 'Idioma, fechas, horarios y recordatorios';

  @override
  String get dataSubtitle => 'Copias, calendarios, CSV y datos locales';

  @override
  String get onlineSubtitle => 'Emparejar dispositivos y ejecutar el MCP local';

  @override
  String get themeAero => 'Aero';

  @override
  String get colorScheme => 'Esquema de color';

  @override
  String get schemeSage => 'Salvia';

  @override
  String get schemeOcean => 'Océano';

  @override
  String get schemeSunset => 'Atardecer';

  @override
  String get schemeViolet => 'Violeta';

  @override
  String get schemeMono => 'Monocromo';

  @override
  String get background => 'Fondo';

  @override
  String get backgroundDots => 'Puntos';

  @override
  String get backgroundGrid => 'Cuadrícula';

  @override
  String get backgroundOled => 'Negro OLED';

  @override
  String get backgroundPlain => 'Liso';

  @override
  String get backgroundCustom => 'Personalizado';

  @override
  String get customBackgroundColor => 'Color personalizado';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String get textSmall => 'Pequeño';

  @override
  String get textDefault => 'Predeterminado';

  @override
  String get textLarge => 'Grande';

  @override
  String get textExtraLarge => 'Muy grande';

  @override
  String get navigationSide => 'Lado de la navegación';

  @override
  String get navLeft => 'Izquierda';

  @override
  String get navRight => 'Derecha';

  @override
  String get dateFormatLabel => 'Formato de fecha';

  @override
  String get dateFormatSystem => 'Sistema';

  @override
  String get dateFormatDmy => 'Día / mes / año';

  @override
  String get dateFormatMdy => 'Mes / día / año';

  @override
  String get dateFormatYmd => 'Año / mes / día';

  @override
  String get performanceMode => 'Modo rendimiento';

  @override
  String get performanceModeSubtitle => 'Reduce desenfoque, sombras y animaciones largas.';

  @override
  String get preferencesSection => 'Preferencias';

  @override
  String get dataSection => 'Datos y copias';

  @override
  String get onlineSection => 'Funciones en línea';

  @override
  String get onlineEnable => 'Activar funciones en línea';

  @override
  String get onlineEnableSubtitle =>
      'Sincronización LAN y MCP local. Desactivado por defecto; el planificador funciona sin ellas.';

  @override
  String get devicesAndSync => 'Dispositivos y sincronización';

  @override
  String get devicesAndSyncSubtitle => 'Busca dispositivos en esta red y empareja.';

  @override
  String get mcpServer => 'Servidor MCP';

  @override
  String get mcpPort => 'Puerto';

  @override
  String get mcpPortHint => 'Puerto local entre 1024 y 65535.';

  @override
  String get applyPort => 'Aplicar puerto';

  @override
  String portSaved(int port) {
    return 'El endpoint MCP ahora usa el puerto $port.';
  }

  @override
  String mcpPortUnavailable(int port) {
    return 'No se pudo usar el puerto $port. Puede que ya esté en uso.';
  }

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataSubtitle =>
      'Quita el plan, dispositivos, enlaces de copia y ajustes de este dispositivo.';

  @override
  String get deleteAllDataQuestion => '¿Eliminar todos los datos locales?';

  @override
  String get deleteAllDataBody => 'No se puede deshacer. Los archivos exportados no se borran.';

  @override
  String get dataDeleted => 'Datos locales eliminados.';

  @override
  String get nearbyDevices => 'Dispositivos cercanos';

  @override
  String get scanningDevices => 'Buscando dispositivos Mane en esta red…';

  @override
  String get noNearbyDevices =>
      'No se han encontrado dispositivos Mane. Asegúrate de que el otro dispositivo tiene las funciones en línea activadas.';

  @override
  String pairWithDevice(String name) {
    return 'Emparejar con $name';
  }

  @override
  String get pairCode => 'Código de emparejamiento';

  @override
  String get pairCodeHint => 'Introduce el código de seis dígitos del otro dispositivo.';

  @override
  String pairingWith(String name) {
    return 'Emparejando con $name';
  }

  @override
  String get syncExplainer =>
      'Mane encuentra tus otros dispositivos en la red local. El emparejamiento guarda una clave compartida una sola vez, así que cambiar de red o de IP no rompe el vínculo. La sincronización es de solo lectura y nunca sustituye tu plan local.';

  @override
  String get pairSuccess => 'Dispositivo emparejado.';

  @override
  String pairFailed(String error) {
    return 'No se pudo emparejar: $error';
  }

  @override
  String get timing => 'Horario';

  @override
  String get timingScheduled => 'Programada';

  @override
  String get timingClockIn => 'Fichar';

  @override
  String get timingDeadline => 'Fecha límite';

  @override
  String get timingAnytime => 'Cuando sea';

  @override
  String get timingScheduledHint => 'Empieza y termina a una hora fija.';

  @override
  String get timingClockInHint => 'Ficha al empezar; fichar salida pausa y conserva el tiempo registrado.';

  @override
  String get timingDeadlineHint => 'Puede hacerse en cualquier momento hasta la fecha límite.';

  @override
  String get timingAnytimeHint => 'Sin hora fija. Complétala cuando esté.';

  @override
  String get context => 'Trabajo, casa o persona';

  @override
  String get noContext => 'Sin trabajo, casa o persona';

  @override
  String get noProject => 'Sin proyecto';

  @override
  String get project => 'Proyecto';

  @override
  String get categories => 'Categorías';

  @override
  String get addCategory => 'Añadir categoría';

  @override
  String get editCategory => 'Editar categoría';

  @override
  String get categoryName => 'Nombre de la categoría';

  @override
  String get noCategories => 'Todavía no hay categorías.';

  @override
  String get stickerImage => 'Imagen';

  @override
  String get pickImage => 'Elegir una imagen';

  @override
  String get zoomHint => 'Pellizca o desplaza para ampliar y arrastra para encuadrar el cuadrado.';

  @override
  String get tolerance => 'Tolerancia del fondo';

  @override
  String get outline => 'Borde blanco de pegatina';

  @override
  String get outlineWidth => 'Grosor del borde';

  @override
  String get reset => 'Restablecer';

  @override
  String get useImage => 'Usar imagen';

  @override
  String get noImage => 'No hay imagen seleccionada.';

  @override
  String get imageError => 'No se pudo cargar la imagen.';

  @override
  String get choosePhotoOrIcon => 'Elige una foto o usa un icono';

  @override
  String get mediaHint => 'Recorta la imagen, quita un fondo liso y añade un borde blanco de pegatina.';

  @override
  String get soundSection => 'Sonido';

  @override
  String get interactionSounds => 'Sonidos de interacción';

  @override
  String get interactionSoundsSubtitle =>
      'Tonos breves y suaves al tocar, cambiar de pestaña, completar o fichar. Apagados por defecto.';

  @override
  String get soundPackLabel => 'Paquete de sonidos';

  @override
  String get soundPackSoft => 'Suave';

  @override
  String get soundPackAero => 'Aero';

  @override
  String get previewSound => 'Escuchar';

  @override
  String get alarmSounds => 'Sonidos de alarma';

  @override
  String get alarmSoundsSubtitle => 'Se usan en los recordatorios programados.';

  @override
  String get alarmSoundSoft => 'Suave';

  @override
  String get alarmSoundChime => 'Campana';

  @override
  String get alarmSoundBright => 'Brillante';

  @override
  String get timezoneSubtitle => 'Zona de las nuevas entradas con hora. Se muestra en la del dispositivo.';

  @override
  String get timezoneDevice => 'Zona del dispositivo';

  @override
  String get timezoneSearch => 'Buscar ciudad o región';

  @override
  String get timezoneUseDevice => 'Usar la zona del dispositivo';

  @override
  String get planningTimeZone => 'Zona de planificación';

  @override
  String get repeatEnds => 'Termina';

  @override
  String get repeatEndsNever => 'Nunca';

  @override
  String get repeatEndsOnDate => 'En una fecha';

  @override
  String get repeatEndsAfter => 'Después de';

  @override
  String repeatOccurrences(int count) {
    return '$count veces';
  }

  @override
  String get repeatEvery => 'Cada';

  @override
  String get repeatUnitDays => 'días';

  @override
  String get repeatUnitWeeks => 'semanas';

  @override
  String get repeatUnitMonths => 'meses';

  @override
  String get repeatUnitYears => 'años';

  @override
  String get repeatOnDays => 'Repetir los días';

  @override
  String get repeatMonthlyMode => 'Patrón mensual';

  @override
  String get repeatMonthlyDay => 'Día del mes';

  @override
  String get repeatMonthlyOrdinal => 'Posición del día';

  @override
  String get repeatOrdinalFirst => 'Primer';

  @override
  String get repeatOrdinalSecond => 'Segundo';

  @override
  String get repeatOrdinalThird => 'Tercer';

  @override
  String get repeatOrdinalFourth => 'Cuarto';

  @override
  String get repeatOrdinalLast => 'Último';

  @override
  String get repeatEndDate => 'Fecha de fin';

  @override
  String get repeatSummaryNever => 'No se repite';

  @override
  String get clearStart => 'Quitar la hora de inicio';

  @override
  String get clearEnd => 'Quitar la hora de fin';

  @override
  String get clearTime => 'Quitar la hora';

  @override
  String get noTime => 'Sin hora';

  @override
  String get pauseTask => 'Pausar';

  @override
  String get resumeTask => 'Reanudar';

  @override
  String get finishTask => 'Terminar';

  @override
  String get paused => 'En pausa';

  @override
  String sessionsTracked(int count) {
    return '$count sesiones';
  }

  @override
  String get sessionsTrackedOne => '1 sesión';

  @override
  String recurrenceUntil(Object date) {
    return 'hasta el $date';
  }
}
