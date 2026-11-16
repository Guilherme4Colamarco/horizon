# Sincronização do Horizon Offline

O workflow `Sync Horizon upstream` verifica `horizon-rust/horizon:main` toda segunda-feira às 09h UTC e também pode ser executado manualmente na aba Actions. O GitHub pode atrasar
execuções agendadas e desativar agendas após 60 dias de inatividade em repositórios
públicos; nesse caso, reative o workflow na aba Actions.

A atualização usa merge em `main`, preservando os commits do fork, sem rebase nem
force push. Se houver conflitos, nada é enviado: a execução falha e lista os
arquivos no resumo em Actions. As notificações dependem das preferências de
notificação do GitHub. Uma alteração concorrente em main também impede o push;
a próxima execução tenta novamente.

Um merge sem conflitos não garante compatibilidade funcional das alterações
offline. Revise e teste o launcher após atualizações relevantes. O push com
GITHUB_TOKEN não dispara outros workflows de push; este fluxo não compila nem
publica releases. Se o upstream alterar arquivos de workflow e o GitHub rejeitar
sua atualização pelo token automático, a integração precisará ser feita
manualmente com uma credencial autorizada.

Para pausar: Actions → Sync Horizon upstream → Disable workflow. Nenhum segredo
pessoal adicional é necessário; a execução usa GITHUB_TOKEN com contents: write.
