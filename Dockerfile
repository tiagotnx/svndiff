# Dockerfile para produção - multi-stage build
FROM golang:1.21-alpine AS builder

# Instalar dependências necessárias
RUN apk add --no-cache git ca-certificates tzdata subversion

# Definir diretório de trabalho
WORKDIR /app

# Copiar go mod e sum files
COPY go.mod go.sum ./

# Baixar dependências
RUN go mod download

# Copiar código fonte
COPY . .

# Build da aplicação
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o svndiff .

# Estágio final - imagem mínima
FROM alpine:latest

# Instalar certificados CA e SVN client
RUN apk --no-cache add ca-certificates subversion

# Criar usuário não-root
RUN addgroup -g 1000 svndiff && \
    adduser -D -u 1000 -G svndiff svndiff

WORKDIR /home/svndiff

# Copiar o binário do estágio anterior
COPY --from=builder /app/svndiff .

# Copiar arquivo de configuração de exemplo
COPY --from=builder /app/config.yaml ./config-example.yaml

# Mudar ownership para o usuário svndiff
RUN chown -R svndiff:svndiff /home/svndiff

# Mudar para usuário não-root
USER svndiff

# Expor porta (se necessário no futuro)
EXPOSE 8080

# Comando padrão
ENTRYPOINT ["./svndiff"]
CMD ["--help"]
