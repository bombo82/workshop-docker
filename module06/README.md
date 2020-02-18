# Workshop Docker - Modulo 6

Concetti in questo modulo:
- _docker-compose_ cos'è e perché usarlo?
- introduzione a _docker-compose_
- i comandi principali di _docker-compose_
- agire su un singolo servizio

Nei precedenti moduli abbiamo studiato il comando `docker` e visto come esso ci permette di interagire con la
_docker-engine_. In questo modulo iniziamo a parlare di _docker-compose_.

## Cos'è e perché usarlo?
_Compose_ è uno strumento che permette di definire, eseguire e, in generale, gestire delle applicazioni multi-container.
Tramite `docker-compose` è possibile utilizzare un singolo comando per creare e avviare tutti i container che compongono
la nostra applicazione. Il mattoncino base di _Compose_ sono i **services** (servizi) definiti al suo interno. Ad ogni
**service** è associata un'immagine, il nome del servizio stesso, una lista di configurazioni che definiscono come
questo **service** può interagire con gli altri ed eventualmente le configurazioni del **service** stesso. Nella
prossima parte vedremo più in dettaglio come definire un **service**.

Oltre alle funzionalità elencate sopra, _Compose_ ci offre le funzionalità tipiche di un orchestratore di servizi e.g.
gestione dell'ordine di avvio, delle dipendenze e scaling automatico dei servizi.

I motivi per utilizzare _Compose_ sono svariati, innanzi tutto nessuna applicazione oggigiorno è composta da un solo
servizio (container), e questo è vero anche quando non stiamo utilizzando un'architettura a micro-services. Pensate
banalmente a un'applicazione web, essa normalmente è composta dai seguenti componenti/servizi: front-end, back-end e
database. In questo caso avremmo 3 differenti immagini (una per ogni servizio) e tramite `docker-compose` possiamo
definire come esse interagiscono tra di loro: i servizi front-end e back-end espongono le proprie funzionalità al mondo
estreno tramite una porta HTTP, mentre il servizio database è raggiungibile solo dal servizio back-end. _Compose_ può
gestire anche le dipendenze e l'ordine di avvio, che in questo caso potrebbe essere: database, back-end e front-end.

Abbiamo capito perché è necessario utilizzare un orchestratore, la domanda diventa perché utilizzare `docker-compose`
come orchestratore? Ammetto che non ho una risposta assoluta e oggettiva a questa domanda, quindi vi dico perché io uso
`docker-compose`:
- è semplice da utilizzare (i concetti alla base sono gli stessi di _docker_)
- non richiede una configurazione iniziale
- si integra alla perfezione con _swarm_ (funzionalità di cluster nativa di docker)

