import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../models/models.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  final city = TextEditingController();
  UserRole role = UserRole.comprador;
  String? error;

  Future<void> register() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 6) {
      setState(() => error = 'Preencha nome, e-mail e senha com pelo menos 6 caracteres.');
      return;
    }

    try {
      final user = await LocalStore.instance.register(
        name: name.text.trim(),
        email: email.text.trim(),
        password: password.text,
        role: role,
        phone: phone.text.trim(),
        city: city.text.trim(),
      );
      await LocalStore.instance.login(user.email, user.password);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 12),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha')),
          const SizedBox(height: 12),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefone')),
          const SizedBox(height: 12),
          TextField(controller: city, decoration: const InputDecoration(labelText: 'Cidade')),
          const SizedBox(height: 16),
          const Text('Tipo de conta',
              style: TextStyle(fontWeight: FontWeight.bold)),
          RadioListTile(
            value: UserRole.comprador,
            groupValue: role,
            title: const Text('Comprador'),
            onChanged: (v) => setState(() => role = v!),
          ),
          RadioListTile(
            value: UserRole.produtor,
            groupValue: role,
            title: const Text('Produtor'),
            onChanged: (v) => setState(() => role = v!),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(onPressed: register, child: const Text('Cadastrar')),
        ],
      ),
    );
  }
}