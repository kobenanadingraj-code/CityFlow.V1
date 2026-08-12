class WeatherEvent {
  final int id;
  final String zone;
  final String type; // normal | pluie_moderee | pluie_forte
  final String condition; // ensoleille | nuageux | pluvieux | orageux
  final double temperature;
  final double intensite;
  final DateTime timestamp;

  WeatherEvent({
    required this.id,
    required this.zone,
    required this.type,
    required this.condition,
    required this.temperature,
    required this.intensite,
    required this.timestamp,
  });

  factory WeatherEvent.fromJson(Map<String, dynamic> json) => WeatherEvent(
        id: json['id'] as int,
        zone: json['zone'] as String,
        type: json['type'] as String,
        condition: json['condition'] as String? ?? 'ensoleille',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 27.0,
        intensite: (json['intensite'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  static const conditionLabels = {
    'ensoleille': 'Ensoleillé',
    'nuageux': 'Nuageux',
    'pluvieux': 'Pluvieux',
    'orageux': 'Orageux',
  };

  String get conditionLabel => conditionLabels[condition] ?? condition;
  int get temperatureRounded => temperature.round();
}
