# 🐳 Configuração de Secrets Docker para CI/CD

## 📋 **Problema Identificado**

O pipeline GitHub Actions falha no job Docker com o erro:

```
Username and password required
```

Isso ocorre porque os secrets `DOCKER_USERNAME` e `DOCKER_PASSWORD` não estão configurados no repositório.

## ✅ **Solução Implementada**

### **1. Job Docker Tornado Condicional**

Modificado o workflow para só executar o job Docker se os secrets existirem:

```yaml
docker:
    name: Build Docker Images
    runs-on: ubuntu-latest
    needs: test
    # ✅ Só executa se os secrets existirem
    if: github.event_name != 'pull_request' && secrets.DOCKER_USERNAME != '' && secrets.DOCKER_PASSWORD != ''
```

**Benefício**: O pipeline não falha mais se os secrets não estiverem configurados.

## 🔧 **Como Configurar os Secrets (Opcional)**

### **Passo 1: Acessar Configurações do Repositório**

1. Vá para seu repositório no GitHub
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

### **Passo 2: Adicionar Secrets**

Clique em **"New repository secret"** e adicione:

#### **DOCKER_USERNAME**

-   **Name**: `DOCKER_USERNAME`
-   **Secret**: Seu nome de usuário do Docker Hub
-   Exemplo: `meuusuario`

#### **DOCKER_PASSWORD**

-   **Name**: `DOCKER_PASSWORD`
-   **Secret**: Sua senha ou token do Docker Hub
-   **Recomendação**: Use um Access Token em vez da senha

### **Passo 3: Criar Token Docker Hub (Recomendado)**

1. Acesse [Docker Hub](https://hub.docker.com/)
2. Vá em **Account Settings** → **Security**
3. Clique em **"New Access Token"**
4. Defina um nome (ex: "GitHub Actions")
5. Copie o token gerado
6. Use este token como `DOCKER_PASSWORD`

## 🚀 **Comportamento do Pipeline**

### **Com Secrets Configurados**

-   ✅ Job de testes executa normalmente
-   ✅ Job de build executa normalmente
-   ✅ Job Docker executa: faz login, build e push da imagem
-   ✅ Job de release executa (se for uma tag)

### **Sem Secrets Configurados**

-   ✅ Job de testes executa normalmente
-   ✅ Job de build executa normalmente
-   ⏭️ Job Docker é **pulado automaticamente**
-   ✅ Job de release executa (se for uma tag)

## 📊 **Vantagens da Abordagem**

1. **✅ Pipeline robusto**: Não falha por configuração ausente
2. **✅ Flexibilidade**: Docker é opcional
3. **✅ Funcionalidade core**: Testes e builds sempre executam
4. **✅ Facilidade**: Configuração de secrets é opcional

## 🔍 **Verificação**

Para verificar se os secrets estão funcionando, observe os logs do job Docker:

```yaml
# ✅ Com secrets configurados
- name: Login no Docker Hub
  uses: docker/login-action@v3
  with:
      username: ${{ secrets.DOCKER_USERNAME }}
      password: ${{ secrets.DOCKER_PASSWORD }}
```

### **Logs Esperados**

**Com secrets**:

```
Login no Docker Hub
✓ Login succeeded
```

**Sem secrets**:

```
Job Docker pulado devido à condição:
secrets.DOCKER_USERNAME != '' && secrets.DOCKER_PASSWORD != ''
```

---

## 📋 **Resumo**

-   **Problema**: Secrets Docker ausentes causavam falha no pipeline
-   **Solução**: Job Docker tornado condicional
-   **Resultado**: Pipeline funciona com ou sem secrets Docker
-   **Benefício**: Funcionalidade core sempre disponível, Docker é enhancement opcional

**Status**: ✅ **Pipeline robusto e flexível implementado**
