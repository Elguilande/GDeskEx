```markdown
# GDeskEx – Gerenciador de Aplicativos Android para Windows

GDeskEx é uma ferramenta de linha de comando (CLI) que permite instalar, executar e gerenciar aplicativos Android no Windows, utilizando o **Windows Subsystem for Android (WSA)** ou o projeto comunitário **WSABuilds**. Ele funciona em **Windows 10 e 11**, com otimizações especiais para PCs com pouca RAM (4 GB).

---

## 🖥️ Requisitos do Sistema

| Item | Mínimo | Recomendado |
|------|--------|-------------|
| **Sistema Operacional** | Windows 10 versão 22H2 (build 19045.2311+) | Windows 11 |
| **Arquitetura** | x64 (64 bits) | x64 |
| **Memória RAM** | 4 GB (com otimizações) | 8 GB ou mais |
| **Armazenamento** | 10 GB livres (SSD recomendado) | SSD NVMe |
| **Virtualização** | Ativada na BIOS (Intel VT-x / AMD-V) | Ativada |
| **PowerShell** | Versão 5.1 ou superior | Versão 7+ (opcional) |

> **Nota:** Em sistemas com 4 GB de RAM, utilize o comando `gdeskex wsa-optimize` para aplicar configurações de baixo consumo.

---

## 📥 Modo Online – Executar sem Instalação (Uma Linha)

O GDeskEx pode ser executado diretamente da internet sem precisar baixar ou instalar nada no computador. Basta abrir o **PowerShell** e usar um dos comandos abaixo:

### Usando PowerShell (nativo)
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seuusuario/gdeskex/main/gdeskex.ps1 | iex; gdeskex wsa-status"
```

### Usando PowerShell (com argumentos)
Para passar argumentos diretamente, use:
```powershell
$script = Invoke-WebRequest -Uri https://raw.githubusercontent.com/seuusuario/gdeskex/main/gdeskex.ps1 -UseBasicParsing; $scriptBlock = [ScriptBlock]::Create($script.Content); & $scriptBlock wsa-status
```

### Usando cURL (se disponível)
```cmd
curl -sSL https://raw.githubusercontent.com/seuusuario/gdeskex/main/gdeskex.ps1 | powershell -Command -
```

> **Importante:** Substitua `seuusuario` pelo seu nome de usuário do GitHub e `main` pela branch correta.

---

## 📦 Modo Offline – Download e Instalação Local

Para ter o GDeskEx sempre disponível sem depender da internet, siga os passos abaixo.

### 1. Baixar o script
- **Opção A – Manual:** Acesse `https://raw.githubusercontent.com/seuusuario/gdeskex/main/gdeskex.ps1`, clique com botão direito e "Salvar como...".
- **Opção B – PowerShell:**
  ```powershell
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/seuusuario/gdeskex/main/gdeskex.ps1" -OutFile "$env:USERPROFILE\Desktop\gdeskex.ps1"
  ```

### 2. Permitir execução de scripts locais (uma vez)
Abra o **PowerShell como Administrador** e execute:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Executar o script
```powershell
cd C:\Users\SeuUsuario\Desktop
.\gdeskex.ps1 wsa-status
```

### 4. (Opcional) Adicionar ao PATH
Para chamar `gdeskex` de qualquer lugar, mova o script para uma pasta do PATH (ex: `C:\Windows\System32`) ou crie um atalho `.bat`:
```bat
@echo off
powershell -ExecutionPolicy Bypass -File "C:\Caminho\para\gdeskex.ps1" %*
```
Salve como `gdeskex.bat` em uma pasta do PATH.

---

## 🧠 Comandos Disponíveis

