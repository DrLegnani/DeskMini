# DeskMini - Smart Display para iPad mini 4 (TrollStore)

App nativo em **SwiftUI (iOS 15+)** projetado para transformar o iPad mini 4 em um painel de mesa com relógio grande, data, clima em tempo real com previsão horária (Open-Meteo) e modo noturno.

---

## 🚀 Como gerar o arquivo `.ipa` pelo GitHub Actions

1. Crie um novo repositório vazio no seu GitHub (pode ser público ou privado), por exemplo `DeskMini`.
2. No seu computador, dentro desta pasta (`DeskMini`), abra o terminal e execute:
   ```bash
   git init
   git branch -M main
   git add .
   git commit -m "feat: initial DeskMini app"
   git remote add origin https://github.com/SEU_USUARIO/DeskMini.git
   git push -u origin main
   ```
3. Acesse o seu repositório no GitHub e vá até a aba **Actions**.
4. O workflow **Build DeskMini IPA** iniciará automaticamente. Em cerca de 2 a 3 minutos, ele concluirá o build.
5. Clique na execução concluída e role até a seção **Artifacts** para baixar o `DeskMini-TrollStore-IPA.zip`.

---

## 📲 Como instalar no iPad via TrollStore

### Método 1: Direto pelo Safari no iPad
1. Abra o Safari no iPad, acesse o GitHub, baixe o artefato ou envie o arquivo `.ipa` para o iPad (ex: AirDrop, Google Drive ou iCloud Drive).
2. Toque no arquivo `.ipa` e escolha **Compartilhar com TrollStore** (ou abra o TrollStore e toque no botão `+` -> *Install IPA File*).

### Método 2: Envio direto via SSH pelo PC
Com o iPad conectado na mesma rede Wi-Fi, você pode enviar o `.ipa` diretamente via SCP pelo PowerShell do Windows:
```powershell
scp -i "$env:LOCALAPPDATA\Codex-iPad\ipad-mini4-ed25519" DeskMini.ipa mobile@10.1.1.183:/var/mobile/Downloads/
```
Depois, abra o app TrollStore no iPad e selecione o arquivo na pasta Downloads.
