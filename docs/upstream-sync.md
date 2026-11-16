# Sincronização do Horizon Offline

A automação de nuvem `Atualizar Horizon Offline` executa semanalmente às segundas.
Ela busca `horizon-rust/horizon:main`, resolve conflitos e valida antes de enviar
mudanças para `Guilherme4Colamarco/horizon:main`.

Preservar ambos os caminhos é obrigatório: jogar offline com cópia local do
Minecraft sem login Microsoft obrigatório, e login Microsoft opcional com o fluxo
autenticado existente. Preservar também as demais alterações do fork.

A integração usa merge, sem force push ou descarte de commits. Quando não puder
validar uma correção, o agente deve salvar em branch separada e informar o bloqueio.
Não publica releases nem inclui arquivos Mojang ou credenciais.

O workflow GitHub `Sync Horizon upstream` permanece apenas para execução manual;
a agenda anterior foi removida para que merges automáticos não contornem a
validação do agente. Esse workflow manual somente faz merge sem testes funcionais
e interrompe em conflitos. Gerencie ou pause a execução semanal nas automações
do ChatGPT/Codex.
