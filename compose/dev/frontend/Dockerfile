FROM ghcr.io/cirruslabs/flutter:latest

WORKDIR /app

# Copia pacotes locais primeiro para que o pub get funcione
COPY frontend/packages/ /app/frontend/packages/

# Move para o diretório do Lab App
WORKDIR /app/frontend/apps/lab_app

# Copia dependências
COPY frontend/apps/lab_app/pubspec.yaml ./

# Instala dependências (incluindo as referências aos pacotes locais)
RUN flutter pub get

# Copia o restante do código do app
COPY frontend/apps/lab_app/ .

# Expõe a porta
EXPOSE 3000

CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]
