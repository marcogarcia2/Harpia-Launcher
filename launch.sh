#!/bin/bash

## Fluxo do programa:

# Encontra o IP automaticamente deste computador;
# Verifica se a Jetson está ligada e conectada à rede Atena;
# Abre 4 terminais do Terminator, e dá SSH na Jetson em três deles;
# Executa os comandos necessários para rodar a fase.

# Definindo o argumento padrão para 1
ARG=${1:-1}

# Verifique se o argumento é um número de 1 a 4
if [[ "$ARG" =~ ^[1-4]$ ]]; then
    echo "[CBR2024]: Executando a Fase $ARG..."
else
    echo "Erro: O argumento deve ser um número entre 1 e 4."
    exit 1
fi

# ---------------- FUNÇÕES E VARIÁVEIS ----------------- #

# Função que descobre o IP da máquina na interface principal
find_ip(){
    ip -4 addr show | grep -Eo 'inet ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' | grep -v '127.0.0.1' | grep -v '172\.17\.' | awk '{ print $2 }'
}

# # CASO A PRIMEIRA FUNÇÃO NÃO FUNCIONE
# find_ip(){
#     if command -v ip > /dev/null; then
#         ip -4 addr show | grep -Eo 'inet ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' | grep -v '127.0.0.1' | grep -v '172\.17\.' | awk '{ print $2 }'
#     else
#         # Caso contrário, use ifconfig
#         ifconfig | grep -Eo 'inet (addr:)?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' | grep -v '127.0.0.1' | grep -v '172\.17\.' | awk '{ print $2 }'
#     fi
# }

# Variáveis do código
fase=$ARG
my_ip=$(find_ip)
jetson_ip="192.168.0.35"
jetson_password="megamente"
echo $my_ip
#echo "O endereço de ip deste computador é $my_ip"
#echo "O endereço de ip da Jetson é $jetson_ip"

ssh_connect_at_jetson(){
    xdotool type --delay 1 "sshpass -p $jetson_password ssh jetson@$jetson_ip"
    xdotool key Return
}

# -------------------- VERIFICAÇÕES -------------------- #

# Verificar se a função find_ip conseguiu obter o IP corretamente
if [ -z "$my_ip" ]; then
    echo "Erro: não foi possível determinar o IP deste computador."
    exit 1
fi

# Testar conectividade com o Jetson
# ping -c 1 $jetson_ip > /dev/null
# if [ $? -ne 0 ]; then
#     echo "Erro: não foi possível alcançar o endereço IP da Jetson ($jetson_ip)."
#     exit 1
# fi

# --------------- EXECUTANDO OS COMANDOS --------------- #

#   [ 1 ] [ 2 ]
#   [ 4 ] [ 3 ]

# Inicia uma nova instância do Terminator
terminator -e bash &
sleep 1

# 1 Jetson
ssh_connect_at_jetson
sleep 1
xdotool type --delay 1 "export ROS_IP=$jetson_ip && export ROS_MASTER_URI=http://$jetson_ip:11311"
xdotool key Return
xdotool key ctrl+shift+e

# 2 Seu computador
xdotool type --delay 1 "export ROS_IP=$my_ip && export ROS_MASTER_URI=http://$jetson_ip:11311"
xdotool key Return
xdotool key Alt+Left

# 1 Jetson
xdotool type --delay 1 "roslaunch px4_realsense_bridge cbr_bridge.launch"
xdotool key Return
xdotool key Alt+Right

# 2 PC
xdotool type --delay 1 "rosrun plotjuggler plotjuggler"
xdotool key Return
xdotool key ctrl+shift+o

# 3 Jetson
#ssh_connect_at_jetson
#sleep 1
xdotool type --delay 1 "roslaunch cbr cbr_onboard.launch phase:='$fase'"
xdotool key Return
xdotool key Alt+Left
xdotool key ctrl+shift+o

# 4 Jetson
#ssh_connect_at_jetson
sleep 10
xdotool type --delay 1 "rosservice call /start_phase "value: true"
xdotool key Return