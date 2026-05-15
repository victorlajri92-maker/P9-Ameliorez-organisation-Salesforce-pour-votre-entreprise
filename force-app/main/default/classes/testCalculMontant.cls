// CLASSE DE TEST : testCalculMontant
// RÔLE : Vérifie que le trigger CalculMontant calcule correctement le champ NetAmount__c
//         (montant net = total - frais de port) pour chaque commande.
//
// COUVERTURE VISÉE : CalculMontant.trigger
//
// RAPPEL MÉTIER : NetAmount = TotalAmount - ShipmentCost
//                 Ce champ permet aux commerciaux de voir le revenu réel d'une commande
//                 après déduction des coûts de livraison.

@isTest
private class testCalculMontant {

    // TEST 1 : Calcul standard avec un frais de port renseigné
    // SCÉNARIO MÉTIER : Une commande de 200€ avec 30€ de port → NetAmount doit afficher 170€.
    @isTest
    static void testNetAmountCalculation() {
        // --- ARRANGE ---
        Account acc = FashaTestDataFactory.createAccount('Test Account Calcul');
        Product2 product = FashaTestDataFactory.createProduct('Robe Rouge', 'Robe');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 100);
        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        // 1 ligne : quantité 2 x 100€ = TotalAmount de 200€
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 2, 100);

        // --- ACT : on renseigne les frais de port, ce qui déclenche le trigger before update ---
        Test.startTest();
        ord.ShipmentCost__c = 30;
        update ord; // → déclenche CalculMontant (before update) → NetAmount = 200 - 30 = 170
        Test.stopTest();

        // --- ASSERT ---
        Order updatedOrder = [SELECT NetAmount__c, TotalAmount FROM Order WHERE Id = :ord.Id];
        // On vérifie que NetAmount = TotalAmount réel de la commande - 30
        System.assertEquals(updatedOrder.TotalAmount - 30, updatedOrder.NetAmount__c,
            'NetAmount doit être TotalAmount - ShipmentCost');
    }

    // TEST 2 : Frais de port null (pas encore renseigné)
    // SCÉNARIO MÉTIER : Une commande sans frais de port → NetAmount = TotalAmount entier.
    //                   Le trigger doit gérer le null sans planter (protection anti-NullPointerException).
    @isTest
    static void testNetAmountWithNullShipmentCost() {
        // --- ARRANGE ---
        Account acc = FashaTestDataFactory.createAccount('Null Shipment Account');
        Product2 product = FashaTestDataFactory.createProduct('Jupe Verte', 'Jupe');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 50);
        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        // 3 lignes : 3 x 50€ = TotalAmount de 150€
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 3, 50);

        // --- ACT ---
        Test.startTest();
        ord.ShipmentCost__c = null; // frais de port absent
        update ord; // → trigger calcule : total(150) - shipment(0) = 150
        Test.stopTest();

        // --- ASSERT ---
        Order updatedOrder = [SELECT NetAmount__c, TotalAmount FROM Order WHERE Id = :ord.Id];
        System.assertEquals(updatedOrder.TotalAmount, updatedOrder.NetAmount__c,
            'NetAmount doit égaler TotalAmount quand ShipmentCost est null');
    }

    // TEST 3 : Calcul en masse sur 200 commandes (test de bulkification)
    // SCÉNARIO MÉTIER : Import via Data Loader de 200 commandes avec frais de port.
    //                   Avant la correction, seule la 1re commande était mise à jour.
    //                   Ce test vérifie que TOUTES les commandes sont correctement calculées.
    @isTest
    static void testBulkNetAmountCalculation() {
        // --- ARRANGE ---
        Account acc = FashaTestDataFactory.createAccount('Bulk Calcul Account');
        Product2 product = FashaTestDataFactory.createProduct('Manteau Gris', 'Manteau');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 200);
        // 200 commandes, chacune avec 3 lignes à 200€ → TotalAmount = 600€ par commande
        List<Order> orders = FashaTestDataFactory.createBulkOrders(acc.Id, pbe.Id, 200, 200);

        // --- ACT ---
        Test.startTest();
        for (Order ord : orders) {
            ord.ShipmentCost__c = 20; // 20€ de frais de port sur chaque commande
        }
        update orders; // → déclenche le trigger sur 200 commandes
        Test.stopTest();

        // --- ASSERT : chaque commande doit avoir NetAmount = TotalAmount - 20 ---
        List<Order> updatedOrders = [SELECT NetAmount__c, TotalAmount FROM Order WHERE AccountId = :acc.Id];
        for (Order ord : updatedOrders) {
            System.assertEquals(ord.TotalAmount - 20, ord.NetAmount__c,
                'Chaque commande doit avoir NetAmount = TotalAmount - 20');
        }
    }
}
