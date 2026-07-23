# txeneza_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Segurança

### Chave da API do Gemini (`GEMINI_API_KEY`)

A app usa `flutter_dotenv` para carregar o `.env`, que é empacotado como
**asset dentro do APK/IPA compilado**. Isto significa que qualquer pessoa
que descompacte a app (trivial — basta abrir o `.apk` como um ficheiro
zip) consegue ler a `GEMINI_API_KEY` em texto simples.

Isto é diferente do token do Mapbox ou da chave anónima do Supabase, que
são desenhados para serem expostos publicamente (protegidos por
restrição de domínio/bundle ou por Row Level Security, respectivamente).
A API key do Gemini está ligada à facturação/quota da conta Google — se
ficar exposta sem restrição, outra pessoa pode extraí-la do APK e usá-la
por conta da Txeneza.

**Antes de publicar a app**, mitigar com uma (idealmente as duas) destas
opções:

1. **Restringir a chave no Google Cloud Console** (mais rápido): Google
   Cloud Console → Credentials → selecionar a chave → *Application
   restrictions* → *Android apps*, adicionando o package name
   `com.example.txeneza_app` e o SHA-1 do certificado de assinatura da
   app (`iOS apps` de forma equivalente, se aplicável). Isto só funciona
   se a chave tiver sido criada no Google Cloud Console — chaves geradas
   pelo fluxo simplificado do Google AI Studio normalmente não têm esta
   opção activada por omissão, é preciso confirmar/migrar.

2. **Proxy pelo backend** (mais robusto, mas requer alterar
   `gemini_service.dart` para chamar uma rota `/api` do `txeneza-web` em
   vez de chamar o Gemini directamente): a chave passa a viver só no
   servidor, nunca no app instalado no telemóvel do utilizador. É o
   mesmo padrão já usado em `txeneza-web` para a verificação de
   resolução por IA (`ai-verification.service.ts`).
