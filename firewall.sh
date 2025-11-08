#!/bin/bash

# Script principal para o firewall

# --- Configuração ---
DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=15
WIDTH=50
CHOICE_HEIGHT=4

# --- Funções ---

# Função para exibir as regras atuais do firewall
function view_rules() {
    # Obter as regras atuais do iptables, incluindo todas as chains
    local rules=$(iptables -L -n --line-numbers 2>&1)

    # Verificar se há regras para exibir
    if [ -z "$rules" ]; then
        rules="Nenhuma regra definida ou o comando iptables falhou."
    fi

    # Exibir as regras em uma caixa de texto rolável
    dialog --backtitle "Gerenciador de Firewall" \
           --title "Regras Atuais do Firewall" \
           --textbox /dev/stdin 22 76 <<<"$rules"
}

# Função para adicionar uma nova regra de firewall usando um assistente passo a passo
function add_rule() {
    # --- Passo 1: Obter Chain ---
    local chain=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 1/8" \
        --radiolist "Selecione a chain:" 15 50 3 \
        "INPUT" "Tráfego de entrada" on \
        "OUTPUT" "Tráfego de saída" off \
        "FORWARD" "Tráfego redirecionado" off \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # --- Passo 2: Obter Interface (opcional) ---
    local interface=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 2/8" \
        --inputbox "Digite a interface de rede (ex: eth0).\nDeixe em branco para qualquer uma." 10 50 "" \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # --- Passo 3: Obter IP de Origem (opcional) ---
    local source_ip=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 3/8" \
        --inputbox "Digite o endereço IP de origem.\nDeixe em branco para qualquer um." 10 50 "" \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # --- Passo 4: Obter IP de Destino (opcional) ---
    local dest_ip=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 4/8" \
        --inputbox "Digite o endereço IP de destino.\nDeixe em branco para qualquer um." 10 50 "" \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # --- Passo 5: Obter Protocolo ---
    local protocol=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 5/8" \
        --radiolist "Selecione o protocolo:" 15 50 4 \
        "all" "Qualquer protocolo" on \
        "tcp" "Protocolo TCP" off \
        "udp" "Protocolo UDP" off \
        "icmp" "Protocolo ICMP" off \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # --- Passo 6: Obter Porta (opcional, apenas para tcp/udp) ---
    local port=""
    if [[ "$protocol" == "tcp" || "$protocol" == "udp" ]]; then
        port=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 6/8" \
            --inputbox "Digite a(s) porta(s) de destino (ex: 80, 443).\nDeixe em branco para qualquer uma." 10 50 "" \
            2>&1 >/dev/tty)
        [ $? -ne 0 ] && return
    fi

    # --- Passo 7: Obter Estado (opcional) ---
    local state_choice=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 7/8" \
        --checklist "Selecione os estados da conexão (opcional):" 15 60 4 \
        "NEW" "Novas conexões" off \
        "ESTABLISHED" "Conexões estabelecidas" off \
        "RELATED" "Relacionada a outra conexão" off \
        "INVALID" "Pacotes inválidos" off \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # Converter a saída da checklist (ex: "NEW" "ESTABLISHED") para uma string separada por vírgulas
    local state=$(echo $state_choice | sed 's/"//g' | sed 's/ /,/g')

    # --- Passo 8: Obter Ação ---
    local action=$(dialog --clear --backtitle "Gerenciador de Firewall" --title "Adicionar Regra: Passo 8/8" \
        --radiolist "Selecione a ação final:" 15 50 3 \
        "ACCEPT" "Permitir o pacote" on \
        "DROP" "Descartar o pacote silenciosamente" off \
        "REJECT" "Rejeitar com um erro" off \
        2>&1 >/dev/tty)
    [ $? -ne 0 ] && return

    # --- Construir e executar o comando ---
    local cmd="iptables -A $chain"
    [ ! -z "$interface" ] && cmd="$cmd -i $interface"
    [ ! -z "$source_ip" ] && cmd="$cmd -s $source_ip"
    [ ! -z "$dest_ip" ] && cmd="$cmd -d $dest_ip"
    if [ "$protocol" != "all" ]; then
        cmd="$cmd -p $protocol"
        [ ! -z "$port" ] && cmd="$cmd --dport $port"
    fi
    [ ! -z "$state" ] && cmd="$cmd -m state --state $state"
    cmd="$cmd -j $action"

    # Executar o comando e mostrar feedback
    if $cmd; then
        dialog --title "Sucesso" --msgbox "Regra adicionada com sucesso:\n\n$cmd" 12 80
    else
        dialog --title "Erro" --msgbox "Falha ao adicionar a regra. Verifique os dados inseridos.\n\nComando tentado:\n$cmd" 12 80
    fi
}

