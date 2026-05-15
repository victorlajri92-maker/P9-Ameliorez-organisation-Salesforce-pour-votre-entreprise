// CLASSE DE TEST : testUpdateAccountCA
// RÔLE : Vérifie que le trigger UpdateAccountCA met correctement à jour
//         le chiffre d'affaires (Chiffre_d_affaire__c) d'un compte client
//         lorsqu'une commande passe au statut 'Activated'.
//
// COUVERTURE VISÉE : UpdateAccountCA.trigger + UpdateAccounts.cls
//
// RÈGLE IMPORTANTE : les tests Salesforce s'exécutent dans un environnement isolé.
//                    Les données créées ici n'impactent pas les vraies données de l'org.

@isTest
private class testUpdateAccountCA {

    // TEST 1 : Activation d'une seule commande
    // SCÉNARIO MÉTIER : Un commercial active la commande d'un client.
    //                   Le CA du compte doit être mis à jour immédiatement.
    @isTest
    static void testSingleOrderActivation() {
        // --- ARRANGE : on prépare les données de test ---
        Account acc = FashaTestDataFactory.createAccount('Test Account');
        Product2 product = FashaTestDataFactory.createProduct('Chemise Bleue', 'Chemise');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 100);
        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        // 3 lignes de commande obligatoires (règle de validation de l'org)
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 100);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 100);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 100);

        // --- ACT : on exécute l'action à tester (activation de la commande) ---
        // Test.startTest() / stopTest() isole la transaction et réinitialise les limites governor
        Test.startTest();
        ord.Status = 'Activated';
        update ord; // → déclenche le trigger UpdateAccountCA
        Test.stopTest();

        // --- ASSERT : on vérifie que le résultat est correct ---
        // On relit le compte depuis la base pour avoir les valeurs à jour
        Account updatedAcc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        // CA attendu : 3 lignes x 100€ = 300€
        System.assertEquals(300, updatedAcc.Chiffre_d_affaire__c, 'Le CA doit être 300 (3 x 100)');
    }

    // TEST 2 : Activation de 200 commandes en une seule fois (test de bulkification)
    // SCÉNARIO MÉTIER : Import massif via Data Loader — 200 commandes activées simultanément.
    //                   Le trigger doit gérer ce volume sans dépasser les limites Salesforce.
    @isTest
    static void testBulkOrderActivation() {
        // --- ARRANGE ---
        Account acc = FashaTestDataFactory.createAccount('Bulk Test Account');
        Product2 product = FashaTestDataFactory.createProduct('Veste Noire', 'Veste');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 50);
        // Création de 200 commandes (chacune avec 3 lignes à 50€)
        List<Order> orders = FashaTestDataFactory.createBulkOrders(acc.Id, pbe.Id, 200, 50);

        // --- ACT ---
        Test.startTest();
        for (Order ord : orders) {
            ord.Status = 'Activated';
        }
        update orders; // → déclenche le trigger sur 200 commandes en même temps
        Test.stopTest();

        // --- ASSERT ---
        Account updatedAcc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        // CA attendu : 200 commandes x 3 lignes x 50€ = 30 000€
        System.assertEquals(200 * 50 * 3, updatedAcc.Chiffre_d_affaire__c, 'Le CA bulk doit être 30000 (200 x 3 items x 50)');
    }

    // TEST 3 : Mise à jour sans changement de statut
    // SCÉNARIO MÉTIER : On modifie un champ de la commande (ex : frais de port)
    //                   sans la passer à 'Activated'. Le CA du compte NE DOIT PAS changer.
    @isTest
    static void testNoTriggerWhenStatusUnchanged() {
        // --- ARRANGE ---
        Account acc = FashaTestDataFactory.createAccount('Unchanged Status Account');
        Product2 product = FashaTestDataFactory.createProduct('Pantalon', 'Pantalon');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 75);
        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 75);

        // --- ACT : on modifie la commande sans changer son statut ---
        Test.startTest();
        ord.ShipmentCost__c = 10; // modification d'un champ, statut reste 'Draft'
        update ord; // → le trigger NE DOIT PAS se déclencher (condition sur statut)
        Test.stopTest();

        // --- ASSERT : le CA reste à 0 (ou null) car la commande n'est pas activée ---
        Account updatedAcc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, updatedAcc.Chiffre_d_affaire__c == null ? 0 : updatedAcc.Chiffre_d_affaire__c,
            'Le CA ne doit pas être mis à jour si le statut reste Draft');
    }
}
