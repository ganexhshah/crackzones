import 'package:flutter/material.dart';

enum ShopCategory { gameTopups, giftCards, subscriptions }

enum DeliveryType { instant, minutes5to30, hours1to24 }

enum DeliveryMode { code, directTopup }

enum ProductInputType { playerId, server, region, email }

enum OrderStatus {
  pending,
  paidConfirmed,
  processing,
  completed,
  failed,
  refunded,
}

class ProductPack {
  final String id;
  final String label;
  final int price;

  const ProductPack({
    required this.id,
    required this.label,
    required this.price,
  });
}

class ProductInputField {
  final ProductInputType type;
  final String label;
  final TextInputType keyboardType;
  final List<String>? options;

  const ProductInputField({
    required this.type,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.options,
  });
}

class ShopProduct {
  final String id;
  final String name;
  final ShopCategory category;
  final String imageAsset;
  final String? badge;
  final DeliveryType deliveryType;
  final DeliveryMode deliveryMode;
  final double rating;
  final int soldCount;
  final int popularity;
  final String description;
  final List<String> rules;
  final List<ProductPack> packs;
  final List<ProductInputField> inputFields;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.imageAsset,
    this.badge,
    required this.deliveryType,
    required this.deliveryMode,
    required this.rating,
    required this.soldCount,
    required this.popularity,
    required this.description,
    required this.rules,
    required this.packs,
    required this.inputFields,
  });

  int get minPrice {
    if (packs.isEmpty) return 0;
    return packs.map((e) => e.price).reduce((a, b) => a < b ? a : b);
  }
}

class ShopOrder {
  final String orderId;
  final DateTime createdAt;
  final ShopProduct product;
  final ProductPack pack;
  final Map<String, String> inputs;
  final int fee;
  final int total;
  final String paymentMethod;
  final OrderStatus status;

  const ShopOrder({
    required this.orderId,
    required this.createdAt,
    required this.product,
    required this.pack,
    required this.inputs,
    required this.fee,
    required this.total,
    required this.paymentMethod,
    required this.status,
  });
}

String categoryLabel(ShopCategory category) {
  switch (category) {
    case ShopCategory.gameTopups:
      return 'Game Topups';
    case ShopCategory.giftCards:
      return 'Gift Cards';
    case ShopCategory.subscriptions:
      return 'Subscriptions';
  }
}

String deliveryTypeLabel(DeliveryType type) {
  switch (type) {
    case DeliveryType.instant:
      return 'Instant';
    case DeliveryType.minutes5to30:
      return '5-30 min';
    case DeliveryType.hours1to24:
      return '1-24 hr';
  }
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.paidConfirmed:
      return 'Paid/Confirmed';
    case OrderStatus.processing:
      return 'Processing';
    case OrderStatus.completed:
      return 'Completed';
    case OrderStatus.failed:
      return 'Failed';
    case OrderStatus.refunded:
      return 'Refunded';
  }
}
