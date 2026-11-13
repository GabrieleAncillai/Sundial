import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/app_sheet.dart';
import '../widgets/mane_search_field.dart';
import '../widgets/pressable.dart';

/// Opens a searchable IANA time-zone picker.
///
/// Returns `null` when dismissed, an empty string for the device zone, or the
/// chosen IANA zone id. Every label is supplied by the caller so the sheet can
/// be reused from settings and both entry editors without hardcoded copy.
Future<String?> showTimeZonePicker(
  BuildContext context, {
  required String selected,
  required String title,
  required String searchHint,
  required String deviceLabel,
  required String deviceZone,
  bool allowDevice = true,
  String emptyText = '—',
}) {
  _ensureTimeZoneDatabase();
  return showAppSheet<String>(
    context: context,
    builder: (context) => _TimeZonePickerSheet(
      selected: selected,
      title: title,
      searchHint: searchHint,
      deviceLabel: deviceLabel,
      deviceZone: deviceZone,
      allowDevice: allowDevice,
      emptyText: emptyText,
    ),
  );
}

/// The sheet is usable from tests and deep links that may open before `main()`
/// has loaded the embedded database.
void _ensureTimeZoneDatabase() {
  if (tz.timeZoneDatabase.locations.isEmpty) tzdata.initializeTimeZones();
}

class _TimeZonePickerSheet extends StatefulWidget {
  const _TimeZonePickerSheet({
    required this.selected,
    required this.title,
    required this.searchHint,
    required this.deviceLabel,
    required this.deviceZone,
    required this.allowDevice,
    required this.emptyText,
  });

  final String selected;
  final String title;
  final String searchHint;
  final String deviceLabel;
  final String deviceZone;
  final bool allowDevice;
  final String emptyText;

  @override
  State<_TimeZonePickerSheet> createState() => _TimeZonePickerSheetState();
}

class _TimeZonePickerSheetState extends State<_TimeZonePickerSheet> {
  final _searchController = TextEditingController();
  late final _ZoneOption _device;
  late final List<_ZoneOption> _zones;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _device = _deviceOption(now);
    _zones = _readZones(now);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _ZoneOption _deviceOption(DateTime now) {
    final local = tz.TZDateTime.from(now, _locationOrUtc(widget.deviceZone));
    final offset = _offsetLabel(local.timeZoneOffset);
    return _ZoneOption(
      id: widget.deviceZone,
      city: widget.deviceZone,
      region: '',
      offset: offset,
      localTime: local,
      searchText: '${widget.deviceLabel} ${widget.deviceZone} $offset'.toLowerCase(),
    );
  }

  List<_ZoneOption> _readZones(DateTime now) {
    final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
    final zones = <_ZoneOption>[];
    for (final id in names) {
      final local = tz.TZDateTime.from(now, tz.timeZoneDatabase.locations[id]!);
      final parts = id.split('/');
      final city = parts.last.replaceAll('_', ' ');
      final region = parts.length > 1
          ? parts.sublist(0, parts.length - 1).join('/').replaceAll('_', ' ')
          : '';
      final offset = _offsetLabel(local.timeZoneOffset);
      zones.add(
        _ZoneOption(
          id: id,
          city: city,
          region: region,
          offset: offset,
          localTime: local,
          searchText: '$id $city $region $offset'.toLowerCase(),
        ),
      );
    }
    return zones;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? _zones
        : _zones.where((zone) => zone.matches(query)).toList(growable: false);
    final showDevice = widget.allowDevice && (query.isEmpty || _device.matches(query));
    final timeFormat = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final deviceSubtitle = widget.deviceZone.isEmpty
        ? _device.offset
        : '${widget.deviceZone} · ${_device.offset}';

    return AppSheet(
      title: widget.title,
      children: [
        ManeSearchField(
          controller: _searchController,
          hint: widget.searchHint,
          autofocus: true,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        if (showDevice) ...[
          _ZoneRow(
            title: widget.deviceLabel,
            subtitle: deviceSubtitle,
            time: timeFormat.format(_device.localTime),
            selected: widget.selected.isEmpty,
            onTap: () => Navigator.of(context).pop(''),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: matches.isEmpty
              ? Center(
                  child: Text(widget.emptyText, style: ManeType.body(13, color: c.textSecondary)),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final zone = matches[index];
                    return _ZoneRow(
                      title: zone.city,
                      subtitle: zone.subtitle,
                      time: timeFormat.format(zone.localTime),
                      selected: zone.id == widget.selected,
                      onTap: () => Navigator.of(context).pop(zone.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ZoneOption {
  const _ZoneOption({
    required this.id,
    required this.city,
    required this.region,
    required this.offset,
    required this.localTime,
    required this.searchText,
  });

  final String id;
  final String city;
  final String region;
  final String offset;
  final tz.TZDateTime localTime;
  final String searchText;

  String get subtitle => region.isEmpty ? offset : '$region · $offset';

  bool matches(String query) => searchText.contains(query);
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      semanticLabel: '$title, $subtitle, $time',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? c.accent.withValues(alpha: 0.5) : c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ManeType.title(14.5, color: c.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ManeType.body(12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(time, style: ManeType.label(13, color: c.textSecondary)),
            if (selected) ...[const SizedBox(width: 8), Icon(Icons.check_rounded, size: 18, color: c.accent)],
          ],
        ),
      ),
    );
  }
}

tz.Location _locationOrUtc(String timeZoneId) {
  try {
    return tz.getLocation(timeZoneId);
  } on tz.LocationNotFoundException {
    return tz.UTC;
  }
}

/// A fixed-width `UTC±HH:MM` label, e.g. `UTC+01:00` or `UTC-03:30`.
String _offsetLabel(Duration offset) {
  final minutes = offset.inMinutes.abs();
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final remainder = (minutes % 60).toString().padLeft(2, '0');
  return 'UTC${offset.isNegative ? '-' : '+'}$hours:$remainder';
}