## Introduzione 
_Compose_ è un tool che ci permette di comporre applicazioni multi-container e di orchestrarle in modo semplice ed
efficace. Le caratteristiche e funzionalità che rendono _Compose_ particolarmente efficace sono:
- ambienti differenti completamente isolati su un singolo host (o sullo stesso _swarm_)
- conservare i volumi dati
- idempotenza (ricrea solo i container modificati, avvia solo i container non avviati, etc.)
- uso di variabili per personalizzare gli ambienti mantenendo la stessa definizione dei servizi (stesso `docker-compose.yml)
- è possibile sfruttare la tecnica della composizione

Vi rimando alla [documentazione ufficiale](https://docs.docker.com/compose/) per le informazioni più approfondite
riguardo le funzionalità sopra elencate.

Le nostre "composizioni" sono definite tramite un file il cui nome di default è `docker-compose.yml`. Tale file
contiene l'elenco dei servizi che compongono la nostra applicazione multi-container. Nell'esempio sotto riportato
abbiamo 2 servizi: mongo e mongo-express. Essi sono basati sulle immagini ufficiali disponibili su dockerhub e per
entrambi abbiamo configurato la politica di riavvio (`restart: on-failure`), questa è una funzionalità tipica degli
orchestratori. Abbiamo inoltre configurato alcune variabili d'ambiente direttamente all'interno del file, ma esse
potrebbero essere definite esternamente come configurazioni di `Compose`. Il database "mongo" non espone alcuna porta,
di conseguenza non è raggiungibile dall'esterno, mentre "mongo-express", il client che accede al db, è esposto e
mappato sulla porta 8081; queste configurazioni rispecchiano i parametri dei comandi `docker container run` e `docker
 container start`. Per il servizio "mongo-express" abbiamo aggiunto la configurazione `depends_on` che permette di
definire l'ordine di avvio dei container.

```yaml
version: '3'
services:
  mongo:
    image: mongo
    restart: on-failure
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example

  mongo-express:
    image: mongo-express
    restart: on-failure
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: root
      ME_CONFIG_MONGODB_ADMINPASSWORD: example
    depends_on:
      - mongo
```

## I principali comandi
Ora che abbiamo definito un `docker-compose.yml` e visto i servizi che lo compongono e le loro configurazioni possiamo
vedere i comandi per avviare, fermare e gestire questi servizi/container. Nel modulo successivo vediamo come creare i
file da usare con _Compose_.

### Avviare i servizi
Lanciamo il comando `docker-compose up` per avviare i servizi. Esso crea i container relativi ai servizi presenti nel
file `docker-compose.yml` e li avvia. Il comando scarica le immagini da un _registry_ **solo se esse non sono presenti
in locale**, questo significa che se volessimo aggiornare la versione dei container dobbiamo esplicitamente scaricare le
nuove versioni lanciando il comando `docker-compose pull`. I container vengono avviati in modalità **attached** dato che
non abbiamo utilizzato l'opzione `-d, --detach`. Per terminare l'esecuzione è necessario premere la combinazione di
tasti `Ctrl+C`, che ferma i container in modo "pulito".

```bash
gianni@nolok ~/workspace/projects/workshop-docker/module06 $ docker-compose up   
Creating network "module06_default" with the default driver
Pulling mongo (mongo:)...
latest: Pulling from library/mongo
5c939e3a4d10: Already exists
c63719cdbe7a: Already exists
19a861ea6baf: Already exists
651c9d2d6c4f: Already exists
85155c6d5fac: Pull complete
85fb0780fd97: Pull complete
85b3b1a901f5: Pull complete
6a882e007bb6: Pull complete
f7806503a70f: Pull complete
5732cde4308d: Pull complete
8f892a804391: Pull complete
afc61ce39de5: Pull complete
479082b17a4a: Pull complete
Digest: sha256:14b612325925ca60d9ccbc710aa4c2dbfb74106229f60f4fee9d42fab0281f6f
Status: Downloaded newer image for mongo:latest
Pulling mongo-express (mongo-express:)...
latest: Pulling from library/mongo-express
c9b1b535fdd9: Already exists
99c818a1969a: Pull complete
fced71a1b5bc: Pull complete
799240489e66: Pull complete
8eb3c0afbdae: Pull complete
4eabc795ad11: Pull complete
7b7fe292e494: Pull complete
4afc03e113fa: Pull complete
Digest: sha256:c0aebfd7d7890a11248fb442706003156dfcbab260a3a1a64efb3c2c475d0d5e
Status: Downloaded newer image for mongo-express:latest
Creating module06_mongo_1 ... done
Creating module06_mongo-express_1 ... done
Attaching to module06_mongo_1, module06_mongo-express_1
......
......
......
^CGracefully stopping... (press Ctrl+C again to force)
Stopping module06_mongo-express_1 ... done
Stopping module06_mongo_1         ... done
```

### Aggiornare i servizi
L'unico comando di _Compose_ che aggiorna i servizi/container è `docker-compose pull`. Nessun altro comando controlla se
esistono versioni più recenti delle immagini e tantomeno scaricano le versioni più aggiornate... nessuno "side-effect"
 e nessuna sorpresa legati agli aggiornamenti dei servizi. 

```bash
gianni@nolok ~/workspace/projects/workshop-docker/module06 $ docker-compose pull
Pulling mongo         ... done
Pulling mongo-express ... done
```

### Fermare i servizi
È possibile fermare i servizi precedentemente avviati in modalità _detach_ utilizzando il comando `docker-compose stop`.
Esso si limita a fermare i container senza cancellare alcun dato o configurazione. Questo comando lascia i container,
le immagini, i volumi e persino la configurazione delle network.  

```bash
gianni@nolok ~/workspace/projects/workshop-docker/module06 $ docker-compose stop
Stopping module06_mongo-express_1 ... done
Stopping module06_mongo_1         ... done
```

### Rimuovere i servizi
Il comando `docker-compose down` ferma i servizi e distrugge tutti i dati e le configurazioni a essi associati!
Utilizzatelo con cautela perché esso rimuove i container, i volumi e le configurazioni delle network.

```bash
gianni@nolok ~/workspace/projects/workshop-docker/module06 $ docker-compose down
Removing module06_mongo-express_1 ... done
Removing module06_mongo_1         ... done
Removing network module06_default
```

### Monitorare i servizi
Esistono due comandi del tutto analoghi a quelli messi a disposizione da _Docker_ ed essi sono `docker-compose top` per
visualizzare i processi in esecuzione all'intreno dei container e `docker-container logs` per visualizzare l'output dei
container.

```bash
gianni@nolok ~/workspace/projects/workshop-docker/module06 $ docker-compose top
module06_mongo-express_1
UID     PID    PPID    C   STIME   TTY     TIME                         CMD                    
-----------------------------------------------------------------------------------------------
root   10699   10660   0   00:02   ?     00:00:00   tini -- /docker-entrypoint.sh mongo-express
root   10785   10699   0   00:02   ?     00:00:01   node app                                   

module06_mongo_1
  UID       PID    PPID    C   STIME   TTY     TIME                 CMD            
-----------------------------------------------------------------------------------
message+   10512   10470   0   00:02   ?     00:00:02   mongod --auth --bind_ip_all
```

## Agire su un singolo servizio
Tutti i comandi che abbiamo utilizzato finora possono lavorare sull'intera composizione oppure su un singolo servizio.
Quando vengono lanciati senza specificare il servizio su cui devono agire, essi agiscono sull'intera composizione,
invece, se viene specificato un servizio, essi agiscono solo su quel servizo e le eventuali dipendenze (se necessario).

## Riassunto
Facciamo un breve riassunto dei comandi e delle opzioni finora utilizzate:

 Command | Option | Behavior
---------|--------|----------
up | | Create and start containers 
| | -d, --detach | Detached mode
pull | | Pull service image
stop | | Stop services
start | | Start services
down | | Stop and remove containers, networks, images, and volumes
top | | Display the running processes
logs | | View output from containers
| | -f, --follow | Follow log output
___

[prev](../module05/README.md) [home](../README.md) [next](../module07/README.md)

Copyright (C) 2018-2020 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).

Images from [Play with Docker classroom](https://training.play-with-docker.com/about/)
