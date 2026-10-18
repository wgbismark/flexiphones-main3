import 'package:intl/intl.dart';

class Package {
  final int id;
  final int partnerId;
  final String price; // monthly price (string from API, e.g. "35.00")
  final int onnetAllocation; // in minutes (monthly)
  final int offnetAllocation; // in minutes (monthly)
  final int dataAllocation; // in MB (monthly)
  final int smsAllocation; // (monthly)
  final int validity; // in days
  final int isActive;
  final int isStandard;

  Package({
    required this.id,
    required this.partnerId,
    required this.price,
    required this.onnetAllocation,
    required this.offnetAllocation,
    required this.dataAllocation,
    required this.smsAllocation,
    required this.validity,
    required this.isActive,
    required this.isStandard,
  });

  /// ========== MONTHLY FORMATTERS ==========
  String get formattedDataAllocation {
    final formatter = NumberFormat.decimalPattern();
    if (dataAllocation < 2000) {
      return "${formatter.format(dataAllocation)} MB";
    } else {
      double gb = dataAllocation / 1024;
      return "${gb.toStringAsFixed(2)} GB";
    }
  }

  String formatMinutes(int minutes) {
    if (minutes < 60) {
      return "$minutes min";
    } else {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      if (mins == 0) {
        return "${hours}h";
      } else {
        return "${hours}h ${mins}m";
      }
    }
  }

  String get formattedOnnet => formatMinutes(onnetAllocation);
  String get formattedOffnet => formatMinutes(offnetAllocation);

  String get formattedSms {
    final formatter = NumberFormat.decimalPattern();
    if (smsAllocation < 2000) {
      return formatter.format(smsAllocation);
    } else {
      double kValue = smsAllocation / 1000;
      return "${kValue.toStringAsFixed(1)}K";
    }
  }

  /// ========== DAILY CALCULATIONS ==========
  int get dailyDataAllocation => (dataAllocation / validity).ceil();
  int get dailyOnnetAllocation => (onnetAllocation / validity).ceil();
  int get dailyOffnetAllocation => (offnetAllocation / validity).ceil();
  int get dailySmsAllocation => (smsAllocation / validity).ceil();

  /// Daily formatted values
  String get formattedDailyData {
    final formatter = NumberFormat.decimalPattern();
    if (dailyDataAllocation < 2000) {
      return "${formatter.format(dailyDataAllocation)} MB / day";
    } else {
      double gb = dailyDataAllocation / 1024;
      return "${gb.toStringAsFixed(2)} GB / day";
    }
  }

  String get formattedDailyOnnet =>
      "${formatMinutes(dailyOnnetAllocation)} / day";
  String get formattedDailyOffnet =>
      "${formatMinutes(dailyOffnetAllocation)} / day";

  String get formattedDailySms {
    final formatter = NumberFormat.decimalPattern();
    if (dailySmsAllocation < 2000) {
      return "${formatter.format(dailySmsAllocation)} / day";
    } else {
      double kValue = dailySmsAllocation / 1000;
      return "${kValue.toStringAsFixed(1)}K / day";
    }
  }

  /// ========== PRICE ==========
  double get monthlyPrice => double.tryParse(price) ?? 0.0;
  double get dailyPrice =>
      validity > 0 ? monthlyPrice / validity : monthlyPrice;

  String get formattedDailyPrice => "₵${dailyPrice.toStringAsFixed(2)} / day";

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'],
      partnerId: json['partner_id'],
      price: json['price'],
      onnetAllocation: json['onnet_allocation'],
      offnetAllocation: json['offnet_allocation'],
      dataAllocation: json['data_allocation'],
      smsAllocation: json['sms_allocation'],
      validity: (json['validity'] * 5).toInt(), // Convert months to days
      isActive: json['is_active'],
      isStandard: json['is_standard'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'price': price,
      'onnet_allocation': onnetAllocation,
      'offnet_allocation': offnetAllocation,
      'data_allocation': dataAllocation,
      'sms_allocation': smsAllocation,
      'validity': validity,
      'is_active': isActive,
      'is_standard': isStandard,
    };
  }
}
