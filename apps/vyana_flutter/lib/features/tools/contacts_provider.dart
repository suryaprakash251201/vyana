import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vyana_flutter/core/api_client.dart';

part 'contacts_provider.g.dart';

class Contact {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String? notes;
  final bool isFavorite;
  final List<String> labels;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.notes,
    this.isFavorite = false,
    this.labels = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      notes: json['notes'],
      isFavorite: json['is_favorite'] ?? false,
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'notes': notes,
      'is_favorite': isFavorite,
      'labels': labels,
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    bool? isFavorite,
    List<String>? labels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      labels: labels ?? this.labels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Check if contact has any contact info
  bool get hasContactInfo => email != null || phone != null;
}

/// Search query notifier
@riverpod
class ContactSearchQuery extends _$ContactSearchQuery {
  @override
  String build() => '';
  
  void update(String query) {
    state = query;
  }
  
  void clear() {
    state = '';
  }
}

/// Filter - favorites only notifier
@riverpod
class ContactFavoritesOnly extends _$ContactFavoritesOnly {
  @override
  bool build() => false;
  
  void toggle() {
    state = !state;
  }
  
  void set(bool value) {
    state = value;
  }
}

@riverpod
Future<List<Contact>> contacts(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final searchQuery = ref.watch(contactSearchQueryProvider);
  final favoritesOnly = ref.watch(contactFavoritesOnlyProvider);
  
  try {
    String url = '/tools/contacts';
    final params = <String>[];
    
    if (searchQuery.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(searchQuery)}');
    }
    if (favoritesOnly) {
      params.add('favorites_only=true');
    }
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    
    final response = await apiClient.get(url);
    return (response['contacts'] as List?)
            ?.map((c) => Contact.fromJson(c))
            .toList() ??
        [];
  } catch (e) {
    return [];
  }
}

@riverpod
class ContactController extends _$ContactController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> addContact({
    required String name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    bool isFavorite = false,
    List<String>? labels,
  }) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'name': name,
      };
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (company != null && company.isNotEmpty) body['company'] = company;
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;
      if (isFavorite) body['is_favorite'] = true;
      if (labels != null && labels.isNotEmpty) body['labels'] = labels;

      final result = await apiClient.post('/tools/contacts', body: body);

      if (result['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(contactsProvider);
      } else {
        throw Exception(result['error'] ?? 'Failed to add contact');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateContact({
    required String contactId,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    bool? isFavorite,
    List<String>? labels,
  }) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (company != null) body['company'] = company;
      if (notes != null) body['notes'] = notes;
      if (isFavorite != null) body['is_favorite'] = isFavorite;
      if (labels != null) body['labels'] = labels;

      final result = await apiClient.put('/tools/contacts/$contactId', body: body);

      if (result['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(contactsProvider);
      } else {
        throw Exception(result['error'] ?? 'Failed to update contact');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteContact(String contactId) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.delete('/tools/contacts/$contactId');

      if (result['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(contactsProvider);
      } else {
        throw Exception(result['error'] ?? 'Failed to delete contact');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleFavorite(String contactId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/tools/contacts/$contactId/favorite');
      ref.invalidate(contactsProvider);
    } catch (e) {
      rethrow;
    }
  }
}
