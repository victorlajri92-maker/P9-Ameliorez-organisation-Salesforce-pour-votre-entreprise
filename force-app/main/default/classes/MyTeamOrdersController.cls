// CLASSE : MyTeamOrdersController
// RÔLE MÉTIER : Fournit au composant LWC "orders" le total des commandes activées
//               pour un compte client donné. Affiché directement sur la fiche du compte
//               dans Salesforce, ce montant permet au commercial de voir en un coup d'œil
//               le chiffre d'affaires généré par ce client.
// EXEMPLE : Sur la fiche du compte "Maison Leclerc", le composant affiche
//           "Total des Commandes : 1 354 390 €"

public with sharing class MyTeamOrdersController {

    // MÉTHODE : getSumOrdersByAccount
    // Appelée automatiquement par le composant LWC via @wire (liaison réactive)
    // @AuraEnabled(cacheable=true) : rend la méthode accessible depuis un composant LWC
    //                               "cacheable" = Salesforce peut mettre le résultat en cache
    //                               pour améliorer les performances (lecture seule)
    // Paramètre : accountId = l'ID du compte actuellement affiché dans Salesforce
    @AuraEnabled(cacheable=true)
    public static Decimal getSumOrdersByAccount(Id accountId) {

        // Requête d'agrégation : SUM(TotalAmount) additionne tous les TotalAmount
        // On filtre par :
        //   - AccountId = le compte affiché (pas toutes les commandes de l'org !)
        //   - Status = 'Activated' (on ne compte pas les commandes en cours ou annulées)
        AggregateResult groupedResults = [SELECT SUM(TotalAmount) total
                                          FROM Order
                                          WHERE AccountId = :accountId
                                          AND Status = 'Activated'];

        // SUM peut retourner null si aucune commande ne correspond → on renvoie 0 dans ce cas
        // pour que le composant LWC affiche le message d'erreur "montant égal à 0"
        Decimal result = (Decimal)groupedResults.get('total');
        return result != null ? result : 0;
    }
}
