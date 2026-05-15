# Projet 9: Améliorez une organisation Salesforce pour votre entreprise

## Prérequis
Avant de commencer, assurez-vous d’avoir :
- Un compte Salesforce valide avec un environnement sandbox ou de développement.
- Les autorisations nécessaires pour créer des objets personnalisés et déployer des packages.
- Git installé sur votre machine pour cloner le projet.

## Installation

### 1. Cloner le dépôt
Commencez par cloner ce dépôt GitHub sur votre machine locale.

```bash
git clone https://github.com/[votre-utilisateur]/[votre-repo].git
cd [votre-repo]
```

### 2. Connexion à votre environnement Salesforce
En utilisant Salesforce DX, connectez-vous à votre organisation Salesforce. Voir documentation : https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_web_flow.htm

```bash
sf org login web --alias my-org [nom-de-votre-org]
```

### 3. Déployer le projet sur Salesforce
Une fois connecté, vous pouvez déployer le projet dans votre environnement Salesforce en exécutant la commande suivante (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_push_md_to_scratch_org.htm) :

```bash
sf project deploy start
```

### 4. Vérification des objets
Après le déploiement, connectez-vous à votre organisation Salesforce et vérifiez que les champs personnalisés pour les **Commandes (Order)** et **Comptes  (Account)** sont créés. Veuillez vérifier également que les classes / triggers et le composant Lightning Web Components ont bien été créés.

## Utilisation
- Accédez aux objets et champs **Commandes** et **Comptes** dans votre environnement Salesforce, puis assurez-vous que les profils disposent des autorisations appropriées pour effectuer des opérations CRUD.

## Ressources supplémentaires
- [Salesforce Developer Documentation](https://developer.salesforce.com/docs)
- [Guide d'utilisation de Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)

