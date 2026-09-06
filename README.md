# ArenaHub

Aplicativo Flutter para reserva e gestão de arenas esportivas. Esta entrega
cobre o módulo de **autenticação**, construído sobre uma separação em
camadas (domínio, dados, apresentação) e os cinco princípios SOLID.

O app tem **dois modos de autenticação**, trocáveis numa constante. Os dois
implementam o mesmo contrato, então nenhuma tela ou regra de negócio muda
entre eles:

| Modo | Onde ficam os usuários | Precisa de internet? | Precisa de configuração? |
| --- | --- | --- | --- |
| `AuthMode.local` | SQLite no aparelho (memória na web), senha em PBKDF2 | não | não |
| `AuthMode.firebase` | Firebase Authentication | sim | já vem configurado |

A escolha está no topo de `lib/main.dart`:

```dart
const AuthMode kAuthMode = AuthMode.firebase;   // ou AuthMode.local
```

## Como rodar

Requer **Flutter 3.47+** (`flutter --version`). Nenhum outro pré-requisito.

```bash
flutter pub get
flutter run -d chrome                    # mais rápido para desenvolver
flutter run                              # escolhe o dispositivo conectado
flutter test                             # 54 testes
flutter analyze                          # sem issues
```

### Se for rodar no emulador Android

A primeira compilação leva de 3 a 10 minutos: o Gradle baixa o ecossistema
Android e os artefatos do Firebase do zero. Da segunda vez em diante são
segundos, e `r` (hot reload) / `R` (hot restart) nem passam pelo Gradle.

O app **trava visivelmente no emulador em modo debug** — Dart roda em JIT,
as `assert` estão ligadas e o emulador ainda traduz cada chamada gráfica.
Isso é do ambiente, não do app. Para ver o desempenho real:

```bash
flutter run --release -d emulator-5554   # liso, mas sem hot reload
```

Se a máquina ficar pesada depois de compilar, o daemon do Gradle continua
vivo segurando alguns GB. Encerrar é seguro:

```bash
cd android && ./gradlew --stop
```

## Modo local (`AuthMode.local`)

Zero configuração: troque a constante, rode, pronto. Funciona offline.

As contas abaixo são criadas na primeira execução, com a senha gravada em
hash como qualquer outra. A tela de cadastro ainda não existe (ver *O que
falta*).

| E-mail | Senha | Papel |
| --- | --- | --- |
| `admin@arenahub.com` | `arena2026` | Administrador do sistema |
| `dono@arenahub.com` | `arena2026` | Dono de arena |
| `jogador@arenahub.com` | `arena2026` | Jogador |

## Modo Firebase (`AuthMode.firebase`, padrão)

**Para rodar contra o projeto do time, não é preciso configurar nada.**
`lib/firebase_options.dart` e `android/app/google-services.json` estão
versionados de propósito — chave de API do Firebase identifica o projeto,
não autentica ninguém; a segurança vem do Authentication e das regras do
Firestore. Basta `flutter pub get` e rodar.

O que você precisa é de **uma conta que exista no projeto**. Como a tela de
cadastro ainda não foi feita, ela é criada no console:

> [console.firebase.google.com](https://console.firebase.google.com) →
> projeto **ArenaHub** → *Authentication* → aba *Users* → *Adicionar
> usuário*.

Peça acesso ao projeto a quem o criou, ou use o modo local, que não depende
de ninguém.

### Usando seu próprio projeto Firebase

Se preferir não depender do projeto do time:

1. Crie um projeto em [console.firebase.google.com](https://console.firebase.google.com).
2. *Authentication* → *Sign-in method* → ative **E-mail/senha**.
   Não ative *Telefone*: é a única opção que cobra.
3. Instale a CLI e configure:

```bash
npm install -g firebase-tools && firebase login
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
flutterfire configure          # escolha o projeto, marque android e web
```

Isso reescreve `lib/firebase_options.dart` e `android/app/google-services.json`.

### Papéis de usuário (opcional)

O Firebase Authentication guarda e-mail e senha, **não guarda cargo**.
Papel exigiria *custom claims*, que precisam do Admin SDK num servidor, e
por isso o perfil (nome e papel) vive num documento do Firestore.

Sem Firestore o login funciona igual — todo mundo entra como *jogador* e o
nome vem do trecho antes do `@`. Para ativar os papéis:

1. *Firestore Database* → *Criar banco de dados* → região
   `southamerica-east1` → modo produção.
2. Aba *Regras* → cole o conteúdo de [`firestore.rules`](firestore.rules)
   → *Publicar*. Sem esse passo o app conecta mas não lê nada.

Nenhuma linha de código muda: os papéis passam a funcionar sozinhos.

## Estrutura

```
lib/
├── core/                         Result<T> e Failure — vocabulário de erro
├── firebase_options.dart         gerado por `flutterfire configure`
├── di/
│   ├── auth_mode.dart            local | firebase
│   └── injector.dart             composition root (único lugar com classes concretas)
└── features/
    ├── auth/
    │   ├── domain/               não importa Flutter, SQLite nem HTTP
    │   │   ├── entities/         User, Role, AuthSession, SignUpData
    │   │   ├── value_objects/    Email, Password
    │   │   ├── repositories/     AuthRepository (port)
    │   │   ├── services/         PasswordHasher, SessionStorage (ports)
    │   │   └── usecases/         SignIn, SignUp, SignOut, GetCurrentSession
    │   ├── data/                 adaptadores dos ports
    │   │   ├── datasources/      SQLite, memória, perfis no Firestore
    │   │   ├── mappers/          sessão ⇄ JSON
    │   │   ├── models/           UserRecord (entidade + hash da senha)
    │   │   ├── repositories/     LocalAuthRepository, FirebaseAuthRepository
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

**O — Aberto/fechado.** Duas demonstrações. `InMemoryUserDataSource` foi
acrescentado para atender à web e aos testes sem editar uma linha de
`UserDataSource`, `LocalAuthRepository` ou do domínio. Depois,
`FirebaseAuthRepository` trocou o backend de autenticação inteiro sem tocar
em nenhuma entidade, caso de uso, controller ou tela — só uma classe nova e
uma linha no composition root. Estender o sistema foi somar código, nunca
alterar o que já funcionava.

**L — Substituição de Liskov.** Todo adaptador devolve `Result<T>` com as
mesmas `Failure` do domínio. `FirebaseAuthRepository.failureFor` traduz os
códigos de erro do Firebase para esse mesmo vocabulário, então a tela reage
igual a uma senha errada venha ela do SQLite ou do Firebase. Trocar
`InMemoryUserDataSource` por `SqfliteUserDataSource` — ou o repositório real
pelo `FakeAuthRepository` dos testes — também não muda nada para quem chama.

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

54 testes, sem nenhum banco ou plugin nativo: os ports são pequenos e os
dublês são escritos à mão em `test/support/fakes.dart`. Cobrem value
objects, os quatro casos de uso, o hasher, o repositório local, o mapper de
sessão, o seeder, o `AuthController` e a `LoginPage`.

## O que falta

- **Tela de cadastro.** O caso de uso `SignUp` e o `AuthController` já a
  suportam nos dois modos; falta a tela. Enquanto isso, as contas de
  demonstração (modo local) ou usuários criados no console (modo Firebase).
- **Recuperação de senha, confirmação de e-mail e biometria.** Não previstos
  nesta entrega.
- **Domínio de arenas.** A `HomePage` ainda é uma tela de boas-vindas;
  quadras, arenas e reservas são o próximo módulo.
