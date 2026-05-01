"""
Importar este pacote garante que todos os handlers sejam registrados no dispatcher.

Para adicionar um novo handler:
  1. Adicionar o valor em OutboxEventType (model.py)
  2. Criar (ou adicionar em) um módulo neste diretório
  3. Decorar a função com @register(OutboxEventType.NOVO_TIPO)
  4. Importar o módulo abaixo — o worker não precisa de nenhuma alteração.
"""

from app.domains.outbox.handlers import auth  # noqa: F401
