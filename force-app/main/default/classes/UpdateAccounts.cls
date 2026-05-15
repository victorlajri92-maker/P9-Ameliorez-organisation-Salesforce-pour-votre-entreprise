// CLASSE : UpdateAccounts
// RÔLE MÉTIER : Calcule et met à jour le chiffre d'affaires (CA) d'un ou plusieurs
//               comptes clients en additionnant le TotalAmount de leurs commandes activées.
//               Cette classe est partagée par le trigger UpdateAccountCA et le batch UpdateAllAccounts
//               → la logique métier est écrite une seule fois, réutilisée partout.
// EXEMPLE : Le compte "Maison Leclerc" a 3 commandes activées (200€, 350€, 150€)
//           → son champ Chiffre_d_affaire__c sera mis à jour à 700€.

public with sharing class UpdateAccounts {

    // MÉTHODE : updateAccountCA
    // Reçoit une liste d'IDs de comptes à mettre à jour.
    // Utilisée par : UpdateAccountCA.trigger + UpdateAllAccounts.cls (batch)
    public static void updateAccountCA(Set<Id> accountIds) {

        // Liste des comptes à sauvegarder à la fin (une seule opération DML = bonne pratique)
        List<Account> accountsToUpdate = new List<Account>();

        // Une seule requête SOQL pour récupérer tous les comptes ET leurs commandes activées
        // (sous-requête relationnelle "Orders" = relation parent-enfant entre Account et Order)
        // IMPORTANT : on ne filtre que Status = 'Activated' pour ne pas inclure les commandes
        // en cours ou annulées dans le calcul du CA.
        for (Account acc : [
            SELECT Id, Chiffre_d_affaire__c,
                (SELECT TotalAmount FROM Orders WHERE Status = 'Activated')
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            // On additionne le TotalAmount de chaque commande activée du compte
            Decimal totalCA = 0;
            for (Order ord : acc.Orders) {
                totalCA += ord.TotalAmount;
            }

            // On affecte le nouveau CA calculé au compte
            acc.Chiffre_d_affaire__c = totalCA;
            accountsToUpdate.add(acc);
        }

        // On sauvegarde tous les comptes en une seule opération DML
        // (si la liste est vide, on évite un update inutile)
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}
