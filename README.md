# 🌾 Marketplace Rural — Aplicativo Flutter

Aplicativo que conecta **produtores rurais** e **compradores**: catálogo de produtos, pedidos com acompanhamento, negociação de preços, controle de estoque e gestão da propriedade.

**Tecnologias:** Flutter · Dart · Material Design 3 · Provider · API REST em PHP · MySQL

```
Flutter (app)  ──HTTPS/JSON + token──▶  API PHP (server/api)  ──PDO──▶  MySQL
```

O app **nunca** acessa o MySQL diretamente e não contém credenciais.

---

## Como executar

```bash
flutter pub get
flutter run                                    # usa https://buzzcodex.com.br/api
flutter run --dart-define=API_BASE_URL=https://outro-servidor/api
flutter test
```

Variáveis opcionais: `SUPPORT_EMAIL` (e-mail exibido em "Falar com o suporte").

## Publicar a API (`server/api`)

1. Envie a pasta `server/api` para o servidor (ex.: `public_html/api`).
2. Copie `config/config.example.php` para `config/config.php` e preencha os dados, ou use as variáveis de ambiente `MR_DB_*` e `MR_TOKEN_SECRET`.
3. Gere a chave do token: `php -r "echo bin2hex(random_bytes(32));"`.
4. Teste: `POST /api/auth/login.php` com `{"email":"...","senha":"..."}`.

Requer PHP 8.1+ com PDO MySQL. Detalhes e endpoints pendentes estão em **[docs/API.md](docs/API.md)**.

---

## Estado da integração

| Módulo | Interface | Servidor |
|---|---|---|
| Login, cadastro, sessão, logout | ✅ | ✅ `server/api` (tabela `usuarios`) |
| Editar perfil, alterar senha | ✅ | ✅ `server/api` |
| Recuperar senha | ✅ | ⏳ requer SMTP + tabela |
| Produtos (catálogo, CRUD, imagens) | ✅ | ⏳ aguardando SQL |
| Estoque (indicadores, atualização, histórico) | ✅ | ⏳ aguardando SQL |
| Pedidos (lista, filtros, linha do tempo, status) | ✅ | ⏳ aguardando SQL |
| Negociações (proposta, contraproposta, aceite) | ✅ | ⏳ aguardando SQL |
| Favoritos | ✅ | ⏳ aguardando SQL |
| Gestão de fazenda | ✅ | ⏳ aguardando SQL |
| Notificações | ✅ | ⏳ aguardando SQL |

Quando um endpoint ainda não existe, a tela informa **"aguardando o servidor"** e indica qual endpoint falta. **Não há dados simulados.**

---

## Estrutura

```
lib/
├── main.dart / app.dart        # inicialização, providers, tema e sessão
├── core/
│   ├── config/                 # URL da API, timeouts, limites
│   ├── network/                # ApiClient (token, timeout, erros), endpoints
│   ├── routes/                 # rotas nomeadas + permissões por tipo de conta
│   ├── theme/                  # paleta, tema claro e escuro
│   └── utils/                  # validadores, formatadores, preferências locais
├── models/                     # User, Product, Order, Negotiation, Farm...
├── repositories/               # uma classe por módulo da API
├── controllers/                # Provider: sessão, tema, preferências, favoritos
├── widgets/                    # componentes reutilizáveis
└── screens/                    # auth, shell (menu), home, products, orders,
                                # negotiations, stock, favorites, farm, settings
server/api/                     # API PHP (auth + usuários)
docs/API.md                     # contrato completo da API
```

## Perfis e permissões

| Recurso | Produtor | Comprador |
|---|---|---|
| Início | Painel de vendas | Vitrine de produtos |
| Produtos | Meus produtos (CRUD) | Catálogo |
| Pedidos | Atender e avançar status | Fazer, acompanhar, cancelar e confirmar |
| Negociações | Responder propostas | Propor e contrapropor |
| Estoque | ✅ | — |
| Favoritos | ✅ | ✅ |
| Gestão de fazenda | ✅ | — |

O controle é feito em três camadas no app (menu, rotas e repositórios) e deve ser repetido no servidor, que lê o tipo de conta do banco e nunca confia no cliente.

## Segurança

- Senhas com `password_hash` no servidor; nunca ficam no dispositivo.
- Token assinado (HMAC-SHA256) com validade e invalidação ao trocar a senha.
- Consultas parametrizadas (PDO, sem emulação de prepares).
- Erros 5xx nunca exibem detalhes técnicos.
- "Lembrar acesso" desmarcado mantém a sessão só em memória.
- ⚠️ O antigo `TCC/backend/config/conexao.php` usa o usuário **root** com a senha escrita no código. Troque essa senha e crie um usuário MySQL exclusivo para a API.
