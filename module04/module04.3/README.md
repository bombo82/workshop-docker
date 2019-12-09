# Workshop Docker - Modulo 4.3

GitHub è pieno di Dockerfile, ma non tutti i Dockerfile sono creati allo stesso modo!
L'efficienza e la qualità dei container passa attraverso le immagini da cui sono istanziati e ha proprio origine nei Dockerfile che scriviamo.
In questo post vorrei mostrarvi alcuni piccoli accorgimenti per creare dei Dockerfile migliori.

Lo scopo di questo modulo è fornire consigli pratici, non nozioni teoriche, quindi lavoriamo su un Dockerfile _reale_ e proviamo a migliorarlo attraverso un processo simile al refactoring.
Ho identificato le seguenti aree su cui intervenire: build time incrementale, dimensione, sicurezza, mantenibilità e riproducibilità.

```dockerfile
FROM centos

COPY ../_drafts /app

RUN yum -y update
RUN yum -y install java-11-openjdk openssh vim

CMD ["java", "-jar", "/app/target/app-x.y.z.jar"]
```

## Incremental build time
Quando sviluppiano del software ci troviamo spesso a fare piccole modifiche ai sorgenti, compilare, creare l'immagine docker, farne il deploy ed eseguire i test.
Avete mai sentito parlare del concetto di **10 minutes build**?? E' una delle pratiche XP e, senza essere rigorosi sui 10 min, in pratica significa ridurre il tempo delle build ottimizzando e automatizzando il processo!

Il processo di creazione delle immagini è _incrementale by design_ e il primo trucco è quello di sfruttarlo in modo efficiente ottimizzando i layer e la cache.

### Tip 1: l'ordine dei comandi
L'ordine dei **build steps** (istruzioni nel Dockerfile) è importante, perché per ogni istruzione (o quasi), viene creato un layer intermedio e inserito in una cache da parte di docker.
La cache viene invalidata quando un'istruzione nel Dockerfile viene modificata oppure i file su cui essa lavora vengono modificati; ovviamente, viene invalidata la cache per il layer creato da quella istruzione e per tutti i layer successivi.
Ordina le istruzioni per sfruttare al meglio la cache e ridurre i tempi di build, in altre parole fai in modo che gli step modificati più di rado siano in cima, mentre quelli modificati più spesso siano in fondo al file.

```dockerfile
FROM centos

RUN yum -y update
RUN yum -y install java-11-openjdk openssh vim

COPY . /app

CMD ["java", "-jar", "/app/target/app-x.y.z.jar"]
```

Nell'esempio sopra abbiamo spostato l'istruzione di **COPY** dopo quelle che installano Java, questo perché la frequenza con cui aggiorneremo la nostra applicazione è superiore a quella con cui viene aggiornato Java e gli altri pacchetti del sistema operativo. 
### Tip 2: copia solo quello che serve
Copia all'interno dell'immagine solo quello che serve! L'affermazione ha due differenti risvolti: 1. riduzione della dimensione delle immagini, 2. la cache viene invalidata solo quando serve.
Se copiamo un'intera cartella, qualsiasi modifica a uno dei file presente in quella cartella invalida la cache; mentre, se copiamo solo i file che realmente ci servono, la cache viene invalidata solo quando uno dei _file utili_ cambia.

```dockerfile
FROM centos

RUN yum -y update
RUN yum -y install java-11-openjdk openssh vim

WORKDIR /app
COPY target/app-x.y.z.jar /app

CMD ["java", "-jar", "/app/app-x.y.z.jar"]
```

Nell'esempio sopra ci serve solo il file `target/app-x.y.z.jar`, quindi copiamo solo quel file, anziché tutto il contenuto della cartella padre.

### Tip 3: identificare e raggruppare le _unità_ cacheable
Ogni istruzione **RUN** crea un layer intermedio e lo inserisce nella cache.
Nel nostro esempio le istruzioni Linux `yum -y update` e `yum -y install ...` possono essere considerate un blocco unico dato che la cache dovrebbe essere valida per entrambi oppure per nessuno.

```dockerfile
FROM centos

RUN yum -y update \
    && yum -y install java-11-openjdk openssh vim

WORKDIR /app
COPY target/app-x.y.z.jar /app

CMD ["java", "-jar", "/app/app-x.y.z.jar"]
```

Inoltre, quando usiamo un gestore dei pacchetti per installare qualcosa è buona pratica metterli nello stesso **RUN**, questo ci aiuta ad avere più coerenza nei pacchetti installati ed evita che possano essere installati pacchetti obsoleti.

## Ridurre le dimensioni delle immagini
Immagini più piccole non solo occupano meno spazio, ma sono più rapide da spostare tramite la rete.
La rapidità di deploy e start delle immagini è un fattore molto importante quando abbiamo micro-servizi che possono scalare, oppure quando abbiamo un cluster che potrebbe distribuire il carico runtime tra differenti nodi fisici.

