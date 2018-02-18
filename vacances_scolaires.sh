#!/bin/bash
#-------------------------------------------------
# Positionne une variable dans Domoticz
# pour savoir si on est en période de vacances scolaires ou pas.
#
#	Chrominator@free.fr
#
#	2018-01-01 : Version initiale
#
#-------------------------------------------------
# Principe :
# Récupération du fichier officiel des vacances scolaires
# sur le site du gouvernement français
# https://www.data.gouv.fr/fr/datasets/le-calendrier-scolaire/#_
#
# Le nom du fichier à télécharger est dans la variable domoticz
# Vacances_Scolaires_Source.
# Si la variable n'existe pas, la zone de l'académie est demandée par
# ce script puis la variable stockée dans domoticz.
#
# La variable résultante indiquant si on est en période
# scolaire est Vacances_Scolaires_ON de type char 
# valant soit O pour oui ou N pour non
# Accessoirement est valorisé le nom de période de vacances dans 
#la variable Vacances_Scolaires_Name
#-------------------------------------------------
# 
# Définition des variables propres à l'installation
#
#-------------------------------------------------
DOMOTICZ_SERVER="127.0.0.1:8080"

#-------------------------------------------------
#
# Import de la fonction de traçage
#
#-------------------------------------------------
source ./voir_les_logs.sh
#-------------------------------------------------

