# Importa todos os models para que o SQLAlchemy resolva os relacionamentos.
# Use em scripts standalone (seeds, fixtures, CLI) antes de qualquer query.
import app.domains.admin.model  # noqa: F401
import app.domains.calibracoes.model  # noqa: F401
import app.domains.clientes.model  # noqa: F401
import app.domains.equipamentos.model  # noqa: F401
import app.domains.grandezas.model  # noqa: F401
import app.domains.ordens_servico.model  # noqa: F401
import app.domains.outbox.model  # noqa: F401
import app.domains.plans.model  # noqa: F401
import app.domains.subscriptions.model  # noqa: F401
import app.domains.tenants.model  # noqa: F401
import app.domains.users.model  # noqa: F401
