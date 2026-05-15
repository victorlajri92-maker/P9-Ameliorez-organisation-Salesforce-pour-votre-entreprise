// TRIGGER : UpdateAccountCA
// RÔLE MÉTIER : Quand une commande passe au statut "Activated" (commande confirmée),
//               ce trigger met automatiquement à jour le chiffre d'affaires (CA)
//               du compte client associé.
// EXEMPLE : Le commercial Dupont active la commande 1042 pour le client "Maison Leclerc"
//           → le CA de "Maison Leclerc" est recalculé immédiatement.
//
// SE DÉCLENCHE : après la mise à jour (after update) d'une commande (Order)

trigger UpdateAccountCA on Order (after update) {

    // Étape 1 : on collecte les IDs des comptes dont AU MOINS une commande
    // vient de passer au statut 'Activated' dans cette transaction.
    // On compare le nouveau statut (Trigger.new) avec l'ancien (Trigger.oldMap)
    // pour ne réagir qu'au moment précis du changement.
    Set<Id> accountIds = new Set<Id>();

    for (Order ord : Trigger.new) {
        Order oldOrd = Trigger.oldMap.get(ord.Id);
        // On ne traite que les commandes qui viennent de passer à 'Activated'
        // (pas celles qui étaient déjà activées, pas celles qui restent en Draft)
        if (ord.AccountId != null && ord.Status == 'Activated' && oldOrd.Status != 'Activated') {
            accountIds.add(ord.AccountId);
        }
    }

    // Étape 2 : si au moins un compte est concerné, on délègue le calcul
    // à la classe UpdateAccounts (logique métier séparée du trigger = bonne pratique)
    if (!accountIds.isEmpty()) {
        UpdateAccounts.updateAccountCA(accountIds);
    }
}
