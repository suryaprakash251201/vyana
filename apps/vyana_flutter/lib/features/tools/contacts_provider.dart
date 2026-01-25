import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vyana_flutter/core/api_client.dart';

part 'contacts_provider.g.dart';

class Contact {
  final String id;
  final String name;
  final String email;

  Contact({required this.id, required this.name, required this.email});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

@riverpod
Future<List<Contact>> contacts(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/tools/contacts');
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

  Future<void> addContact(String name, String email) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.post('/tools/contacts', body: {
        'name': name,
        'email': email,
      });

      if (result['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(contactsProvider);
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw e;
    }
  }
}