### Comandos de Aplicativos Android

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `install <caminho.apk>` | Instala um APK local | `gdeskex install C:\Downloads\whatsapp.apk` |
| `run <pacote>` | Executa um aplicativo instalado | `gdeskex run com.whatsapp` |
| `list` | Lista todos os pacotes instalados | `gdeskex list` |
| `list-user` | Lista apenas apps do usuário | `gdeskex list-user` |
| `remove <pacote>` | Desinstala um aplicativo | `gdeskex remove com.whatsapp` |
| `shortcut <pacote> [nome]` | Cria atalho na área de trabalho | `gdeskex shortcut com.whatsapp WhatsApp` |
| `get <app-id>` | Baixa e instala app do repositório online | `gdeskex get among-us` |

### Comandos de Gerenciamento do Subsistema (WSA)

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `wsa-install` | Baixa e instala o WSABuilds automaticamente | `gdeskex wsa-install` |
| `wsa-status` | Mostra status do WSA (instalado, memória, modelo) | `gdeskex wsa-status` |
| `wsa-memory <MB>` | Define limite de memória RAM para o WSA | `gdeskex wsa-memory 1536` |
| `wsa-spoof <modelo>` | Altera identificação do dispositivo (Pixel4a, Pixel5, Pixel6) | `gdeskex wsa-spoof Pixel4a` |
| `wsa-restart` | Reinicia o subsistema Android | `gdeskex wsa-restart` |
| `wsa-optimize` | Aplica otimizações para PC com 4 GB de RAM | `gdeskex wsa-optimize` |

### Ajuda Geral
- Execute `gdeskex` (sem argumentos) para exibir o menu de ajuda.

---

## 🚀 Exemplos de Uso Comum

### 1. Verificar se o ambiente está pronto
```powershell
.\gdeskex.ps1 wsa-status
```

### 2. Instalar o WSABuilds (primeira vez)
```powershell
.\gdeskex.ps1 wsa-install
```

### 3. Aplicar otimizações para 4 GB de RAM
```powershell
.\gdeskex.ps1 wsa-optimize
```

### 4. Instalar um APK baixado da internet
```powershell
.\gdeskex.ps1 install C:\Users\Macovela\Downloads\telegram.apk
```

### 5. Executar o aplicativo recém‑instalado
```powershell
.\gdeskex.ps1 run org.telegram.messenger
```

### 6. Criar um atalho na área de trabalho
```powershell
.\gdeskex.ps1 shortcut org.telegram.messenger "Meu Telegram"
```

### 7. Listar todos os apps instalados
```powershell
.\gdeskex.ps1 list
```

### 8. Remover um app
```powershell
.\gdeskex.ps1 remove com.exemplo.app
```

---

## 🔧 Resolução de Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `running scripts is disabled` | Política de execução restrita | Execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` como Admin |
| `adb não encontrado` | WSA não instalado ou modo desenvolvedor desligado | Execute `gdeskex wsa-install` e ative o modo desenvolvedor nas configurações do WSA |
| `WSA não inicia` | Virtualização desativada na BIOS | Reinicie o PC, entre na BIOS e ative Intel VT-x ou AMD-V |
| `Aplicativo não abre` | Activity principal não encontrada | Use `gdeskex list` para ver o nome correto do pacote |
| `Erro de memória` | RAM insuficiente | Aplique `gdeskex wsa-optimize` ou aumente o limite com `wsa-memory` |

---

## 📡 Repositório Online (para o modo `get`)

O comando `gdeskex get <app-id>` consulta um arquivo JSON hospedado em:
```
https://raw.githubusercontent.com/seuusuario/gdeskex-repo/main/repo.json
```

Formato esperado:
```json
{
  "apps": [
    {
      "id": "among-us",
      "name": "Among Us",
      "apk_url": "https://example.com/amongus.apk",
      "package": "com.innersloth.amongus"
    }
  ]
}
```

Você pode hospedar seu próprio repositório e alterar a variável `$repoUrl` dentro do script `gdeskex.ps1`.

---

## 📄 Licença

GDeskEx é distribuído sob a licença **MIT**. O subsistema WSABuilds segue a licença **AGPL v3**.

---

## 👤 Autor

Criado por Elves Guilande – parte do ecossistema GTSXAI.

Para dúvidas ou sugestões, abra uma issue no repositório GitHub.
```