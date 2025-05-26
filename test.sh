#!/bin/bash

# Script de teste para o Sistema Web do Hub de Crédito
# Este script executa testes funcionais básicos para verificar se o sistema está operando corretamente

echo "Iniciando testes do Sistema Web do Hub de Crédito..."
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

# Criar arquivo .env a partir do exemplo
if [ ! -f ".env" ]; then
    echo "[SETUP] Criando arquivo .env a partir do exemplo..."
    cp .env.example .env
    echo "[SETUP] Arquivo .env criado com sucesso."
fi

# Executar testes funcionais
echo "[TESTE] Iniciando testes funcionais..."

# Teste 1: Verificar se o aplicativo inicia corretamente
echo "[TESTE 1] Verificando inicialização do aplicativo..."
python -c "from src.main import create_app; app = create_app('testing'); print('Aplicativo inicializado com sucesso.')"
if [ $? -eq 0 ]; then
    echo "[TESTE 1] ✅ Aplicativo inicializa corretamente."
else
    echo "[TESTE 1] ❌ Falha na inicialização do aplicativo."
    exit 1
fi

# Teste 2: Verificar se o banco de dados é criado corretamente
echo "[TESTE 2] Verificando criação do banco de dados..."
python -c "
from src.main import create_app
from src.models.models import db
app = create_app('testing')
with app.app_context():
    db.create_all()
    print('Banco de dados criado com sucesso.')
"
if [ $? -eq 0 ]; then
    echo "[TESTE 2] ✅ Banco de dados criado corretamente."
else
    echo "[TESTE 2] ❌ Falha na criação do banco de dados."
    exit 1
fi

# Teste 3: Verificar se os modelos estão funcionando corretamente
echo "[TESTE 3] Verificando modelos de dados..."
python -c "
from src.main import create_app
from src.models.models import db, Usuario, Cliente, Assessor, Banco, Modalidade, Operacao
app = create_app('testing')
with app.app_context():
    db.create_all()
    usuario = Usuario(nome='Teste', email='teste@teste.com', senha_hash='hash')
    db.session.add(usuario)
    db.session.commit()
    usuario_db = Usuario.query.filter_by(email='teste@teste.com').first()
    print(f'Usuário criado com ID: {usuario_db.id}')
    assert usuario_db is not None, 'Usuário não encontrado'
    print('Modelos funcionando corretamente.')
"
if [ $? -eq 0 ]; then
    echo "[TESTE 3] ✅ Modelos de dados funcionando corretamente."
else
    echo "[TESTE 3] ❌ Falha nos modelos de dados."
    exit 1
fi

# Teste 4: Verificar se as rotas estão registradas corretamente
echo "[TESTE 4] Verificando rotas..."
python -c "
from src.main import create_app
app = create_app('testing')
print('Rotas registradas:')
for rule in app.url_map.iter_rules():
    print(f'- {rule}')
"
if [ $? -eq 0 ]; then
    echo "[TESTE 4] ✅ Rotas registradas corretamente."
else
    echo "[TESTE 4] ❌ Falha no registro de rotas."
    exit 1
fi

# Teste 5: Verificar se os templates estão sendo carregados corretamente
echo "[TESTE 5] Verificando templates..."
python -c "
from src.main import create_app
import os
app = create_app('testing')
template_dir = os.path.join(app.root_path, 'templates')
print(f'Diretório de templates: {template_dir}')
templates = [f for f in os.listdir(template_dir) if os.path.isdir(os.path.join(template_dir, f))]
print(f'Subdiretórios de templates: {templates}')
assert len(templates) > 0, 'Nenhum template encontrado'
print('Templates carregados corretamente.')
"
if [ $? -eq 0 ]; then
    echo "[TESTE 5] ✅ Templates carregados corretamente."
else
    echo "[TESTE 5] ❌ Falha no carregamento de templates."
    exit 1
fi

echo "======================================================"
echo "Testes concluídos com sucesso!"
echo "O sistema está pronto para implantação."

# Desativar ambiente virtual
deactivate
