# Projet Liquibase-script

Le projet est constitué des dossiers suivants:
 * Le dossier **bin** contient les utilitaires nécessaires pour le traitement.
 * Le dossier **changelog** => contient le changelog généré par les commandes de **dump** et **restore**.
 * Le dossier **doc** => contient une documentation sommaire de Liquibase
 * Le dossier **liquibase** => contient les versions utilisées de liquibase 

## Fichier de configuration

Le fichier **config.properties** contient la configuration nécessaire pour Liquibase. Il n'est pas directement exploitable par les différentes versions de liquibase du projet.

> _Nota_: Le fichier **config.properties** est toutefois nécessaire pour le parametrage du script batch **Liquibse_service.bat** qui gère le basculement entre les différents versions de liquibase contenu dans le projet.

les élèments de configuration sont reparti en 3 groupes:
* groupe 1: Ce groupe contient les mots clés suivantx et décrit la BDD modifiée par le script batch:
    * url=jdbc:postgresql://localhost:5432/target_db
    * username=<user>
    * password=<pwd>

* groupe 2: Ce groupe contient les mots clés suivants et décrit la BDD servant de référence ( elle fournit les schemas + les données contenu dans le changeLog ):
    * referenceUrl=jdbc:postgresql://localhost:5432/ref_db
    * referenceUsername=<user>
    * referencePassword=<pwd>

* groupe 3 : Ce groupe contient les autres options de parametrage:
    * debug: true|false => activation du mode debug
    * liquibaseVersion: 3|4 => choix de la version liquibase utlisée

## Dump d'une BDD de référence
 
 1. Renseigner la configuration de la BDD à sauvegarder dans le ficher **config.properties**:
    * referenceUrl=jdbc:postgresql://<server>:<port>/<db_name>
    * referenceUsername=<user>
    * referencePassword=<password>
  

2. Selectionner la version de liquibase à utiliser
   >    3 => (Postgresql < v9.5) ou   4 => (Postgresql >= v9.5)
    * liquibaseVersion=4


3. Selon le type de sauvegarde, il est possible de sauvegarder:
   * la totalité de la BDD (schema + contrainte + donnée) avec la commande suivante :
        > **Liquibase_service.bat dump**

    * ou par partie avec un découpage (schema, contraintes et données):
       * commande pour sauvegarder uniquement le schema (tables + colonnes): 
            > **Liquibase_service.bat dump --table**

       * commande pour sauvegarder pour les contraintes (clés primaires, étrangères, indexes):
            > **Liquibase_service.bat dump --constraint**

       * commande pour sauvegarder pour les données:
            > **Liquibase_service.bat dump --data**

Le resultat est placé dans le repertoire **changelog\script** du projet. Ce dernier contient les fichiers sql resultant de la sauvegarde.

A la racine du dossier **changelog** se trouve un fichier nommé **root.yaml**.
C'est un fichier spécial qui sert de référence pour la restoration des sauvegardes. 
> Note: Ne pas modifier le contenu du fichier _**root.yaml**_.


## Créer une nouvelle base de donnée à partir d'une sauvegarde

1. Renseigner la configuration de la BDD à créer dans le ficher **config.properties**:
    * url=jdbc:postgresql://<server>:<port>/<db_name>
    * username=<user>
    * password=<password>
  

2. Selectionner la version de liquibase à utilisée.
   >    3 => (Postgresql < v9.5) ou   4 => (Postgresql >= v9.5)
    * liquibaseVersion=4

3. Enn fonction du paramètre de restoration, il est possible de restorer:
   * la totalité de la BDD (schema + contrainte + donnée) :
        > **Liquibase_service.bat restore**

    * ou par partie avec un découpage (schema, contraintes et données):
       * Restorer uniquement le schema (tables + colonnes): 
            > **Liquibase_service.bat restore --table**

       * Restorer uniquement les contraintes (clés primaires, étrangères, indexes):
            > **Liquibase_service.bat restore --constraint**

       * Restorer uniquement les données:
            > **Liquibase_service.bat restore --data**

4. Vérifier le resultat de la commande en se connectant à la BDD configurée à l'étape 1.

## Voir la version de Liquibase en cours d'utilisation

>**_Important_**: 
Le script _Liquibase_service.bat_ a été uniquement testé sur Postgresql comme Type de BDD avec différentes versions (9.2, 9.5 et 12) !

Il est possible de changer la version de Liquibase utlisée durant une opération de duplication d'une BDD cible vers une autre, notamment si les versions de BDD sont différentes.
> Exemple:  postgresql v9.2 => Postgresql v9.5 

>**_Important_**: 
Pour les versions Postgresql < 9.5 mieux vaut utiliser la version 3 (paramètre liquibaseVersion) pour tout type d'opération et ensuite faire la restoration avec la version 4 de liquibase si la version de postgresql > 9.5 !

Pour connaitre à tout moment la version de liquibase utilisé par le script, utiliser une des commandes suivantes:

    > **Liquibase_service.bat**
                ou
    > **Liquibase_service.bat -v**
                ou
    > **Liquibase_service.bat --version**
