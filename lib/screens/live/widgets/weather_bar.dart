import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/weather.dart';

class WeatherBar extends StatelessWidget {
  final Weather weather;

  const WeatherBar({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: F1Colors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _WeatherItem(
            icon: Icons.thermostat,
            label: '${weather.airTemperature.toStringAsFixed(1)}°C',
            tooltip: '기온',
          ),
          _WeatherItem(
            icon: Icons.sports_motorsports,
            label: '${weather.trackTemperature.toStringAsFixed(1)}°C',
            tooltip: '노면 온도',
          ),
          _WeatherItem(
            icon: Icons.water_drop,
            label: '${weather.humidity.toStringAsFixed(0)}%',
            tooltip: '습도',
          ),
          _WeatherItem(
            icon: weather.rainfall > 0 ? Icons.umbrella : Icons.wb_sunny,
            label: weather.rainfall > 0 ? '비' : '맑음',
            tooltip: '날씨',
          ),
          _WeatherItem(
            icon: Icons.air,
            label: '${weather.windSpeed.toStringAsFixed(1)}m/s',
            tooltip: '풍속',
          ),
        ],
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _WeatherItem({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: F1Colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: F1Colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
