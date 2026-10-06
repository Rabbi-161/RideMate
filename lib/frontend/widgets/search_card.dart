import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/location.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';
import 'location_selector.dart';

class SearchCard extends StatefulWidget {
  final Location? initialFrom;
  final Location? initialTo;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int initialSeats;
  final Function(Location from, Location to, String date, String time, int seats) onSearch;
  final Function(Location from, Location to, String date, String time, int seats)? onRequestRide;
  final VoidCallback onSelectFrom;
  final VoidCallback onSelectTo;
  final VoidCallback? onClearFrom;
  final VoidCallback? onClearTo;
  final VoidCallback? onSwapLocations;
  final Function(DateTime date)? onDateChanged;
  final Function(TimeOfDay time)? onTimeChanged;
  final Function(int seats)? onSeatsChanged;

  const SearchCard({
    super.key,
    this.initialFrom,
    this.initialTo,
    this.initialDate,
    this.initialTime,
    this.initialSeats = 1,
    required this.onSearch,
    this.onRequestRide,
    required this.onSelectFrom,
    required this.onSelectTo,
    this.onClearFrom,
    this.onClearTo,
    this.onSwapLocations,
    this.onDateChanged,
    this.onTimeChanged,
    this.onSeatsChanged,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late int _seats;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _seats = widget.initialSeats;
  }

  @override
  void didUpdateWidget(SearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
    }
    if (widget.initialTime != oldWidget.initialTime) {
      _selectedTime = widget.initialTime;
    }
    if (widget.initialSeats != oldWidget.initialSeats) {
      _seats = widget.initialSeats;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime initialDate = _selectedDate ?? today;
    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 2, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged?.call(picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 17, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      widget.onTimeChanged?.call(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('d MMMM y').format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  bool _validateInputs() {
    if (widget.initialFrom == null) {
      _showError('Please select your departure location.');
      return false;
    }
    if (widget.initialTo == null) {
      _showError('Please select your destination location.');
      return false;
    }
    if (widget.initialFrom!.area.toLowerCase() == widget.initialTo!.area.toLowerCase()) {
      _showError('Departure and destination cannot be the same area.');
      return false;
    }
    if (_selectedDate == null) {
      _showError('Please select your travel date.');
      return false;
    }
    if (_selectedTime == null) {
      _showError('Please select your departure time.');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSearch() {
    if (!_validateInputs()) return;
    final dateStr = _formatDate(_selectedDate);
    final timeStr = _formatTime(_selectedTime);
    widget.onSearch(widget.initialFrom!, widget.initialTo!, dateStr, timeStr, _seats);
  }

  void _handleRequestRide() {
    if (!_validateInputs()) return;
    final dateStr = _formatDate(_selectedDate);
    final timeStr = _formatTime(_selectedTime);
    widget.onRequestRide?.call(widget.initialFrom!, widget.initialTo!, dateStr, timeStr, _seats);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDateText = _formatDate(_selectedDate);
    final formattedTimeText = _formatTime(_selectedTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FROM Location
          LocationSelector(
            label: 'WHERE ARE YOU LEAVING FROM?',
            selectedLocation: widget.initialFrom,
            placeholder: 'Select departure location',
            onTap: widget.onSelectFrom,
            onClear: widget.onClearFrom,
            icon: Icons.trip_origin_rounded,
            iconColor: AppTheme.primaryColor,
          ),

          // Divider with Location Swap
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(color: AppTheme.dividerColor, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onSwapLocations,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: AppTheme.dividerColor, thickness: 1),
                ),
              ],
            ),
          ),

          // 2. TO Location
          LocationSelector(
            label: 'WHERE ARE YOU GOING?',
            selectedLocation: widget.initialTo,
            placeholder: 'Select destination location',
            onTap: widget.onSelectTo,
            onClear: widget.onClearTo,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 14),

          // 3 & 4. DATE and TIME Row
          Row(
            children: [
              // 3. Date
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedDate != null
                            ? AppTheme.primaryColor.withValues(alpha: 0.5)
                            : AppTheme.borderColor,
                        width: _selectedDate != null ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'TRAVEL DATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDateText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedDate != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _selectedDate != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 4. Time
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTime != null
                            ? AppTheme.primaryColor.withValues(alpha: 0.5)
                            : AppTheme.borderColor,
                        width: _selectedTime != null ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'DEPARTURE TIME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedTimeText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTime != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _selectedTime != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. NUMBER OF SEATS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NUMBER OF SEATS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_seats ${_seats == 1 ? "seat" : "seats"}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      color: _seats > 1 ? AppTheme.primaryColor : AppTheme.textMuted,
                      visualDensity: VisualDensity.compact,
                      onPressed: _seats > 1
                          ? () {
                              setState(() => _seats--);
                              widget.onSeatsChanged?.call(_seats);
                            }
                          : null,
                    ),
                    Text(
                      '$_seats',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      color: _seats < 6 ? AppTheme.primaryColor : AppTheme.textMuted,
                      visualDensity: VisualDensity.compact,
                      onPressed: _seats < 6
                          ? () {
                              setState(() => _seats++);
                              widget.onSeatsChanged?.call(_seats);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. SEARCH RIDE Button
          CustomButton(
            text: 'SEARCH RIDE',
            icon: Icons.search_rounded,
            onPressed: _handleSearch,
            height: 50,
          ),
          const SizedBox(height: 12),

          // 7. REQUEST RIDE Button
          CustomButton(
            text: 'REQUEST RIDE',
            icon: Icons.add_circle_outline_rounded,
            isOutlined: true,
            onPressed: _handleRequestRide,
            height: 50,
          ),
        ],
      ),
    );
  }
}
