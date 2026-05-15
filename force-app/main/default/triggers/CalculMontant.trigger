// TRIGGER : CalculMontant
// RÔLE MÉTIER : Calcule automatiquement le montant net (NetAmount) de chaque commande
//               en soustrayant les frais de livraison (ShipmentCost) du montant total (TotalAmount).
//               NetAmount = TotalAmount - ShipmentCost
// EXEMPLE : Une commande de 500€ avec 30€ de frais de port → NetAmount = 470€
//           Ce champ est affiché aux commerciaux pour voir le revenu réel après port.
//
// SE DÉCLENCHE : avant la mise à jour (before update) d'une commande (Order)
//               "before" = on modifie les champs avant que Salesforce enregistre en base
//               → pas besoin de faire un update() explicite, Salesforce sauvegarde automatiquement.

trigger CalculMontant on Order (before update) {

    // On boucle sur TOUTES les commandes de la transaction (bulkification).
    // Avant la correction, le code utilisait Trigger.new[0] → seule la 1re commande
    // était traitée lors d'un import en masse via Data Loader. Maintenant toutes le sont.
    for (Order newOrder : Trigger.new) {

        // Protection contre les valeurs null : si un champ est vide, on le remplace par 0
        // pour éviter une erreur de calcul (NullPointerException)
        Decimal total = newOrder.TotalAmount != null ? newOrder.TotalAmount : 0;
        Decimal shipment = newOrder.ShipmentCost__c != null ? newOrder.ShipmentCost__c : 0;

        // Calcul et affectation du montant net pour cette commande
        newOrder.NetAmount__c = total - shipment;
    }
}
