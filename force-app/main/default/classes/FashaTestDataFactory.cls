// CLASSE : FashaTestDataFactory
// RÔLE : Fabrique de données de test réutilisables pour les classes de test du projet Fasha.
//        Au lieu de dupliquer la création de comptes/produits/commandes dans chaque test,
//        on centralise ici toutes les méthodes de création.
//        Nommée "FashaTestDataFactory" (et non "TestDataFactory") pour éviter de
//        conflictuer avec une classe du même nom déjà existante dans l'org Salesforce.
//
// UTILISATION : appelée depuis testUpdateAccountCA, testCalculMontant,
//               testUpdateAllAccounts et testMyTeamOrdersController
//
// @isTest = cette classe n'existe QUE dans le contexte de test, jamais en production

@isTest
public class FashaTestDataFactory {

    // Crée et insère un compte client (Account) avec le nom donné
    // Retourne le compte créé pour pouvoir utiliser son Id dans les tests
    public static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    // Crée et insère un produit (Product2) avec un nom et une famille (ex: 'Chemise', 'Veste')
    // Le produit doit être actif (IsActive = true) pour être utilisable dans un catalogue de prix
    public static Product2 createProduct(String name, String family) {
        Product2 product = new Product2(Name = name, Family = family, IsActive = true);
        insert product;
        return product;
    }

    // Crée et insère une entrée de catalogue de prix (PricebookEntry)
    // Une PricebookEntry = l'association entre un produit et son prix dans le catalogue standard
    // Obligatoire pour pouvoir ajouter des lignes de commande (OrderItem) à une commande
    public static PricebookEntry createPricebookEntry(Id productId, Decimal unitPrice) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), // catalogue de prix standard de l'org
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    // Crée et insère une commande (Order) pour un compte donné avec un statut initial
    // EffectiveDate = date d'effet de la commande (obligatoire dans Salesforce)
    // Pricebook2Id = catalogue de prix utilisé (obligatoire pour ajouter des lignes)
    public static Order createOrder(Id accountId, String status) {
        Order ord = new Order(
            AccountId = accountId,
            Status = status,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;
        return ord;
    }

    // Crée et insère une ligne de commande (OrderItem) sur une commande existante
    // Quantity x UnitPrice = TotalPrice de la ligne → contribue au TotalAmount de la commande
    public static OrderItem createOrderItem(Id orderId, Id pricebookEntryId, Integer quantity, Decimal unitPrice) {
        OrderItem item = new OrderItem(
            OrderId = orderId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = unitPrice
        );
        insert item;
        return item;
    }

    // Crée N commandes en statut 'Draft' avec 3 lignes de commande chacune
    // Utilisée pour tester la BULKIFICATION : vérifier que le code fonctionne avec 200+ enregistrements
    // IMPORTANT : 3 lignes par commande minimum → règle de validation de l'org Fasha
    //             ("Panier insuffisant : 3 produits minimum requis pour un Particulier")
    // Optimisation : toutes les commandes sont insérées en 1 DML, toutes les lignes en 1 DML
    public static List<Order> createBulkOrders(Id accountId, Id pricebookEntryId, Integer count, Decimal unitPrice) {
        // Préparation de toutes les commandes en mémoire avant insertion
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < count; i++) {
            orders.add(new Order(
                AccountId = accountId,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = Test.getStandardPricebookId()
            ));
        }
        insert orders; // 1 seule opération DML pour toutes les commandes

        // Préparation de 3 lignes par commande en mémoire avant insertion
        List<OrderItem> items = new List<OrderItem>();
        for (Order ord : orders) {
            items.add(new OrderItem(OrderId = ord.Id, PricebookEntryId = pricebookEntryId, Quantity = 1, UnitPrice = unitPrice));
            items.add(new OrderItem(OrderId = ord.Id, PricebookEntryId = pricebookEntryId, Quantity = 1, UnitPrice = unitPrice));
            items.add(new OrderItem(OrderId = ord.Id, PricebookEntryId = pricebookEntryId, Quantity = 1, UnitPrice = unitPrice));
        }
        insert items; // 1 seule opération DML pour toutes les lignes

        return orders;
    }
}