test_vacances() {
	AUJOURDHUI=`date +%Y%m%d`
	if [ ! -z ${VACANCES["DTEND"]} ]; then
		if [ $AUJOURDHUI -gt ${VACANCES["DTSTART"]} ] && [ $AUJOURDHUI -lt ${VACANCES["DTEND"]} ]; then
			voir_les_logs "Nous sommes actuellement en ${VACANCES["SUMMARY"]}"
			JSONDATA=`$cURL -s -H "Accept: application/json" \
			"http://${DOMOTICZ_SERVER}/json.htm?type=command&param=updateuservariable&vname=Vacances_Scolaires_ON&vtype=2&vvalue=O"`
			if [ ! `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
				voir_les_logs "Erreur lors de la mise à jour de la variable Vacances_Scolaires_ON."
			fi
			JSONDATA=`$cURL -s -H "Accept: application/json" \
			"http://${DOMOTICZ_SERVER}/json.htm?type=command&param=updateuservariable&vname=Vacances_Scolaires_Name&vtype=2&vvalue=$($JQ -s -R -r @uri <<< ${VACANCES['SUMMARY']})"`
			if [ ! `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
				voir_les_logs "Erreur lors de la mise à jour de la variable Vacances_Scolaires_Name."
			fi
		fi
	fi
}

#
#-------------------------------------------------
# Définition des commandes externes utilisées
#
# A installer si inexistantes par sudo apt install ...
#-------------------------------------------------
cURL="/usr/bin/curl"
JQ="/usr/bin/jq"
#-------------------------------------------------
#
# Vérification de l'existence de la variable 
# Vacances_Scolaires_Source
#
#-------------------------------------------------

JSONDATA=`$cURL -s -H "Accept: application/json" "http://${DOMOTICZ_SERVER}/json.htm?type=command&param=getuservariables"`
VACANCES_SCOLAIRES_SOURCE=`$JQ -r '.result[] | select(.Name=="Vacances_Scolaires_Source") | .idx' <<< $JSONDATA`
VACANCES_SCOLAIRES_ON=`$JQ -r '.result[] | select(.Name=="Vacances_Scolaires_ON") | .idx' <<< $JSONDATA`
VACANCES_SCOLAIRES_NAME=`$JQ -r '.result[] | select(.Name=="Vacances_Scolaires_Name") | .idx' <<< $JSONDATA`
if [ ! -z $VACANCES_SCOLAIRES_SOURCE ] && [ ! -z $VACANCES_SCOLAIRES_NAME ] && [ ! -z $VACANCES_SCOLAIRES_ON ]; then
	echo "Index $VACANCES_SCOLAIRES_SOURCE de la variable Vacances_Scolaires_Source trouvé."
#	Effacement des variables issues de précédentes exécution dans Domoticz
	JSONDATA=`$cURL -s -H "Accept: application/json" \
	"http://${DOMOTICZ_SERVER}/json.htm?type=command&param=updateuservariable&vname=Vacances_Scolaires_ON&vtype=2&vvalue=N"`
	if [ ! `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
		voir_les_logs "Erreur lors de la mise à jour de la variable Vacances_Scolaires_ON."
	fi
	JSONDATA=`$cURL -s -H "Accept: application/json" \
	"http://${DOMOTICZ_SERVER}/json.htm?type=command&param=updateuservariable&vname=Vacances_Scolaires_Name&vtype=2&vvalue=$($JQ -s -R -r @uri <<< ' ')"`
	if [ ! `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
		voir_les_logs "Erreur lors de la mise à jour de la variable Vacances_Scolaires_Name."
	fi
	JSONDATA=`$cURL -s -H "Accept: application/json" "http://${DOMOTICZ_SERVER}/json.htm?type=command&param=getuservariable&idx=$VACANCES_SCOLAIRES_SOURCE"`
	if [ `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
		voir_les_logs "Récupération du calendrier des vacances scolaires."
		URI=`$JQ -r '.result[] | .Value' <<< $JSONDATA`
		ICALDATA=`$cURL -s -H "Accept: application/json" "$URI"`

		declare -A VACANCES=( ) 							# définition du tableau

		while IFS=":" read -r KEY VALUE; do					# Chargement du calendrier ICAL dans le tableau
		  VALUE=${VALUE%$'\r'} 								# remove DOS newlines
		  if [[ $KEY = END && $VALUE = VEVENT ]]; then
			test_vacances 									# Vérifie si nous sommes en période de vacances
			VACANCES=( )
		  else
			VACANCES[${KEY%%";"*}]=$VALUE
		  fi
		done <<< "$ICALDATA"
else
		voir_les_logs "Problème lors de la lecture de la variable Vacances_Scolaires_Source."
	fi
else
	if [ -z $VACANCES_SCOLAIRES_NAME ]; then
		JSONDATA=`$cURL -s -H "Accept: application/json" "http://${DOMOTICZ_SERVER}/json.htm?type=command&param=saveuservariable&vname=Vacances_Scolaires_Name&vtype=2&vvalue=nil"`
		if [ `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
			echo -e "Variable Vacances_Scolaires_Name initialisée."
		fi
	fi
	if [ -z $VACANCES_SCOLAIRES_ON ]; then
		JSONDATA=`$cURL -s -H "Accept: application/json" "http://${DOMOTICZ_SERVER}/json.htm?type=command&param=saveuservariable&vname=Vacances_Scolaires_ON&vtype=2&vvalue=nil"`
		if [ `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
			echo -e "Variable Vacances_Scolaires_ON initialisée."
		fi
	fi
	if [ -z $VACANCES_SCOLAIRES_SOURCE ]; then
		echo "Index de la variable Vacances_Scolaires_Source non trouvé."
		 if [ -t 0 ] ; then
			echo -e "On est sur un terminal.\nCréation de la variable Vacances_Scolaires_Source."
			while read -n1 -r -p "De quelle zone académique dépendez vous [A],[B] ou [C]) ?" ZONE; do
				case ${ZONE^^} in
					A) echo -e "\nZone A. Ok"; break;;
					B) echo -e "\nZone B. Ok"; break;;
					C) echo -e "\nZone C. Ok"; break;;
					*) echo -e "\nPardon ?\nRépondez par les lettres [A],[B] ou [C]";;
				esac
			done
			JSONDATA=`$cURL -s -H "Accept: application/json" "http://${DOMOTICZ_SERVER}/json.htm?type=command&param=saveuservariable&vname=Vacances_Scolaires_Source&vtype=2&vvalue=http://www.education.gouv.fr/download.php?file=http://cache.media.education.gouv.fr/ics/Calendrier_Scolaire_Zone_${ZONE^^}.ics"`
			if [ `$JQ -r '.status' <<< $JSONDATA` = 'OK' ]; then
				echo -e "Variable Vacances_Scolaires_Source initialisée pour la Zone $ZONE."
				echo -e "Vous pouvez ajouter ce script à la crontab pour l'exécuter une fois par jour peu après minuit."
			else
				echo -e "Problème lors de la création de la variable dans domonticz.\nCréez la variable Vacances_Scolaires_Source manuellement."
			fi
		else
			voir_les_logs "on est en batch.\nExécutez ce script sur un terminal une fois pour initialiser les variables."
		fi
	fi
fi
