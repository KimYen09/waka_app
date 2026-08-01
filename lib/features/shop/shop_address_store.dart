import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ShopShippingAddress {
  const ShopShippingAddress({
    required this.recipient,
    required this.phone,
    required this.provinceCode,
    required this.province,
    required this.districtCode,
    required this.district,
    required this.wardCode,
    required this.ward,
    required this.streetAddress,
    this.label = 'Nhà riêng',
  });

  final String recipient;
  final String phone;
  final int provinceCode;
  final String province;
  final int districtCode;
  final String district;
  final int wardCode;
  final String ward;
  final String streetAddress;
  final String label;

  String get fullAddress => [
    streetAddress,
    ward,
    district,
    province,
  ].where((part) => part.trim().isNotEmpty).join(', ');

  Map<String, Object?> toJson() => {
    'recipient': recipient,
    'phone': phone,
    'provinceCode': provinceCode,
    'province': province,
    'districtCode': districtCode,
    'district': district,
    'wardCode': wardCode,
    'ward': ward,
    'streetAddress': streetAddress,
    'label': label,
  };

  factory ShopShippingAddress.fromJson(Map<String, Object?> json) {
    return ShopShippingAddress(
      recipient: json['recipient'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      provinceCode: (json['provinceCode'] as num?)?.toInt() ?? 0,
      province: json['province'] as String? ?? '',
      districtCode: (json['districtCode'] as num?)?.toInt() ?? 0,
      district: json['district'] as String? ?? '',
      wardCode: (json['wardCode'] as num?)?.toInt() ?? 0,
      ward: json['ward'] as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      label: json['label'] as String? ?? 'Nhà riêng',
    );
  }
}

abstract interface class ShopAddressStore {
  Future<ShopShippingAddress?> read(String ownerKey);
  Future<void> write(String ownerKey, ShopShippingAddress address);
}

class SecureShopAddressStore implements ShopAddressStore {
  const SecureShopAddressStore({this.storage = const FlutterSecureStorage()});

  final FlutterSecureStorage storage;

  String _key(String ownerKey) => 'waka_shipping_address_$ownerKey';

  @override
  Future<ShopShippingAddress?> read(String ownerKey) async {
    final value = await storage.read(key: _key(ownerKey));
    if (value == null || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) return null;
    return ShopShippingAddress.fromJson(decoded);
  }

  @override
  Future<void> write(String ownerKey, ShopShippingAddress address) {
    return storage.write(
      key: _key(ownerKey),
      value: jsonEncode(address.toJson()),
    );
  }
}