Il **_Tip 2: copia solo quello che serve_** vale anche in questo caso!

### Tip 4: installa solo il necessario
I container non sono una macchina virtuale in cui è necessario **ssh**, oppure in cui è utile avere una _toolchain_ basilare con alcuni strumenti installati di default (in realtà questo fatto è discutibile pure per le VM).
I container sono oggetti a cui non accederemo e devono avere solo i pacchetti utili alla loro funzione, quindi nessuna _toolchain_ e niente software non necessario al loro scopo!

```dockerfile
FROM centos

RUN yum -y update \
    && yum -y install java-11-openjdk

WORKDIR /app
COPY target/app-x.y.z.jar /app

CMD ["java", "-jar", "/app/app-x.y.z.jar"]
```

Rendere i container minimali ha anche un side-effect positivo sulla sicurezza, riducendo la _attack surface_.

**NOTA:** alcune distribuzioni installano in automatico delle dipendenze non strettamente necessarie all'esecuzione del pacchetto che vogliamo installare e che ovviamente preferiremmo che non ci fossero!
I gestori dei pacchetti hanno delle opzioni per evitare che questi pacchetti aggiuntivi vengano installati.

### Tip 5: rimuovi le cache e i file temporanei
Quando installiamo dei pacchetti tramite il gestore della distribuzione oppure scarichiamo dei file compressi che dobbiamo scompattare ci troviamo nella situazione in cui abbiamo generato dei dati temporanei o delle cache.

```dockerfile
FROM centos

RUN yum -y update \
    && yum -y install java-11-openjdk \
    && yum -y clean all

WORKDIR /app
COPY target/app-x.y.z.jar /app

CMD ["java", "-jar", "/app/app-x.y.z.jar"]
```

Rimuovere i queste cache e questi dati temporanei permette di ridurre di parecchio la dimensione delle immagini.

## Sicurezza
Questo argomento è veramente vasto e sicuramente farò alcuni post su questo tema, ma vi lascio ugualmente qualche consiglio spiccio!
Ridurre la _attack surface_ installando solo il minimo indispensabile per l'esecuzione delle applicazioni è una delle regole fondamentali della sicurezza!
Un'altra regola è quella di mantenere aggiornate le applicazioni, ma **NON FRAINTENDETE** la mia frase! _NON_ aggiornate il software all'interno dei container, bensì _create una nuova immagine_ con il software aggioranto!
Se i server _"dovrebbero"_ essere **immutabili**, i container è _mandatorio_ che lo siano!

## Mantenibilità
Questa proprietà è molto importante e implica parecchie di cose! Faccio un breve elenco: scrivi codice ordinato e leggibile per i tuoi colleghi e per chi lo leggerà in futuro; non ripeterti, in altre parole evita il copia-incolla; non fare quello che altri hanno già fatto al posto tuo; tutti i file sorgenti/testuali vanno salvati in un repository.

### Tip 6: usa le immagini ufficiali
Preferisci le immagini ufficiali... insomma non re-inventare l'acqua calda!
Se esiste una versione ufficiale (a.k.a. stabile, testata e sicura) usala!
Risparmiamo tempo e probabilmente l'immagine ha una qualità più alta di quella che faremmo io o te.

```dockerfile
FROM openjdk

WORKDIR /app
COPY target/app-x.y.z.jar /app

CMD ["java", "-jar", "/app/app-x.y.z.jar"]
```

Perfetto con il refactor di questo tip abbiamo praticamente buttato 2/3 dei refactor precedenti!
Solitamente le immagini ufficiali sono di qualità e adottano le migliori best practices, quindi dovrebbero rispettare tutti i consigli che ti ho dato fino a ora. 

### Tip 7: usa tag specifici
Ricorda che quando non specifichi il tag docker suppone che tu voglia usare l'ultima versione, quella con tag _latest_.
Potresti anche voler utilizzare l'ultima versione attualmente disponibile (oggi per Java è la 13), ma ti consiglio vivamente di mettere il tag della versione, altrimenti un giorno ti potresti ritrovare la successiva _major release_ e non capire perché non va più nulla!

```dockerfile
FROM openjdk:11-jre

WORKDIR /app
COPY target/app-x.y.z.jar /app

CMD ["java", "-jar", "/app/app-x.y.z.jar"]
```

### Tip 8: scegli la "variante" più adatta a te
Normalmente sono presenti più varianti per ogni versione delle immagini ufficiali.
Le varianti dipendono da quale immagine _parent_ gli sviluppatori sono partiti per creare quella che hanno pubblicato, ebbene sì! anche i Dockerfile delle immagini ufficiali hanno l'istruzione **FROM**.

