# Gerenciador de Firewall IPTables

Este projeto fornece uma interface de linha de comando amigável para gerenciar as regras de firewall do `iptables` no Linux. Ele utiliza o utilitário `dialog` para criar menus e caixas de entrada, facilitando a adição, remoção e visualização de regras de firewall sem a necessidade de memorizar a sintaxe complexa do `iptables`.

## Funcionalidades

*   **Menu Interativo:** Um menu simples e intuitivo para navegar pelas opções do firewall.
*   **Visualizar Regras:** Exibe todas as regras atuais do `iptables` em um formato limpo e numerado.
*   **Adicionar Regras:** Um assistente passo a passo guia você pelo processo de criação de uma nova regra. Em vez da entrada manual, você pode selecionar opções de menus para parâmetros como:
    *   **Chain:** Escolha entre `INPUT`, `OUTPUT` ou `FORWARD`.
    *   **Protocolo:** Selecione `tcp`, `udp`, `icmp` ou `all`.
    *   **Ação:** Escolha `ACCEPT` (aceitar), `DROP` (descartar) ou `REJECT` (rejeitar) o tráfego.
    *   **Estado da Conexão:** Selecione múltiplos estados como `NEW`, `ESTABLISHED`, etc.
    *   Você ainda será solicitado a inserir informações específicas, como endereços IP e números de porta, quando necessário.
*   **Remover Regras:** Exclua facilmente uma regra especificando sua chain e número de linha após visualizar as regras atuais.
*   **Salvar Regras:** Salva as regras atuais do firewall para que persistam após a reinicialização.
*   **Limpar Todas as Regras:** Remove todas as regras do firewall.

## Pré-requisitos

*   Uma distribuição Linux baseada em Debian (como o Ubuntu) com o gerenciador de pacotes `apt`.
*   Privilégios de root ou `sudo`.

## Instalação

1.  **Clone o repositório ou baixe os arquivos.**
2.  **Execute o script de instalação.** Este script instalará as dependências `dialog`, `iptables` e `iptables-persistent`, e tornará o script principal do firewall executável.

    ```bash
    # Você será solicitado a fornecer sua senha para instalar os pacotes
    bash install.sh
    ```

## Uso

Após a instalação, você pode executar o gerenciador de firewall com o seguinte comando. É recomendado executá-lo com `sudo` para ter as permissões necessárias para modificar o `iptables`.

```bash
sudo ./firewall.sh
```
