import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))  # DON'T CHANGE THIS !!!

from flask import Flask, render_template, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from datetime import datetime
from src.models.models import db, Usuario
from src.routes.operacoes import operacoes_bp
from src.routes.auth import auth_bp
from src.config import config

def create_app(config_name='production'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    config[config_name].init_app(app)
    
    # Inicializar o banco de dados
    db.init_app(app)
    
    # Configurar o login manager
    login_manager = LoginManager()
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message = 'Por favor, faça login para acessar esta página.'
    login_manager.login_message_category = 'info'
    
    @login_manager.user_loader
    def load_user(user_id):
        return Usuario.query.get(int(user_id))
    
    # Registrar blueprints
    app.register_blueprint(operacoes_bp, url_prefix='/operacoes')
    app.register_blueprint(auth_bp, url_prefix='/auth')
    
    @app.route('/')
    def index():
        return redirect(url_for('operacoes.index'))
    
    @app.errorhandler(404)
    def page_not_found(e):
        return render_template('404.html'), 404
    
    @app.errorhandler(500)
    def internal_server_error(e):
        return render_template('500.html'), 500
    
    @app.context_processor
    def inject_now():
        return {'now': datetime.utcnow()}
    
    # Criar tabelas do banco de dados
    with app.app_context():
        db.create_all()
        
        # Verificar se já existe um usuário admin
        if not Usuario.query.filter_by(email='admin@hubcredito.com.br').first():
            from werkzeug.security import generate_password_hash
            admin = Usuario(
                nome='Administrador',
                email='admin@hubcredito.com.br',
                senha_hash=generate_password_hash('admin123'),
                cargo='Administrador',
                ativo=True
            )
            db.session.add(admin)
            
            # Adicionar dados iniciais para testes
            from src.models.models import Banco, Modalidade, Assessor, Cliente
            import json
            
            # Bancos
            bancos = [
                {'nome': 'Banco do Brasil', 'codigo': 'BB', 'taxa_media': 1.2, 'tempo_medio_aprovacao': 5},
                {'nome': 'Caixa Econômica', 'codigo': 'CEF', 'taxa_media': 1.1, 'tempo_medio_aprovacao': 7},
                {'nome': 'Itaú', 'codigo': 'ITAU', 'taxa_media': 1.3, 'tempo_medio_aprovacao': 3},
                {'nome': 'Bradesco', 'codigo': 'BRAD', 'taxa_media': 1.25, 'tempo_medio_aprovacao': 4},
                {'nome': 'Santander', 'codigo': 'SANT', 'taxa_media': 1.35, 'tempo_medio_aprovacao': 4}
            ]
            
            for banco_data in bancos:
                banco = Banco(**banco_data)
                db.session.add(banco)
            
            # Modalidades
            modalidades = [
                {
                    'nome': 'Crédito Pessoal',
                    'descricao': 'Empréstimo pessoal com taxas atrativas',
                    'documentos_necessarios': json.dumps([
                        {'tipo': 'RG', 'obrigatorio': True},
                        {'tipo': 'CPF', 'obrigatorio': True},
                        {'tipo': 'Comprovante de Residência', 'obrigatorio': True},
                        {'tipo': 'Comprovante de Renda', 'obrigatorio': True}
                    ])
                },
                {
                    'nome': 'Financiamento Imobiliário',
                    'descricao': 'Financiamento para compra de imóveis',
                    'documentos_necessarios': json.dumps([
                        {'tipo': 'RG', 'obrigatorio': True},
                        {'tipo': 'CPF', 'obrigatorio': True},
                        {'tipo': 'Comprovante de Residência', 'obrigatorio': True},
                        {'tipo': 'Comprovante de Renda', 'obrigatorio': True},
                        {'tipo': 'Certidão de Casamento', 'obrigatorio': False},
                        {'tipo': 'Escritura do Imóvel', 'obrigatorio': True},
                        {'tipo': 'IPTU', 'obrigatorio': True}
                    ])
                },
                {
                    'nome': 'Financiamento de Veículos',
                    'descricao': 'Financiamento para compra de veículos',
                    'documentos_necessarios': json.dumps([
                        {'tipo': 'RG', 'obrigatorio': True},
                        {'tipo': 'CPF', 'obrigatorio': True},
                        {'tipo': 'Comprovante de Residência', 'obrigatorio': True},
                        {'tipo': 'Comprovante de Renda', 'obrigatorio': True},
                        {'tipo': 'Documento do Veículo', 'obrigatorio': True}
                    ])
                }
            ]
            
            for modalidade_data in modalidades:
                modalidade = Modalidade(**modalidade_data)
                db.session.add(modalidade)
            
            # Assessores
            assessores = [
                {'nome': 'João Silva', 'telefone': '11999887766', 'email': 'joao@exemplo.com', 'empresa': 'Crédito Fácil', 'ativo': True},
                {'nome': 'Maria Oliveira', 'telefone': '11988776655', 'email': 'maria@exemplo.com', 'empresa': 'Financeira Rápida', 'ativo': True},
                {'nome': 'Pedro Santos', 'telefone': '11977665544', 'email': 'pedro@exemplo.com', 'empresa': 'Crédito Fácil', 'ativo': True}
            ]
            
            for assessor_data in assessores:
                assessor = Assessor(**assessor_data)
                db.session.add(assessor)
            
            # Clientes
            clientes = [
                {'nome': 'Ana Souza', 'cpf': '123.456.789-00', 'telefone': '11966554433', 'email': 'ana@cliente.com'},
                {'nome': 'Carlos Ferreira', 'cpf': '987.654.321-00', 'telefone': '11955443322', 'email': 'carlos@cliente.com'},
                {'nome': 'Beatriz Lima', 'cpf': '456.789.123-00', 'telefone': '11944332211', 'email': 'beatriz@cliente.com'}
            ]
            
            for cliente_data in clientes:
                cliente = Cliente(**cliente_data)
                db.session.add(cliente)
            
            db.session.commit()
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)
