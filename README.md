# ArenaHub

Aplicativo Flutter para reserva e gestão de arenas esportivas. Esta entrega
cobre o módulo de **autenticação**, construído sobre uma separação em
camadas (domínio, dados, apresentação) e os cinco princípios SOLID.

A autenticação roda **inteiramente no dispositivo**: usuários em SQLite
(memória na web) e sessão em `SharedPreferences`. O app funciona sem
backend e sem rede.

## Como rodar

```bash
flutter pub get
flutter run            # Android, iOS, Linux, Windows, macOS ou Chrome
flutter test           # 47 testes
flutter analyze        # sem issues
```

### Contas de demonstração

Criadas na primeira execução, com a senha gravada em hash como qualquer
outra. A tela de cadastro ainda não existe (ver *O que falta*).

| E-mail | Senha | Papel |
| --- | --- | --- |
| `admin@arenahub.com` | `arena2026` | Administrador do sistema |
| `dono@arenahub.com` | `arena2026` | Dono de arena |
| `jogador@arenahub.com` | `arena2026` | Jogador |

## Estrutura

```
lib/
├── core/                         Result<T> e Failure — vocabulário de erro
├── di/injector.dart              composition root (único lugar com classes concretas)
└── features/
    ├── auth/
    │   ├── domain/               não importa Flutter, SQLite nem HTTP
    │   │   ├── entities/         User, Role, AuthSession, SignUpData
    │   │   ├── value_objects/    Email, Password
    │   │   ├── repositories/     AuthRepository (port)
    │   │   ├── services/         PasswordHasher, SessionStorage (ports)
    │   │   └── usecases/         SignIn, SignUp, SignOut, GetCurrentSession
    │   ├── data/                 adaptadores dos ports
    │   │   ├── datasources/      SQLite, memória
    │   │   ├── mappers/          sessão ⇄ JSON
    │   │   ├── models/           UserRecord (entidade + hash da senha)
    │   │   ├── repositories/     LocalAuthRepository
    │   │   ├── seed/             contas de demonstração
    │   │   └── services/         Pbkdf2PasswordHasher, PrefsSessionStorage
    │   └── presentation/         AuthController, AuthState, LoginPage
    └── home/presentation/        HomePage
```

A dependência aponta sempre para dentro: `presentation → domain ← data`.
Nenhum arquivo de `domain/` importa pacote externo além do próprio Dart.

## SOLID, arquivo por arquivo

**S — Responsabilidade única.** `SignIn` valida a entrada, delega e guarda a
sessão; quem sabe conferir senha é `Pbkdf2PasswordHasher`; quem sabe
traduzir sessão para JSON é `SessionJsonMapper`. A regra de e-mail vive só
em `Email` — a tela a consome (`LoginPage._validateEmail`) em vez de
reescrevê-la, então mudar a validação num lugar muda no outro.

**O — Aberto/fechado.** `InMemoryUserDataSource` foi acrescentado para
atender à web e aos testes sem editar uma linha de `UserDataSource`,
`LocalAuthRepository` ou do domínio. Estender o sistema foi somar uma
classe, não alterar as existentes.

**L — Substituição de Liskov.** Todo adaptador devolve `Result<T>` com as
mesmas `Failure` do domínio. Trocar `InMemoryUserDataSource` por
`SqfliteUserDataSource` — ou o repositório real pelo `FakeAuthRepository`
dos testes — não muda como o chamador trata sucesso e erro.

**I — Segregação de interfaces.** `PasswordHasher` tem dois métodos;
`SessionStorage`, três. `SignOut` depende só de `SessionStorage`, e não do
`AuthRepository` que não usaria. Os ports são pequenos o bastante para que
os dublês de teste sejam escritos à mão, sem biblioteca de mock.

**D — Inversão de dependência.** Casos de uso e `AuthController` dependem
de abstrações. `Injector` é o único arquivo que menciona SQLite,
`SharedPreferences` ou PBKDF2 — trocar o armazenamento local por um cliente
HTTP é editar esse arquivo e mais nenhum.

## Tratamento de erro

Falha de negócio não é exceção: é valor. `Result<T>` tem dois casos
(`Ok`/`Err`) e `Failure` é um tipo selado, então o compilador cobra o
tratamento dos dois lados e a mensagem exibida vem do tipo, não de um
`toString()` interpretado com `replaceAll`.

## Senhas

PBKDF2-HMAC-SHA256, 12.000 iterações, salt aleatório de 16 bytes por senha,
comparação em tempo constante. O hash carrega os próprios parâmetros
(`pbkdf2-sha256$<iterações>$<salt>$<hash>`), então aumentar o custo no
futuro não invalida as senhas já cadastradas. Nenhuma senha é gravada em
texto puro, nem mesmo as das contas de demonstração.

## Testes

47 testes, sem nenhum banco ou plugin nativo: os ports são pequenos e os
dublês são escritos à mão em `test/support/fakes.dart`. Cobrem value
objects, os quatro casos de uso, o hasher, o repositório local, o mapper de
sessão, o seeder, o `AuthController` e a `LoginPage`.

## O que falta

- **Tela de cadastro.** O caso de uso `SignUp` e o `AuthController` já a
  suportam; falta a tela. Enquanto isso, as contas de demonstração acima.
- **Recuperação de senha, confirmação de e-mail e biometria.** Não previstos
  nesta entrega.
- **Domínio de arenas.** A `HomePage` ainda é uma tela de boas-vindas;
  quadras, arenas e reservas são o próximo módulo.
