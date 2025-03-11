class Battery {
  final String macId;
  double? soc;

  Battery({
    required this.macId,
    this.soc,
  });

  factory Battery.fromJson(Map<String, dynamic> json) {
    return Battery(
      macId: json['mac_id'],
    );
  }
}