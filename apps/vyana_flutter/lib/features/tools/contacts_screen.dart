import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/tools/contacts_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(contactsProvider);
    final favoritesOnly = ref.watch(contactFavoritesOnlyProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search contacts...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(contactSearchQueryProvider.notifier).update(value);
                },
              )
            : const Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(contactSearchQueryProvider.notifier).clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              favoritesOnly ? Icons.star : Icons.star_border,
              color: favoritesOnly ? Colors.amber : null,
            ),
            tooltip: 'Show favorites only',
            onPressed: () {
              ref.read(contactFavoritesOnlyProvider.notifier).toggle();
            },
          ),
          IconButton(
            onPressed: () => ref.invalidate(contactsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return _buildEmptyState(theme);
          }
          
          // Group contacts by first letter
          final grouped = _groupContacts(contacts);
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return _buildContactGroup(context, entry.key, entry.value, theme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const Gap(16),
              Text('Error loading contacts', style: TextStyle(color: Colors.grey.shade600)),
              const Gap(8),
              TextButton(
                onPressed: () => ref.invalidate(contactsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppColors.primaryPurple,
            ),
          ),
          const Gap(24),
          Text(
            'No contacts yet',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Text(
            'Add your contacts to keep them synced\nacross all your devices',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Gap(24),
          FilledButton.icon(
            onPressed: () => _showContactDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  Map<String, List<Contact>> _groupContacts(List<Contact> contacts) {
    final grouped = <String, List<Contact>>{};
    
    // Favorites first
    final favorites = contacts.where((c) => c.isFavorite).toList();
    if (favorites.isNotEmpty) {
      grouped['★ Favorites'] = favorites;
    }
    
    // Then alphabetically
    for (final contact in contacts.where((c) => !c.isFavorite)) {
      final letter = contact.name.isNotEmpty 
          ? contact.name[0].toUpperCase() 
          : '#';
      grouped.putIfAbsent(letter, () => []).add(contact);
    }
    
    return grouped;
  }

  Widget _buildContactGroup(BuildContext context, String letter, List<Contact> contacts, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            letter,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...contacts.map((contact) => _buildContactTile(context, contact, theme)),
      ],
    );
  }

  Widget _buildContactTile(BuildContext context, Contact contact, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Hero(
        tag: 'contact_avatar_${contact.id}',
        child: CircleAvatar(
          radius: 24,
          backgroundColor: _getAvatarColor(contact.name),
          child: Text(
            contact.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.name,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (contact.isFavorite)
            const Icon(Icons.star, size: 18, color: Colors.amber),
        ],
      ),
      subtitle: contact.company != null
          ? Text(contact.company!, style: TextStyle(color: Colors.grey.shade600))
          : contact.email != null
              ? Text(contact.email!, style: TextStyle(color: Colors.grey.shade600))
              : contact.phone != null
                  ? Text(contact.phone!, style: TextStyle(color: Colors.grey.shade600))
                  : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contact.phone != null)
            IconButton(
              icon: const Icon(Icons.phone, size: 20),
              color: Colors.green,
              onPressed: () => _makePhoneCall(contact.phone!),
              tooltip: 'Call',
            ),
          if (contact.email != null)
            IconButton(
              icon: const Icon(Icons.email, size: 20),
              color: AppColors.primaryPurple,
              onPressed: () => _sendEmail(contact.email!),
              tooltip: 'Email',
            ),
        ],
      ),
      onTap: () => _showContactDetails(context, contact),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactDetailSheet(
        contact: contact,
        onEdit: () {
          Navigator.pop(context);
          _showContactDialog(context, ref, contact: contact);
        },
        onDelete: () async {
          Navigator.pop(context);
          final confirm = await _showDeleteConfirmation(context, contact.name);
          if (confirm == true) {
            try {
              await ref.read(contactControllerProvider.notifier).deleteContact(contact.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${contact.name} deleted')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          }
        },
        onToggleFavorite: () async {
          await ref.read(contactControllerProvider.notifier).toggleFavorite(contact.id);
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context, WidgetRef ref, {Contact? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactFormSheet(
        contact: contact,
        onSave: (name, email, phone, company, notes, isFavorite) async {
          try {
            if (contact != null) {
              await ref.read(contactControllerProvider.notifier).updateContact(
                contactId: contact.id,
                name: name,
                email: email,
                phone: phone,
                company: company,
                notes: notes,
                isFavorite: isFavorite,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name updated')),
                );
              }
            } else {
              await ref.read(contactControllerProvider.notifier).addContact(
                name: name,
                email: email,
                phone: phone,
                company: company,
                notes: notes,
                isFavorite: isFavorite,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name added')),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

class _ContactDetailSheet extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _ContactDetailSheet({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),
          
          // Avatar and name
          Hero(
            tag: 'contact_avatar_${contact.id}',
            child: CircleAvatar(
              radius: 48,
              backgroundColor: _getAvatarColor(contact.name),
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                contact.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (contact.isFavorite) ...[
                const Gap(8),
                const Icon(Icons.star, color: Colors.amber),
              ],
            ],
          ),
          if (contact.company != null) ...[
            const Gap(4),
            Text(
              contact.company!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
          const Gap(24),
          
          // Quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (contact.phone != null)
                _QuickAction(
                  icon: Icons.phone,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () => _makePhoneCall(contact.phone!),
                ),
              if (contact.email != null)
                _QuickAction(
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.blue,
                  onTap: () => _sendEmail(contact.email!),
                ),
              if (contact.phone != null)
                _QuickAction(
                  icon: Icons.message,
                  label: 'Message',
                  color: Colors.orange,
                  onTap: () => _sendSms(contact.phone!),
                ),
            ],
          ),
          const Gap(24),
          
          // Contact info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (contact.phone != null)
                  _InfoTile(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: contact.phone!,
                    onCopy: () => _copyToClipboard(context, contact.phone!),
                  ),
                if (contact.email != null)
                  _InfoTile(
                    icon: Icons.email,
                    label: 'Email',
                    value: contact.email!,
                    onCopy: () => _copyToClipboard(context, contact.email!),
                  ),
                if (contact.notes != null && contact.notes!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.note,
                    label: 'Notes',
                    value: contact.notes!,
                  ),
              ],
            ),
          ),
          const Gap(24),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      contact.isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    label: Text(contact.isFavorite ? 'Unfavorite' : 'Favorite'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
          const Gap(32),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const Gap(8),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      trailing: onCopy != null
          ? IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: onCopy,
            )
          : null,
    );
  }
}

class _ContactFormSheet extends StatefulWidget {
  final Contact? contact;
  final Future<void> Function(
    String name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    bool isFavorite,
  ) onSave;

  const _ContactFormSheet({
    this.contact,
    required this.onSave,
  });

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;
  late final TextEditingController _notesController;
  late bool _isFavorite;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _companyController = TextEditingController(text: widget.contact?.company ?? '');
    _notesController = TextEditingController(text: widget.contact?.notes ?? '');
    _isFavorite = widget.contact?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.contact != null;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Contact' : 'New Contact',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? Colors.amber : Colors.grey,
                  ),
                ),
              ],
            ),
            const Gap(24),
            
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name *',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(16),
            
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(16),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(16),
            
            TextField(
              controller: _companyController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Company',
                prefixIcon: const Icon(Icons.business_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(16),
            
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
            ),
            const Gap(24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Add Contact'),
                  ),
                ),
              ],
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    await widget.onSave(
      name,
      _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      _isFavorite,
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
