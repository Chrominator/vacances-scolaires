# vacances-scolaires
Principe du script :

Après son initialisation manuelle sur un terminal, le script va chercher le calendrier ICAL des congés scolaires et détermine si aujourd'hui appartient à une période de ce calendrier.

Les variables Domoticz suivantes seront valorisés :

    Vacances_Scolaires_Source : chemin d'accès vers le calendier ICAL des congés scolaires sur la page OpenData du gouvernement français.
    Vacances_Scolaires_ON : Contient soit O si on est en période de congés, ou N sinon.
    Vacances_Scolaires_Name : Contient le nom de la période de vacances, ou blanc sinon.


Prérequis :

cURL est requis, mais en général il fait partie des distributions linux.
Dans ce script j'utilise un outil bien pratique pour décoder les sorties de Domoticz au format JSON : https://github.com/stedolan/jq
Je l'ai trouvé dans mes dépôts, ils est possible qu'il soit aussi dans d'autres distributions.
Si ce n'est pas le cas, vous pourrez l'installer via git.

Initialisation :

La seule chose à faire est de placer le script dans le répertoire des scripts de domoticz.
L'exécuter en ligne de commande, et répondre aux questions posées.
Le script va créer les variables dans Domoticz automatiquement.

Ensuite, paramétrer l'appel du script dans la crontab une fois par jour.

Note : si le calendrier officiel ne convient pas (calendrier de vacances différent), vous pouvez générer votre propre calendrier ICAL
puis l'héberger sur le serveur www de Domoticz et définir manuellement la variable Vacances_Scolaires_Source vers ce chemin.

Voir https://easydomoticz.com/forum/viewtopic.php?f=17&t=5601 pour plus d'infos