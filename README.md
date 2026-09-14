# GDeskEx – Gerenciador de Aplicativos Android para Windows

GDeskEx é uma ferramenta de linha de comando (CLI) que permite instalar, executar e gerenciar aplicativos Android no Windows utilizando o **Windows Subsystem for Android (WSA)** através dos builds comunitários **WSABuilds**.

Funciona em **Windows 10 e Windows 11**.

---

## 🖥️ Requisitos do Sistema

| Item                    | Mínimo                          | Recomendado              |
|-------------------------|---------------------------------|--------------------------|
| **Sistema Operacional** | Windows 10 22H2 (19045.2311+)   | Windows 11               |
| **Arquitetura**         | x64                             | x64                      |
| **Memória RAM**         | 8 GB                            | 16 GB                    |
| **Armazenamento**       | 10 GB livres (SSD recomendado)  | SSD NVMe                 |
| **Virtualização**       | Ativada na BIOS + Windows       | Ativada                  |
| **PowerShell**          | 5.1 ou superior                 | 7+                       |

> **Nota:** Em PCs com 8 GB de RAM, use o comando `.\gdeskex.ps1 wsa-optimize` para melhorar o desempenho.

---

## 📥 Como Usar (Forma Correta)

### 1. Baixar o script
```powershell
irm https://raw.githubusercontent.com/Elguilande/gdeskex/main/gdeskex.ps1 -OutFile gdeskex.ps1
```

### 2. Liberar execução de scripts (só precisa fazer uma vez por sessão)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### 3. Executar comandos
Sempre use desta forma:

```powershell
.\gdeskex.ps1 wsa-status
.\gdeskex.ps1 wsa-install
.\gdeskex.ps1 wsa-optimize
.\gdeskex.ps1 list
```

---

## 🧠 Comandos Disponíveis

### Comandos de Aplicativos
| Comando                        | Descrição                          | Exemplo                                      |
|--------------------------------|------------------------------------|----------------------------------------------|
| `install <caminho.apk>`        | Instala um APK local               | `.\gdeskex.ps1 install C:\Downloads\app.apk` |
| `run <pacote>`                 | Executa um app instalado           | `.\gdeskex.ps1 run com.whatsapp`             |
| `list`                         | Lista todos os pacotes             | `.\gdeskex.ps1 list`                         |
| `list-user`                    | Lista apenas apps do usuário       | `.\gdeskex.ps1 list-user`                    |
| `remove <pacote>`              | Desinstala um app                  | `.\gdeskex.ps1 remove com.whatsapp`          |
| `shortcut <pacote> [nome]`     | Cria atalho na área de trabalho    | `.\gdeskex.ps1 shortcut com.whatsapp WhatsApp` |
| `get <app-id>`                 | Baixa e instala do repositório     | `.\gdeskex.ps1 get among-us`                 |

### Comandos do WSA
| Comando                  | Descrição                                      | Exemplo                          |
|--------------------------|------------------------------------------------|----------------------------------|
| `wsa-install`            | Baixa e instala o WSABuilds                    | `.\gdeskex.ps1 wsa-install`      |
| `wsa-status`             | Mostra status do WSA                           | `.\gdeskex.ps1 wsa-status`       |
| `wsa-memory <MB>`        | Define limite de memória                       | `.\gdeskex.ps1 wsa-memory 2048`  |
| `wsa-spoof <modelo>`     | Altera modelo do dispositivo                   | `.\gdeskex.ps1 wsa-spoof Pixel5` |
| `wsa-restart`            | Reinicia o WSA                                 | `.\gdeskex.ps1 wsa-restart`      |
| `wsa-optimize`           | Otimiza para PCs com pouca RAM                 | `.\gdeskex.ps1 wsa-optimize`     |

---

## 🚀 Exemplos Rápidos

```powershell
# Verificar status
.\gdeskex.ps1 wsa-status

# Instalar o WSA
.\gdeskex.ps1 wsa-install

# Otimizar
.\gdeskex.ps1 wsa-optimize

# Instalar um APK
.\gdeskex.ps1 install C:\Users\SeuUsuario\Downloads\telegram.apk

# Executar o app
.\gdeskex.ps1 run org.telegram.messenger
```

---

## 🔧 Resolução de Problemas

| Problema                          | Solução                                                                 |
|-----------------------------------|-------------------------------------------------------------------------|
| `running scripts is disabled`     | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`           |
| `gdeskex` não é reconhecido       | Use sempre `.\gdeskex.ps1` em vez de só `gdeskex`                      |
| WSA não instala                   | Verifique se a Virtualização está ativada na BIOS                      |
| Muito lento                       | Use `.\gdeskex.ps1 wsa-optimize` e preferencialmente SSD               |

---

## 👤 Autor

Criado por **Elves Guilande** – GTSXAI
```

---
