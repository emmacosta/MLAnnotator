# AnnotatorML

L'applicazione permette di annotare immagini mediche su iPad, selezionando con Apple Pencil un'area chiusa che identifica una parte di interesse e inviando al server le coordinate corrispondenti ai punti che la delimitano.
L'utilizzo è facilitato da un algoritmo che chiude automaticamente tratti (singoli o multipli) se i vertici sono sufficientemente vicini; è possibile annullare l'ultimo tratto effettuato, oltre che muovere l'immagine e zoommare per annotazioni più precise.
È presente un login che identifica l'utente con username e password e salva i dati in memoria persistente.


### Sviluppo
L'app è stata sviluppata con il linguaggio Swift e i framework SwiftUI e PencilKit.


### Requisiti
- iOS 16+
- XCode 14.2

### To-do
Tra i possibili miglioramenti dell'app si segnalano:
- Rimozione della conferma di invio per rendere più veloce il processo di annotazione;
- Possibilità di tornare all'annotazione dell'immagine precedente;
- Funzione "annulla" che ridisegna l'ultimo tratto cancellato.
