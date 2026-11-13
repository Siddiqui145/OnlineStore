import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';

class ServicePage extends StatefulWidget {
  final AppUser user;
  const ServicePage({required this.user});
  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.user.name);
  late final phone = TextEditingController(text: widget.user.phone);
  final address = TextEditingController(), notes = TextEditingController();
  String type = serviceTypes.first;
  DateTime? date;
  bool busy = false;

  Future<void> pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context, initialDate: now.add(const Duration(days: 1)), firstDate: now, lastDate: now.add(const Duration(days: 180)));
    if (d != null) setState(() => date = d);
  }

  Future<void> submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Repo.placeOrder({
        'type': 'service',
        'serviceType': type,
        'customerName': name.text.trim(),
        'phone': phone.text.trim(),
        'email': widget.user.email,
        'address': address.text.trim(),
        'notes': notes.text.trim(),
        'preferredDate': date == null ? '' : DateFormat('d MMM yyyy').format(date!),
        'items': [],
        'total': 0,
      });
      address.clear();
      notes.clear();
      setState(() => date = null);
      if (mounted) toast(context, 'Service request sent. We will contact you shortly.');
    } catch (e) {
      if (mounted) toast(context, 'Could not send request: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PageTitle('Book a service', subtitle: 'Describe the job and we will get in touch to confirm.'),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Panel(
                child: Form(
                  key: _key,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Service type'),
                      items: [for (final s in serviceTypes) DropdownMenuItem(value: s, child: Text(s))],
                      onChanged: (v) => setState(() => type = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: notes,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'What needs to be done?'),
                        validator: req),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(date == null ? 'Preferred date (optional)' : DateFormat('d MMM yyyy').format(date!)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name'), validator: req),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone number'),
                        validator: req),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: address,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Service address'),
                        validator: req),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kAccent, foregroundColor: kInk),
                      onPressed: busy ? null : submit,
                      child: busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Request service', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}
