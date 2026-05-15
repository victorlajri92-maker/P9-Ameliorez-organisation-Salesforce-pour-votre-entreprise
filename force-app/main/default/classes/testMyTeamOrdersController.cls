// CLASSE DE TEST : testMyTeamOrdersController
// RÔLE : Vérifie que la méthode getSumOrdersByAccount de MyTeamOrdersController
//         retourne bien le bon total de commandes pour un compte donné,
//         et gère correctement les cas limites (aucune commande, commandes en Draft).
//
// COUVERTURE VISÉE : MyTeamOrdersController.cls
//
// RAPPEL : MyTeamOrdersController alimente le composant LWC "orders" affiché
//           sur la fiche du compte Salesforce. Ces tests garantissent que
//           le chiffre affiché au commercial est toujours correct.

@isTest
private class testMyTeamOrdersController {

    // TEST 1 : Compte avec des commandes activées → doit retourner leur somme
    // SCÉNARIO MÉTIER : Le commercial ouvre la fiche du compte "Maison Leclerc".
    //                   Ce compte a une commande activée de 300€.
    //                   Le composant LWC doit afficher "Total des Commandes : 300".
    @isTest
    static void testGetSumWithActivatedOrders() {
        // --- ARRANGE ---
        Account acc = FashaTestDataFactory.createAccount('Controller Test Account');
        Product2 product = FashaTestDataFactory.createProduct('Chemise Test', 'Chemise');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 100);

        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        // 3 lignes x 100€ = TotalAmount 300€
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 100);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 100);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 100);
        // On active la commande pour qu'elle soit comptée
        ord.Status = 'Activated';
        update ord;

        // --- ACT : appel direct de la méthode Apex (sans passer par le LWC) ---
        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // --- ASSERT ---
        System.assertEquals(300, result, 'Le total doit être 300 (3 x 100)');
    }

    // TEST 2 : Compte sans aucune commande → doit retourner 0 (pas null)
    // SCÉNARIO MÉTIER : Un nouveau compte vient d'être créé, aucune commande rattachée.
    //                   Le composant LWC doit afficher le message d'erreur rouge
    //                   (car hasOrders = false quand result = 0).
    @isTest
    static void testGetSumWithNoOrders() {
        // --- ARRANGE : compte sans commande ---
        Account acc = FashaTestDataFactory.createAccount('Empty Account');

        // --- ACT ---
        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // --- ASSERT : la méthode doit retourner 0 et non null ---
        System.assertEquals(0, result, 'Le total doit être 0 si aucune commande');
    }

    // TEST 3 : Compte avec des commandes en Draft → ne doit PAS les compter
    // SCÉNARIO MÉTIER : Un client a des commandes en cours (Draft) mais aucune confirmée.
    //                   Le CA affiché doit être 0, pas le total des commandes non validées.
    @isTest
    static void testGetSumIgnoresDraftOrders() {
        // --- ARRANGE : commandes en Draft, non activées ---
        Account acc = FashaTestDataFactory.createAccount('Draft Orders Account');
        Product2 product = FashaTestDataFactory.createProduct('Veste Test', 'Veste');
        PricebookEntry pbe = FashaTestDataFactory.createPricebookEntry(product.Id, 200);

        Order ord = FashaTestDataFactory.createOrder(acc.Id, 'Draft');
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 200);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 200);
        FashaTestDataFactory.createOrderItem(ord.Id, pbe.Id, 1, 200);
        // On laisse la commande en 'Draft' → ne doit pas être incluse dans le total

        // --- ACT ---
        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // --- ASSERT ---
        System.assertEquals(0, result, 'Les commandes Draft ne doivent pas être comptées');
    }
}
