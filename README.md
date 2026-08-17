# Pirate Isles: Crown of Tides

Gioco 2D isometrico completo realizzato con Godot 4.3 e GDScript.

## Gioco

Sei un capitano senza corona. Esplora un arcipelago, trova l'ingresso delle grotte, risolvi due enigmi, sconfiggi il guardiano e conquista tutte le cinque isole. Ogni territorio conquistato produce monete, utilizzabili per comprare armi più potenti.

Funzioni incluse:

- campagna completa con finale;
- cinque isole di difficoltà e rendita crescenti;
- dieci enigmi, cinque boss e ricompense;
- combattimento, negozio e tre livelli arma;
- salvataggio locale automatico;
- controlli tastiera/mouse e touch Android;
- interfaccia adattiva 1280×720;
- esportazione Windows e Android;
- workflow GitHub Actions per compilare Windows.

## Avvio in Godot

1. Installa Godot 4.3 o una versione 4.x compatibile.
2. Premi **Importa** e seleziona `project.godot`.
3. Premi **F6/F5** per avviare.

Controlli Windows: WASD/frecce per muoversi, E per entrare nella grotta, B per il negozio, spazio o clic per attaccare, Esc per la pausa.

## Compilazione tramite GitHub

Carica l'intera cartella in un repository GitHub usando **Add file → Upload files**. Apri **Actions → Build Windows → Run workflow**. Al termine scarica `PirateIsles-Windows` dalla sezione Artifacts.

Per Android installa in Godot i modelli di esportazione, configura Java SDK/Android SDK nelle impostazioni dell'editor, quindi usa **Progetto → Esporta → Android**.

## Grafica e licenze

La grafica base è generata dal gioco tramite primitive vettoriali originali: non dipende da siti esterni, funziona offline ed è liberamente modificabile. La cartella `assets/` è pronta per eventuali pacchetti CC0; prima di pubblicare, verifica sempre la licenza di ogni risorsa aggiunta.

## Multiplayer futuro

Il salvataggio, le isole e la progressione sono separati dalla presentazione per consentire una futura migrazione a server autorevole. La fase online richiederà server dedicato, account, sincronizzazione giocatori, database e protezioni anti-cheat: non è simulata in questa versione offline.

