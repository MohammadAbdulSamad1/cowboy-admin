import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportModel {
  final String? id;
  final String reporterId;
  final String listingId;
  final String listingType; // 'Item', 'Business', 'Event'
  final String listingName;
  final String? listingImage;
  final String reason;
  final String? customReason;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminResponse;
  final String? adminId;

  ReportModel({
    this.id,
    required this.reporterId,
    required this.listingId,
    required this.listingType,
    required this.listingName,
    this.listingImage,
    required this.reason,
    this.customReason,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.adminResponse,
    this.adminId,
  });

  factory ReportModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReportModel(
      id: id,
      reporterId: data['reporterId'] ?? '',
      listingId: data['listingId'] ?? '',
      listingType: data['listingType'] ?? '',
      listingName: data['listingName'] ?? '',
      listingImage: data['listingImage'],
      reason: data['reason'] ?? '',
      customReason: data['customReason'],
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${data['status'] ?? 'pending'}',
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminResponse: data['adminResponse'],
      adminId: data['adminId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'listingId': listingId,
      'listingType': listingType,
      'listingName': listingName,
      'listingImage': listingImage,
      'reason': reason,
      'customReason': customReason,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminResponse': adminResponse,
      'adminId': adminId,
    };
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? listingId,
    String? listingType,
    String? listingName,
    String? listingImage,
    String? reason,
    String? customReason,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminResponse,
    String? adminId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      listingId: listingId ?? this.listingId,
      listingType: listingType ?? this.listingType,
      listingName: listingName ?? this.listingName,
      listingImage: listingImage ?? this.listingImage,
      reason: reason ?? this.reason,
      customReason: customReason ?? this.customReason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
    );
  }
}

enum ReportStatus { pending, inReview, completed, rejected, dismissed }

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return Color(0xFFF2B342);
      case ReportStatus.inReview:
        return Colors.blue;
      case ReportStatus.completed:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.pending:
        return Icons.schedule;
      case ReportStatus.inReview:
        return Icons.visibility;
      case ReportStatus.completed:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
      case ReportStatus.dismissed:
        return Icons.close;
    }
  }
}
