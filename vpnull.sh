#! /bin/bash

# Hecho por Anabel Díaz Labrador
# alu0101206011
# 
# Versión 1.5v
# Última actualización: 1 nov 2022
#
# Script que automatiza el proceso de configuración, conexión
# y desconexión del VPN de la Universidad de La Laguna
#
# Necesario ejecutar con permisos de administrador (sudo)

CONNECT="-ON"
DISCONNECT="-OFF"
CONNECTED=0
REGISTERED=0
FILE=/etc/vpnc/vpnull.conf

exit_error()
{
  echo "$1" 1>&2
  exit 1
}

vpn_running_check()
{
  if ifconfig tun0 > /dev/null 2>&1; then
    CONNECTED=1
    
  else
    CONNECTED=0
  fi  
}


process()
{
  vpn_running_check
  if [ $1 = $CONNECT ]; then
    if [ $CONNECTED = 1  ]; then
      exit_error "Ya se encuentra conectado a la VPN."
    fi
    echo "Conectando..."
    vpnc-connect vpnull.conf --local-port 0 1>&2
    if [ $? != 0 ];then
      echo "Borrando datos introducidos..."
      rm $FILE
      echo "Borrado con éxito."
    fi
  elif [ $1 = $DISCONNECT ]; then
    if [ $CONNECTED = 0 ]; then
      exit_error "No se puede desconectar de la VPN porque ya se encuentra desconectado."
    fi
    echo "Desconectando..."
    vpnc-disconnect 
  fi
}

usage()
{
  echo "usage: vpnull [-OFF]or[-ON] to disconnect or connect."
  echo "       vpnull [-D o --delete] to reset data."
  echo "       vpnull [-S o --status] to see the current status."
  echo "       vpnull [-R o --register] to introduce VPN login data."
  echo "Must be run with administrator privileges (sudo)."
} 

initial()
{
  if [ -f "$FILE" ]; then
    echo "Fichero $FILE correcto"
    REGISTERED=1
  else 
    echo "Creando fichero $FILE..."
    echo "IPSec gateway vpn.ull.es" >> $FILE
    echo "IPSec ID ULL" >> $FILE
    echo "IPSec secret usu4r10s" >> $FILE
  
    while true; do
      read -p 'VPN Username: ' user
      read -s -p 'Password: ' password
      echo
      echo "¿Están correctos sus datos? Y/n"
      read answer
      if [[ $answer == "Y" || $answer == "y" ]]; then
        break
      fi
    done
  
    echo "Xauth username $user" >> $FILE
    echo "Xauth password $password" >> $FILE
  
    echo "Datos introducidos con éxito."
  fi
}

if [ $(whoami) != "root" ]; then
  echo "Debe ejecutar con permisos de administrador (sudo)."
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    -h | --help )
      usage
      exit 0
      ;;
    -ON | --online )
      initial
      process -ON
      exit 0
      ;;

    -OFF | --offline )
      process -OFF
      exit 0
      ;;
     -D | --delete )
      rm $FILE
      echo "Reseteado con éxito."
      exit 0
      ;;
     -R | --register )
      initial
      if [ $REGISTERED = 1 ];then
        echo "Usted tiene ya sus datos introducidos, ¿desea volver a introudicr sus datos? Y/n"
        read answer
        if [[ $answer == "Y" || $answer == "y" ]]; then
          rm $FILE
          initial
        fi  
      fi
      exit 0
      ;;
     -S | --status )
      vpn_running_check
      if [ $CONNECTED = 1  ]; then
        echo "Usted tiene la VPN activada."
      else
        echo "Usted tiene la VPN desactivada."
      fi
      exit 0
      ;;
    * )
    echo "La opción $1 no existe, por favor indique una opción válida."
    echo
    usage 
    exit_error "----------------------------------------------------------------"
  esac
  shift
done    

echo "Introduzca algún argumento."
echo
usage 
exit_error "----------------------------------------------------------------"
