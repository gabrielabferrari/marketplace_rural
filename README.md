# MarketPlace Rural — Flutter

Projeto front-end funcional com persistência local e camada preparada para API.

## O que já funciona sem backend
- Cadastro e login.
- Dois perfis: produtor e comprador.
- Dados separados por usuário.
- Cadastro, edição e exclusão de produtos.
- Controle de estoque.
- Catálogo.
- Favoritos.
- Carrinho com alteração de quantidade.
- Finalização de pedido.
- Baixa automática do estoque ao finalizar pedido.
- Histórico de pedidos.
- Edição de perfil.
- Persistência local com SharedPreferences.

## Usuários de teste
Comprador:
- comprador@email.com
- 123456

Produtor:
- produtor@email.com
- 123456

## Como executar
1. Abra a pasta no VS Code/Android Studio.
2. Rode `flutter pub get`.
3. Rode `flutter run`.

## Integração com o backend
O Flutter NÃO deve acessar o MySQL diretamente.

Quando o grupo criar a API PHP:
1. Configure `baseUrl` em `lib/services/api_service.dart`.
2. Criem endpoints para login, usuários, produtos, estoque, carrinho, pedidos, favoritos e negociações.
3. Substituam as operações do `LocalStore` por chamadas ao `ApiService` gradualmente.
4. Mantenham os mesmos Models para reduzir alterações nas telas.

Exemplo de arquitetura futura:

Flutter -> ApiService -> API PHP -> MySQL

O arquivo PHP de conexão com MySQL deve permanecer no servidor e nunca ser colocado dentro do aplicativo Flutter.