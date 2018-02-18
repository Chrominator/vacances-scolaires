# Fonction permettant d'afficher un texte sur tty
# et dans les logs de Domoticz
#
#	Chrominator@free.free
#
#	2017-12-31 : Version initiale
#
# 
cURL="/usr/bin/curl"
JQ="/usr/bin/jq"
couleur="#801ee1"

voir_les_logs () {
	msg="$0: $1"
	echo $msg
	msg="<font color='$couleur'>"$msg"</font>"
	$cURL -i -H  "Accept: application/json" "http://${DOMOTICZ_SERVER}/json.htm?type=command&param=addlogmessage&message=`$JQ -s -R -r @uri <<< $msg`"
}