# Função para deletar uma regra de firewall
function delete_rule() {
    # Primeiro, mostrar as regras para que o usuário saiba qual deletar
    view_rules

    # Pedir ao usuário a chain e o número da linha
    local details=$(dialog --clear \
                           --backtitle "Gerenciador de Firewall" \
                           --title "Deletar Regra" \
                           --form "Digite os detalhes da regra a ser deletada:" \
                           10 50 2 \
                           "Chain (ex: INPUT):" 1 1 "" 1 20 20 0 \
                           "Número da Linha:" 2 1 "" 2 20 20 0 \
                           2>&1 >/dev/tty)

    # Lidar com cancelar/esc
    if [ $? -ne 0 ]; then
        return
    fi

    local chain=$(echo "$details" | sed -n 1p)
    local line_num=$(echo "$details" | sed -n 2p)

    # Validar entrada
    if [ -z "$chain" ] || [ -z "$line_num" ]; then
        dialog --title "Erro" --msgbox "Chain e Número da Linha são obrigatórios." 8 40
        return
    fi

    # Construir e executar o comando
    local cmd="iptables -D $chain $line_num"
    if $cmd; then
        dialog --title "Sucesso" --msgbox "Regra deletada com sucesso." 8 40
    else
        dialog --title "Erro" --msgbox "Falha ao deletar a regra. Verifique se a chain e o número da linha estão corretos." 8 60
    fi
}

# Função para salvar as regras do firewall
function save_rules() {
    if sudo iptables-save > /etc/iptables/rules.v4; then
        dialog --title "Sucesso" --msgbox "Regras salvas com sucesso em /etc/iptables/rules.v4" 8 60
    else
        dialog --title "Erro" --msgbox "Falha ao salvar as regras. Verifique se o pacote 'iptables-persistent' está instalado." 8 70
    fi
}

# Função para limpar todas as regras do firewall
function flush_rules() {
    if dialog --yesno "Você tem certeza que deseja limpar TODAS as regras do firewall?" 8 60; then
        if sudo iptables -F && sudo iptables -X && sudo iptables -Z; then
            dialog --title "Sucesso" --msgbox "Todas as regras do firewall foram limpas." 8 50
        else
            dialog --title "Erro" --msgbox "Falha ao limpar as regras do firewall." 8 50
        fi
    fi
}

# Função para exibir o menu principal
function main_menu() {
    while true; do
        choice=$(dialog --clear \
                        --backtitle "Gerenciador de Firewall" \
                        --title "Menu Principal" \
                        --menu "Por favor, escolha uma das seguintes opções:" \
                        $HEIGHT $WIDTH 6 \
                        1 "Visualizar regras atuais do firewall" \
                        2 "Adicionar uma nova regra" \
                        3 "Deletar uma regra" \
                        4 "Salvar regras" \
                        5 "Limpar todas as regras" \
                        6 "Sair" \
                        2>&1 >/dev/tty)

        # Lidar com a escolha do usuário
        case $? in
            $DIALOG_CANCEL)
                clear
                echo "Programa finalizado."
                exit
                ;;
            $DIALOG_ESC)
                clear
                echo "Programa abortado." >&2
                exit 1
                ;;
        esac

        case $choice in
            1)
                view_rules
                ;;
            2)
                add_rule
                ;;
            3)
                delete_rule
                ;;
            4)
                save_rules
                ;;
            5)
                flush_rules
                ;;
            6)
                clear
                echo "Saindo."
                break
                ;;
        esac
    done
}

# --- Execução Principal ---

# Verificar se o script está sendo executado como root
if [ "$(id -u)" != "0" ]; then
   echo "Este script deve ser executado como root" 1>&2
   exit 1
fi

# Iniciar o menu principal
main_menu
