// CLASSE : UpdateAllAccounts
// RÔLE MÉTIER : Batch Apex qui recalcule le chiffre d'affaires de TOUS les comptes clients
//               ayant au moins une commande activée. Utilisé lors d'une migration de données
//               (ex : import massif via Data Loader) pour mettre à jour en masse les CA
//               sans saturer les limites Salesforce (governor limits).
// EXEMPLE D'UTILISATION : après l'import de 50 000 commandes historiques via un système externe,
//                         on lance ce batch pour calculer le CA de tous les comptes concernés.
//
// Un batch Apex traite les enregistrements par lots (ex : 200 par 200) pour contourner
// les limites Salesforce sur le nombre de requêtes et d'opérations par transaction.

global class UpdateAllAccounts implements Database.Batchable<sObject> {

    // MÉTHODE START : définit quels enregistrements traiter
    // Ici, on récupère uniquement les comptes qui ont au moins une commande activée
    // (inutile de recalculer le CA d'un compte sans commande)
    global Database.QueryLocator start(Database.BatchableContext info) {
        return Database.getQueryLocator(
            'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Order WHERE Status = \'Activated\')'
        );
    }

    // MÉTHODE EXECUTE : appelée pour chaque lot d'enregistrements
    // "scope" contient le sous-ensemble de comptes traités dans ce lot
    // On délègue le calcul à UpdateAccounts.updateAccountCA (logique partagée avec le trigger)
    global void execute(Database.BatchableContext info, List<Account> scope) {
        // Conversion de la liste en Set d'IDs pour la requête SOQL de UpdateAccounts
        Set<Id> accountIds = (new Map<Id, SObject>(scope)).keySet();
        UpdateAccounts.updateAccountCA(accountIds);
    }

    // MÉTHODE FINISH : appelée une seule fois après la fin de tous les lots
    // Peut être utilisée pour envoyer un email de confirmation ou déclencher un autre batch
    global void finish(Database.BatchableContext info) {
    }
}
