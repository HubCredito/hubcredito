#!/bin/bash

# Script de deploy para o Sistema Web do Hub de Crédito
# Este script prepara o ambiente e realiza o deploy da aplicação

echo "Iniciando deploy do Sistema Web do Hub de Crédito..."
echo "======================================================"

# Verificar se o ambiente virtual existe
if [ ! -d "venv" ]; then
    echo "[SETUP] Criando ambiente virtual..."
    python3 -m venv venv
    echo "[SETUP] Ambiente virtual criado com sucesso."
fi

# Ativar ambiente virtual
echo "[SETUP] Ativando ambiente virtual..."
source venv/bin/activate

# Instalar dependências
echo "[SETUP] Instalando dependências..."
pip install -r requirements.txt

# Criar arquivo .env para produção
echo "[SETUP] Configurando variáveis de ambiente para produção..."
cat > .env << EOL
# Banco de dados
DB_USERNAME=root
DB_PASSWORD=password
DB_HOST=localhost
DB_PORT=3306
DB_NAME=hub_credito

# Segurança
SECRET_KEY=hub-credito-chave-secreta-producao-2025

# Configurações de email (para notificações)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=seu-email@gmail.com
MAIL_PASSWORD=sua-senha-de-app
MAIL_DEFAULT_SENDER=Hub de Crédito <seu-email@gmail.com>

# Configurações de WhatsApp (para integração)
WHATSAPP_API_KEY=sua-chave-api
WHATSAPP_PHONE_NUMBER=5511999999999
EOL

echo "[SETUP] Arquivo .env criado com sucesso."

# Criar arquivo wsgi.py para o Gunicorn
echo "[SETUP] Criando arquivo wsgi.py..."
cat > wsgi.py << EOL
from src.main import create_app

app = create_app('production')

if __name__ == "__main__":
    app.run()
EOL

echo "[SETUP] Arquivo wsgi.py criado com sucesso."

# Criar arquivo de serviço para o systemd
echo "[SETUP] Criando arquivo de serviço para o systemd..."
cat > hub_credito.service << EOL
[Unit]
Description=Hub de Crédito Web Service
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 wsgi:app
Restart=always

[Install]
WantedBy=multi-user.target
EOL

echo "[SETUP] Arquivo de serviço criado com sucesso."

# Criar arquivo de configuração para o Nginx
echo "[SETUP] Criando arquivo de configuração para o Nginx..."
cat > hub_credito_nginx << EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /static {
        alias $(pwd)/src/static;
    }
}
EOL

echo "[SETUP] Arquivo de configuração do Nginx criado com sucesso."

# Iniciar o serviço com Gunicorn para teste
echo "[DEPLOY] Iniciando o serviço com Gunicorn..."
gunicorn --daemon --workers 3 --bind 0.0.0.0:5000 wsgi:app

echo "======================================================"
echo "Deploy concluído com sucesso!"
echo "O sistema está disponível na porta 5000."
echo "Para acessar externamente, use o comando 'deploy_expose_port 5000'."
echo "======================================================"
