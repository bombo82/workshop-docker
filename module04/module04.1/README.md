# Workshop Docker - Modulo 4.1

In questo modulo elenco una serie di caratteristiche che i container dovrebbero possedere.
Rispettare queste caratteristiche è fondamentale per creare immagini e container di qualità, efficienti e mantenibili nel tempo.

## Immutabili
Si, avete capito bene... __immutabili__ nel senso che dobbiamo applicare il principio _Immutable Infrastructure_ ai nostri container.
In pratica dobbiamo rispettare le seguenti regole:
* NON installare nuovi pacchetti
* NON aggiornare (o retrocedere) pacchetti presenti
* NON rimuovere pacchetti
* NON modificare i file di configurazione (interni al container)
* NON modificare il codice dell'applicazione

__Neanche _Vulnerabilità di Sicurezza_, _piccoli bugfix_ o _Urgenti fix a bug bloccanti_ sono delle motivazioni valide per andare contro questo principio.__

Le motivazioni? Le trovate in questa presentazione fatta da Jérôme Petazzoni
[Immutable infrastructure with Docker and containers (GlueCon 2015)](https://www.slideshare.net/jpetazzo/immutable-infrastructure-with-docker-and-containers-gluecon-2015)

## Effimeri
Le immagini definite dai nostri _Dockerfile_ devono generare dei container effimeri.
Cosa significa effimero? Semplicemente che dobbiamo poter stoppare e distruggere il container senza alcun problema.
Una volta creato un nuovo container dalla stessa immagine, eventualmente da una nuova versione, esso deve sostituire il precedente senza alcun intervento esterno per il set up e le configurazioni.

Possiamo ottenere questo comportamento usando questi accorgimenti:
* evitare di salvare i dati all'interno del container
* utilizzare volumi per salvare i dati
  * filesystem usati dalle applicazioni
  * storage usato dai database
* salvare le configurazioni esternamente al container
  * repository e.g. git
  * file di configurazione esterni, passati al container tramite apposite istruzioni

## Minimali
In generale, è buona norma avere solo il minimo necessario per eseguire l'applicazione.
Questo è un elenco di buone pratiche valido per creare dei Dockerfile efficienti:
* usare .dockerignore per escludere i file e le directory che non ci servono all'interno del container, ma senza sconvolgere la struttura del repository dei sorgenti
* non installare pacchetti del sistema operativo non necessari
* rimuovere eventuali cache interne al container e.g. quelle generate dai gestori dei pacchetti (apt, yum, etc.)
* minimizzare il numero di layer. Le istruzioni __RUN__, __COPY__ e __ADD__ committano il layer creato, mentre i layer creati dalle altre istruzioni sono temporanei
* suddividere i comandi inseriti nei __RUN__ su più righe e ordinarli alfabeticamente (ove possibile). Questo piccolo accorgimento rende più ordinato il Dockerfile e ci aiuta a identificare le duplicazioni del codice
* ordinare i comandi dal più generico a quello più specifico... questo ci permette di sfruttare la cache e riusare i layer tra differenti immagini

___

[home](../../README.md) [up](../README.md)  [next](../module04.2/README.md)

Copyright (C) 2018-2019 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
