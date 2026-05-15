// CLASSE DE TEST : testUpdateAllAccounts
// RÔLE : Vérifie que le batch UpdateAllAccounts recalcule correctement le CA
//         de tous les comptes ayant des commandes activées.
//
// COUVERTURE VISÉE : UpdateAllAccounts.cls + UpdateAccounts.cls (via le batch)
//
// RAPPEL : Un batch Apex traite des milliers d'enregistrements par lots.
//          Dans les tests, Database.executeBatch() simule l'exécution complète du batch.
//          Test.startTest()/stopTest() force le batch à s'exécuter de façon synchrone
//          (normalement il s'exécute de façon asynchrone en dehors des tests).

@isTest
private class testUpdateAllAccounts {

    // TEST 1 : Le batch met bien à jour le CA d'un compte avec des commandes activées
    // SCÉNARIO MÉTIER : Après une migration de données, on lance le batch pour recalculer
    //                   le CA de tous les comptes. Un compte avec une commande de 450€ activée
    //                   doit voir son CA mis à jour à 450€.
    @isTest
    static void testBatchUpdatesAccountCA() {
        // --- ARRANGE : on crée une commande déjà activée (simulant des données migrées) ---
        Account acc = FashaTestDataFactory.createAccount('Batch Test Account');
        Product2 product = FashaTestDataFactory.createProduct('Chemise Verte longue XYX', 'Chemise');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 150);

        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        // 3 lignes obligatoires (règle de validation de l'org)
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 150);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 150);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 150);
        // On active la commande avant de lancer le batch (simule une commande déjà existante)
        ord.Status = 'Activated';
        update ord;

        // --- ACT : on lance le batch ---
        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest(); // force l'exécution synchrone du batch

        // --- ASSERT ---
        Account updatedAcc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        // CA attendu : 3 lignes x 150€ = 450€
        System.assertEquals(450, updatedAcc.Chiffre_d_affaire__c, 'Le batch doit calculer CA = 450 (3 x 150)');
    }

    // TEST 2 : Le batch ignore les comptes dont les commandes sont en Draft
    // SCÉNARIO MÉTIER : Un compte avec uniquement des commandes non confirmées
    //                   ne doit PAS apparaître dans le calcul du CA.
    @isTest
    static void testBatchExcludesDraftOrders() {
        // --- ARRANGE : un compte avec une commande en statut Draft (non activée) ---
        Account acc = FashaTestDataFactory.createAccount('Draft Only Account');
        Product2 product = FashaTestDataFactory.createProduct('Pantalon Kaki', 'Pantalon');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 80);
        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 80);
        // La commande reste en 'Draft' → ne doit pas être comptée

        // --- ACT ---
        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest();

        // --- ASSERT : le CA doit rester à 0 (compte pas traité par le batch) ---
        Account updatedAcc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, updatedAcc.Chiffre_d_affaire__c == null ? 0 : updatedAcc.Chiffre_d_affaire__c,
            'Le batch ne doit pas traiter les comptes sans commande Activated');
    }
}