Io prediligo quasi sempre le versioni basate su _Alpine Linux_... un po' per gusto personale, un po' perché sono estremamente minimali e di conseguenza piccole, leggere e veloci.
In alcuni casi ho utilizzato delle immagini basate su CentOS, quindi valutate di volta in volta in base al vostro caso d'uso.

## Riproducibilità
Concetto banale, quello che facciamo deve essere riproducibile! Non può funzionare solo sul nostro pc o solo una volta.
La via migliore per ottenere la riproducibilità è creare un ambiente consistente e automatizzato per creare le nostre immagini, ma di quello non ne parliamo!
Ci sono alcuni _tip_ che riguardano esclusivamente il Dockerfile e che possono essere veramente utili.

### Tip 9: l'immagine _"parent"_ è una dipendenza
I Dockerfile iniziano sempre con l'istruzione _FROM_ che definisce il padre, l'immagine base da cui partire, di conseguenza essa è una dipendenza del nostro Dockerfile.
Gestite il _FROM_ come se fosse una normale dipendenza esterna del vostro software, quindi scegliete se utilizzare una versione specifica oppure utilizzare l'ultima versione di una determinata _major release_.

Credo che non ci sia un _buono o cattivo_, ma dipende dall'applicazione e dal contesto.
L'unico consiglio assoluto che vi posso dare è di evitare la _latest_ (o omettere la versione), per il resto fate le stesse considerazioni che fareste per le dipendenze delle librerie dell'applicazione.

### Tip 10: evitate i numeri di versione "HARD-CODED"
Nel Dockerfile spesso è necessario scaricate qualcosa da Internet oppure passare dei file dall'esterno e solitamente essi contengono dei numeri di versione.
Avere un numero di versione **"HARD-CODED"** all'interno del Dockerfile di solito non è una buona cosa, piuttosto passate queste versioni dall'esterno come argomenti e parametrizzate le istruzioni.

```dockerfile
ARG JAVA_TAG
FROM openjdk:${JAVA_TAG}

ARG VERSION

WORKDIR /app
COPY target/app-${VERSION}.jar /app/app.jar

CMD ["java", "-jar", "/app/app.jar"]
```

In questo esempio ho paremetrizzato sia la versione dell'immagine padre sia la versione della nostra applicazione.
Raramente parametrizzo la versione del padre, mentre rendo sempre parametriche, eventualmente con valore di default, tutte le altre versioni!

**NOTA:** le istruzioni **ENTRYPOINT** e **CMD** quando utilizzate nella _"exec form"_ non valorizzano le variabili d'ambiente **ENV** e argomenti **ARG** definiti nel Dockerfile o passate dall'esterno.
E' pratica comune rinominare i file durante la copia per eliminare le eventuali parti "variabili".

### Tip 11: build esterne all'immagine
Ultimo tip della lista, ma non come importanza!
In realtà questa cosa l'ho sempre data per scontata e faccio veramente fatica a trovare un motivo ragionevole per scrivere un Dockerfile come quello sotto riportato...
ho visto alcuni che fanno le build delle applicazioni direttamente nel Dockerfile che crea l'immagine da rilasciare e rilasciano un'immagine con l'applicazione e tutta la _toolchain_ necessaria per compilare e testare.

Se qualcuno fra i lettori fa le build delle applicazioni direttamente nel Dockerfile, come nell'esempio sotto, sappia che posso aiutarlo... di mestiere faccio il coach!

```dockerfile
FROM maven:3.6-jdk-8-alpine
RUN git clone https://domain.example/~user/repository.git app
WORKDIR /app
RUN mvn -e -B package
CMD ["java", "-jar", "/app/app.jar"] 
```
Faccio fatica a concepire un Dockerfile come quello sopra e a trovare le parole giuste per proporvi una soluzione...
dai fate una bella pipeline di build applicando le buone pratiche del caso e ci mettete tutti gli step necessari: analisi statica, compilazione, test unitari, deploy, test d'integrazione/accettazione, controlli di sicurezza, etc., etc.

Se proprio avete un'allergia o un'intolleranza certificata per i build server e le pipeline fate almeno un Dockerfile multi-stage!
Tutti gli altri ignorino questo tip! Questo tip è come togliere la benda a chi sta guidando di notte, a fari spenti e bendato.
```dockerfile
FROM maven:3.6-jdk-8-alpine AS builder
RUN git clone https://domain.example/~user/repository.git app
WORKDIR /app
RUN mvn -e -B package

FROM openjdk:11-jre
COPY --from=builder /app/target/app.jar /
CMD ["java", "-jar", "/app.jar"]
```

___

[prev](../module04.2/README.md)  [home](../../README.md) [up](../README.md)

Copyright (C) 2018-2019 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
