import 'dart:convert';

import 'package:http/http.dart' as http;

class ShopAdministrativeUnit {
  const ShopAdministrativeUnit({required this.code, required this.name});

  final int code;
  final String name;
}

abstract interface class ShopLocationRepository {
  Future<List<ShopAdministrativeUnit>> getProvinces();
  Future<List<ShopAdministrativeUnit>> getDistricts(int provinceCode);
  Future<List<ShopAdministrativeUnit>> getWards(int districtCode);
}

class ShopLocationService implements ShopLocationRepository {
  const ShopLocationService();

  static const _baseUrl = 'https://provinces.open-api.vn/api/v1';

  @override
  Future<List<ShopAdministrativeUnit>> getProvinces() {
    return _getUnits(Uri.parse('$_baseUrl/p/'));
  }

  @override
  Future<List<ShopAdministrativeUnit>> getDistricts(int provinceCode) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/p/$provinceCode?depth=2'),
    );
    final data = _decode(response);
    return _readUnits(data['districts']);
  }

  @override
  Future<List<ShopAdministrativeUnit>> getWards(int districtCode) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/d/$districtCode?depth=2'),
    );
    final data = _decode(response);
    return _readUnits(data['wards']);
  }

  Future<List<ShopAdministrativeUnit>> _getUnits(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Không tải được danh mục địa chỉ.');
    }
    return _readUnits(jsonDecode(response.body));
  }

  Map<String, Object?> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Không tải được danh mục địa chỉ.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw StateError('Dữ liệu địa chỉ không đúng định dạng.');
    }
    return decoded;
  }

  List<ShopAdministrativeUnit> _readUnits(Object? value) {
    if (value is! List<Object?>) return const [];
    return value
        .whereType<Map<String, Object?>>()
        .map((item) {
          return ShopAdministrativeUnit(
            code: (item['code'] as num?)?.toInt() ?? 0,
            name: item['name'] as String? ?? '',
          );
        })
        .where((item) => item.code > 0 && item.name.isNotEmpty)
        .toList();
  }
}
