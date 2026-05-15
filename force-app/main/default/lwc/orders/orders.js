// COMPOSANT LWC : orders (orders.js)
// RÔLE MÉTIER : Affiche le total des commandes activées d'un compte client directement
//               sur sa fiche Salesforce. Si le total est 0 ou qu'il n'y a pas de commandes,
//               un message d'erreur en rouge est affiché. Sinon, le total apparaît en vert.
//
// Ce fichier JS gère la logique du composant (récupération des données, calcul d'affichage).
// Le fichier orders.html gère l'affichage visuel.

// Imports nécessaires au fonctionnement d'un composant LWC
import { LightningElement, api, wire } from 'lwc';
// On importe la méthode Apex qui va chercher le total des commandes côté serveur Salesforce
import getSumOrdersByAccount from '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount';

export default class Orders extends LightningElement {

    // @api recordId : récupère automatiquement l'ID du compte actuellement ouvert dans Salesforce
    // Sans ce champ, le composant ne saurait pas pour quel compte afficher les données
    @api recordId;

    // Variable qui stocke le total des commandes récupéré depuis Salesforce
    // Initialement undefined, elle est remplie par le @wire ci-dessous
    sumOrdersOfCurrentAccount;

    // @wire : liaison réactive avec la méthode Apex
    // Dès que recordId change (ex : on ouvre un autre compte), la méthode est ré-appelée automatiquement
    // { data, error } = résultat de l'appel Apex (data = succès, error = erreur)
    @wire(getSumOrdersByAccount, { accountId: '$recordId' })
    wiredOrders({ error, data }) {
        if (data !== undefined) {
            // Succès : on stocke le total pour l'afficher dans le HTML
            this.sumOrdersOfCurrentAccount = data;
        } else if (error) {
            // Erreur Apex : on l'affiche dans la console pour faciliter le débogage
            console.error(error);
        }
    }

    // GETTER : hasOrders
    // Utilisé dans le HTML pour décider quel bloc afficher (erreur ou succès)
    // Retourne true si le total est > 0, false sinon
    // Un getter se comporte comme une propriété calculée : le HTML peut l'appeler avec {hasOrders}
    get hasOrders() {
        return this.sumOrdersOfCurrentAccount > 0;
    }
}
