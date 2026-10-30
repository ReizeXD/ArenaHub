# Guia de Configuração da Autenticação Social — Google & Apple Auth

Este documento fornece o passo a passo completo para configurar os provedores de autenticação social (**Sign in with Google** e **Sign in with Apple**) no **ArenaHub**, integrando o Firebase Authentication, o Google Cloud Console e o Apple Developer Portal para ambientes de desenvolvimento e produção.

---

## 🚀 Sumário

1. [Visão Geral e Arquitetura](#1-visão-geral-e-arquitetura)
2. [Execução Local e Offline (Modo Local)](#2-execução-local-e-offline-modo-local)
3. [Configuração do Google Sign-In](#3-configuração-do-google-sign-in)
   - [3.1 Ativação no Firebase Console](#31-ativação-no-firebase-console)
   - [3.2 Obtenção da Chave SHA-1 (Android)](#32-obtenção-da-chave-sha-1-android)
   - [3.3 Configuração no Google Cloud Console](#33-configuração-no-google-cloud-console)
4. [Configuração do Apple Sign-In](#4-configuração-do-apple-sign-in)
   - [4.1 Requisitos de Conta Apple Developer](#41-requisitos-de-conta-apple-developer)
   - [4.2 Habilitação no App ID (iOS / macOS)](#42-habilitação-no-app-id-ios--macos)
   - [4.3 Criação do Service ID e Redirect URI (Web / Android)](#43-criação-do-service-id-e-redirect-uri-web--android)
   - [4.4 Geração da Chave Privada (.p8) e Ativação no Firebase](#44-geração-da-chave-privada-p8-e-ativação-no-firebase)
5. [Auto-provisionamento de Perfil no Firestore](#5-auto-provisionamento-de-perfil-no-firestore)
6. [Tratamento de Falhas e Cancelamentos](#6-tratamento-de-falhas-e-cancelamentos)

---

## 1. Visão Geral e Arquitetura

O ArenaHub implementa login e cadastro social com base nos princípios de **Clean Architecture**:

- **Domínio (`features/auth/domain`)**: Casos de uso `SignInWithGoogle` e `SignInWithApple` desacoplados de SDKs de terceiros.
- **Dados (`features/auth/data`)**: `FirebaseAuthRepository` (produção na nuvem) e `LocalAuthRepository` (desenvolvimento offline e testes determinísticos).
- **Apresentação (`features/auth/presentation`)**: `AuthController`, `GoogleSignInButton`, `AppleSignInButton` e `SocialAuthDivider`, em total conformidade com as diretrizes de marca e tokens de design (`AppColors`, `AppText`, `AppSpacing`).

---

## 2. Execução Local e Offline (Modo Local)

Para desenvolver ou testar o aplicativo **sem necessidade de credenciais externas, sem internet e sem custos**:

1. No arquivo `lib/main.dart`, certifique-se de que o modo está definido como `AuthMode.local`:
   ```dart
   const AuthMode kAuthMode = AuthMode.local;
   ```
2. Ao rodar o app (`flutter run`), clicar em **"Continuar com o Google"** ou **"Continuar com a Apple"** simula imediatamente uma sessão válida com perfis fictícios pré-configurados:
   - Google: `atleta.google@arenahub.com` (Nome: *Atleta Google*)
   - Apple: `atleta.apple@arenahub.com` (Nome: *Atleta Apple*)
3. A sessão é persistida em memória / SharedPreferences local, suportando restauração na abertura do app e logout completo.

---

## 3. Configuração do Google Sign-In

### 3.1 Ativação no Firebase Console

1. Acesse o [Firebase Console](https://console.firebase.google.com/) e selecione o projeto do **ArenaHub**.
2. Navegue até **Build** > **Authentication** > aba **Sign-in method**.
3. Clique em **Adicionar novo provedor** e selecione **Google**.
4. Ative a opção **Habilitar**.
5. Informe o **Nome público do projeto** e selecione o **E-mail de suporte do projeto**.
6. Clique em **Salvar**.

### 3.2 Obtenção da Chave SHA-1 (Android)

Para que o Google Sign-In funcione em dispositivos ou emuladores Android, a impressão digital SHA-1 do certificado precisa estar cadastrada no Firebase.

**Para a chave de debug (desenvolvimento):**
```bash
# No Windows (PowerShell):
keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# No macOS / Linux:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copie a linha que contém o hash `SHA1:` (ex: `AA:BB:CC:...:11:22`).

No Firebase Console:
- Vá em **Configurações do Projeto** (ícone de engrenagem) > aba **Geral**.
- Na seção **Seus aplicativos**, selecione o app Android (`com.computacao.arenahub`).
- Clique em **Adicionar impressão digital** e cole o valor SHA-1.
- Baixe o novo arquivo `google-services.json` atualizado e substitua em `android/app/google-services.json`.

---

## 4. Configuração do Apple Sign-In

### 4.1 Requisitos de Conta Apple Developer

- **Para testes locais/offline**: Gratuito, basta rodar com `AuthMode.local`.
- **Para publicação na App Store e produção**: É obrigatório possuir uma conta ativa no **Apple Developer Program** ($99/ano). Conforme a **Diretriz 4.8 da App Store**, aplicativos que oferecem qualquer login social de terceiros (como o Google) **devem obrigatoriamente oferecer também o Sign in with Apple** como opção equivalente.

### 4.2 Habilitação no App ID (iOS / macOS)

1. Acesse o [Apple Developer Portal](https://developer.apple.com/account/).
2. Vá em **Certificates, Identifiers & Profiles** > **Identifiers**.
3. Selecione o App ID do ArenaHub (`com.computacao.arenahub`).
4. Na lista de capacidades (*Capabilities*), marque a opção **Sign in with Apple**.
5. Clique em **Edit** ao lado da capacidade e selecione **Enable as a primary App ID**.
6. Clique em **Save**.

### 4.3 Criação do Service ID e Redirect URI (Web / Android)

O Service ID é utilizado para autenticação via OAuth 2.0 na Web e no Android:

1. No Apple Developer Portal, vá em **Identifiers** e clique no botão **+**.
2. Selecione **Services IDs** e continue.
3. Preencha:
   - **Description**: `ArenaHub Service`
   - **Identifier**: `com.computacao.arenahub.service`
4. Habilite **Sign in with Apple** e clique em **Configure**:
   - **Primary App ID**: selecione `com.computacao.arenahub`.
   - **Domains and Subdomains**: insira o domínio de autenticação do seu projeto Firebase (ex: `<PROJECT-ID>.firebaseapp.com`).
   - **Return URLs**: insira a URL de callback do Firebase Auth:
     ```
     https://<PROJECT-ID>.firebaseapp.com/__/auth/handler
     ```
5. Salve e registre o Service ID.

### 4.4 Geração da Chave Privada (.p8) e Ativação no Firebase

1. No Apple Developer Portal, vá em **Keys** e clique no botão **+**.
2. Nomeie a chave como `ArenaHub Auth Key`.
3. Marque **Sign in with Apple**, clique em **Configure** e selecione o Primary App ID.
4. Salve e faça o download do arquivo de chave privada (`.p8`). Guarde-o com segurança, pois ele só pode ser baixado uma única vez!
5. Anote o **Key ID** (10 caracteres) e o **Team ID** (localizado no canto superior direito do portal).

**No Firebase Console:**
1. Vá em **Authentication** > **Sign-in method** > **Adicionar provedor** > **Apple**.
2. Ative a opção **Habilitar**.
3. Preencha os campos:
   - **ID do serviço (Service ID)**: `com.computacao.arenahub.service`
   - **ID da equipe da Apple (Team ID)**: seu Team ID
   - **ID da chave (Key ID)**: o Key ID da chave criada
   - **Chave privada**: cole o conteúdo do arquivo `.p8` baixado
4. Clique em **Salvar**.

---

## 5. Auto-provisionamento de Perfil no Firestore

Quando um atleta realiza o primeiro acesso via Google ou Apple Sign-In:

1. O `FirebaseAuthRepository` cria o registro de autenticação no Firebase Auth.
2. Automaticamente é consultada a coleção `users` no Cloud Firestore com o `uid` do usuário.
3. Se o documento ainda não existir, é criado um registro `UserProfile` padrão com:
   - `id`: UID da conta
   - `fullName`: Nome fornecido pelo provedor social (ou trecho antes do `@` caso não informado)
   - `email`: E-mail autenticado
   - `role`: `Role.player` (*Jogador / Atleta*)
   - `createdAt`: Timestamp do momento do cadastro
4. Isso dispensa formulários intermediários de cadastro e permite acesso instantâneo ao catálogo de quadras e reservas.

---

## 6. Tratamento de Falhas e Cancelamentos

O ArenaHub categoriza e trata as falhas sociais de forma tipada:

| Cenário | Falha do Domínio | Comportamento da Interface |
|---|---|---|
| **Cancelamento do diálogo nativo** | `OAuthCancelledFailure` | A interface retorna silenciosamente ao estado `Unauthenticated`, sem disparar alertas ou mensagens de erro desnecessárias. |
| **Colisão de conta existente** | `OAuthAccountCollisionFailure` | Exibe SnackBar explicativo informando que o e-mail já está associado a outro método de login. |
| **Instabilidade de conexão** | `OAuthNetworkFailure` | Exibe SnackBar com mensagem clara de falha de conexão com a rede. |

---

Para dúvidas adicionais ou suporte de desenvolvimento, consulte a equipe de engenharia do ArenaHub.
