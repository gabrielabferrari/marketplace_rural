import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../theme/app_theme.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });
    final user = await LocalStore.instance.login(email.text, password.text);
    if (!mounted) return;
    setState(() => loading = false);

    if (user == null) {
      setState(() => error = 'E-mail ou senha inválidos.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const Icon(Icons.eco, size: 70, color: AppColors.green),
                  const SizedBox(height: 10),
                  const Text('MarketPlace Rural',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen)),
                  const SizedBox(height: 6),
                  const Text('Conectando produtores e compradores.'),
                  const SizedBox(height: 35),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'E-mail', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha', prefixIcon: Icon(Icons.lock)),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: Text(loading ? 'Entrando...' : 'Entrar'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text('Criar uma conta'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Teste local: comprador@email.com / 123456'),
                  const Text('Teste local: produtor@email.com / 123456'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}