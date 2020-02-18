# Workshop Docker - Modulo 7

Concetti in questo modulo:
- definire servizi
- riavvio dei servizi
- mappare porte
- variabili d'ambiente
- passare parametri al container
- gestione dei volumi
- ordine di avvio e dipendenze
- labels
- altri concetti

## Definizione dei servizi
I servizi sono definiti come una mappa all'interno di un file chiamato `docker-compose.yml`. Per ogni servizio viene
definita una chiave che lo identifica in modo univoco all'interno della composizione. È possibile inserire più volte la
stessa chiave e in questo coas _Compose_ crea un solo servizio i cui attributi saranno l'unione degli attributi definiti
dalla singola chiave. Associamo ad ogni chiave una lista di attributi che definisco il servizio in questione.

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

Nell'esempio sopra riportato ci sono 2 servizi: _mongo_ e _mongo-express_. Per il servizio _mongo_ abbiamo definito gli
attributi _image_, _restart_ ed _environment_. I primi 2 attributi contengono una stringa come singolo valore, mentre
_environment_ contiene una mappa di valori.

Ogni servizio ha l'attributo _image_ che indica l'immagine da cui creare il container e, come alternativa, potremmo fare
la build di un'immagine da `Dockerfile` direttamente tramite _Compose_. Questa alternative dovrebbe essere utilizzata
solo in fase di sviluppo per rendere più rapido il processo di sviluppo e test, mentre per gli ambienti di test e
produzione dovremmo sempre utilizzare immagini già costruite e presenti su un _artefactory_,

## Riavvio dei servizi
La politica di default è _"no"_ e significa che il servizio non verrà mai riavviato in modo automatico. Le altre scelte
disponibili sono: _always_, _on-failure_ e _unless-stopped_.

> **ATTENZIONE:** l'attributo "_restart_" viene ignorato quando stiamo facendo il deploy su `docker-swarm` e in questo
>caso dovremmo gestire il riavvio tramite l'attributo "_deploy_.

## Mappare porte
In modo del tutto analogo a _Docker_, abbiamo la possibilità di definire im mapping delle porte TCP esposte dai servizi.
L'attributo "_ports_" accetta in input un'array di valori e tali valori sono nel formato `HOST:CONTAINER`, per esempio:

```yaml
ports:
 - "3000"
 - "3000-3005"
 - "8000:8000"
 - "9090-9091:8080-8081"
 - "49100:22"
 - "127.0.0.1:8001:8001"
 - "127.0.0.1:5000-5010:5000-5010"
 - "6060:6060/udp"
```

Esiste anche una sintassi più "lunga ed elaborata" che spesso viene utilizzata in ambiente _Swarm_ e utilizzata con reti
distribuite tra più nodi e con load-balancer.

## Variabili d'ambiente
In _Compose_ possono essere definite le variabili d'ambiente da passare ai servizi quando vengono avviati. Questo
sistema è molto utili per rendere dinamiche le configurazioni e riutilizzare sia le immagini sia i file 
`docker-compose.yml`.
Tramite l'attributo "_environment_" possiamo definire una mappa di valori da passare al container al momento del "run".
Una caratteristicha molto potente di _Compose_ è che possiamo utilizzare le variabili d'ambiente del terminale in cui
viene eseguito il comando `docker-compose` all'interno del file. Di seguito un esempio di configurazione delle variabili
d'ambiente:

```yaml
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example
      CURRENT_FOLDER: $PWD
```

> **ATTENZIONE:** poter utilizzare le variabili definite per il terminale è molto potente e spesso molto utile, ma rende
>difficile comprendere quale valore hanno tali variabili. Il mio consiglio è di utilizzare il meno possibile le
>variabili d'ambiente del terminale e definirle a livello di `docker-compose` magari creando file di environement
>specifici per ogni ambiente.

## Passare parametri al container
Normalmente con _Docker_ possiamo passare dei parametri al container quando eseguiamo il comando `docker container run`
e questa funzionlità è presente anche in _Compose_. Tramite l'attibuto "_command_" è possibile sovrascrivere il _CMD_
definito nel _Dockerfile_ dell'immagine.

```yaml
  reverse-proxy:
    image: traefik
    command: --api.insecure=true --providers.docker --providers.docker.exposedByDefault=false
    restart: on-failure
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

Sopra trovate l'esempio di un servizio a cui passiamo dei parametri dall'esterno tramite l'attributo _command_.

## Gestione dei volumi
Tramite _Compose_ è possibile creare e montare volumi "interni a Docker" oppure effettuare dei `bind mount`. Riguardo la
differenza tra queste tipologie di volumi ne abbiamo parlato in precedenza, nel modulo 03. In generale, non è una buona
pratica utilizzare i `bind mount` perché essi espongono il filesystem del nostro "host server" e ci possono essere
problemi quando utilizzati con _Swarm_. La gestione dei volumi avviene tramite l'attributo _volumes_ che accetta una
lista di stringhe.

### Bind mount
Nell'esempio sotto ho utilizzato _volumes_ per effettuare il `bind mount` del file `/var/run/docker.sock` all'interno
del servizio reverse-proxy. Il file `/var/run/docker.sock` è il socket (uno stream dati) utilizzato da _Docker_
praticamente per effettuare ogni operazione! i comandi `docker` e `docker-compose` inviano alla _docker-engine_ i
comandi e i dati tramite quel file e la _docker-engine_ utilizza quel file per pubblicare eventi relativi al sistema.
In pratica, abbiamo reso accessibile ed esposto tutto _docker_ a un container!

```yaml
  reverse-proxy:
    image: traefik
    command: --api.insecure=true --providers.docker --providers.docker.exposedByDefault=false
    restart: on-failure
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

> **ATTENZIONE:** Questa operazione implica parecchie cose a livello di sicurezza e introduce possibili falle enormi,]
>quindi fa fatta con molta cautela e a ragion veduta!

### Volume
La gestione dei volumi interni a _Compose_ richiede la scrittura di qualche riga in più perché, oltre a configurare il
volume nel servizio `mongo_volume:/data/db` è necessario dichiarare il volume `mongo_volume` all'interno. Nell'esempio
sotto è definito un volume (ultime 2 righe) e utilizzato nel servizio _mongo_.

```yaml
services:
  mongo:
    image: mongo
    restart: on-failure
    volumes:
      - mongo_volume:/data/db

volumes:
  mongo_volume:
```

I volumi definiti nel _Compose_ sono persistenti, quindi quando fermiamo la nostra composizione essi **NON** vengono
cancellati e vengono utilizzati nuovamente al successivo avvio dei container. Per cancellare i volumi è necessario
lanciare il comando `down` con l'opzione `-v`, quindi è poco probabile che vengano cancellati per errore i volumi dato
che `docker-compose down -v` è l'unica istruzione che effettua la rimozione degli stessi.

## Ordine di avvio e dipendenze
Ci viene offerta una funzionalità molto basilare per gestire l'ordine di avvio e le dipendenze tra servizi. Tramite
l'attributo "_depends_on_" è possibile stabilire l'ordine di avvio dei servizi. Purtroppo _depends_on_  controlla solo
quando il serizio è avviato come container, senza preoccuparsi se esso sia anche **realmente pronto** (in grado di
rispondere alle richieste). Le dipendenze tra i servizi influiscono anche sull'ordine in cui vengono fermati i servizi.

Nel file `docker-compose.yml` presente in questo modulo trovate un esempio completo di composizione in cui sono definite
le dipendenze. Abbiamo 5 servizi e le seguenti dipendenze:

- reverse-proxy -> redis-commander & mongo-express
- redis-commander -> redis
- mongo-express -> mongo

Visto le dipendenze, i comandi `docker-compose up` e `docker-compose stop` si comporteranno nel seguento modo:

- `docker-compose up redis` avvia solo il servizio redis;
- `docker-compose up redis-commander` avvia il servizio redis prima di redis-commander
- `docker-compose up` avvia i servizi nel seguente ordine: redis & mongo (in contemporanea), poi redis-commander &
mongo-express (quando la loro dipendenza è avviata) e infine reverse-proxy (quando tutti gli altri sono avviati)
- `docker-compose stop` ferma i servizi nel seguente ordine: reverse-proxy, poi redis-commander & mongo-express (in
contemporanea), infine redis e mongo (quando le rispettive dipendenze sono ferme).

## Labels
L'attributo "_labels_" permette di definire delle etichetti, dei meta-data. Queste _labels_ sono associate al serizio e
non alle singole istanze di container. Le _label_ non sono utilizzate da Docker, ma esso le rende disponibili a tutti i
servizi presenti nella composizione. Questo significa che se associamo una _label_ al servizio redis-commander, tale
_label_ può essere letta e interpretata da un altro servizio e.g. reverse-proxy. Nel nostro esempio le _labels_ sono
proprio utilizzare per questo scopo! Il servizio reverse-proxy è implementato tramite il software _traefik_ che si
auto-configura tramite le _labels_ con prefisso _traefik_ presenti negli altri servizi. 

## Altri concetti
Di seguito un elenco di concetti avanzati che non sono trattati in questo workshop:
- gestione delle configurazioni: _config_
- gestioni delle password (e simili): _secrets_
- healtcheck (intraducibile): _healthcheck_
- sistemi di logging: _logging_
- gestione delle reti: _networks_
- deploy in swarm

## Riassunto
Facciamo un breve riassunto dei comandi e delle opzioni finora utilizzate:

 Command | Option | Behavior
---------|--------|---------
up | | Create and start containers 
| | -d, --detach | Detached mode
pull | | Pull service image
stop | | Stop services
start | | Start services
down | | Stop and remove containers, networks, images, and volumes
top | | Display the running processes
logs | | View output from containers
| | -f, --follow | Follow log output

 Attribute | Type | Default | Description
-----------|------|---------|-------------
image | stringa | | Specifica da quale immagini creare il container
restart | stringa | "no" | Imposta la politica di riavvio dei servizi.
ports | lista di stringhe | | Espone e mappa le porte 
environment | mappa | | Definisce le variabili d'ambiente 
command | stringa | | Sovrascrive (override) del `CMD` di default dell'immagine definita nel `Dockerfile`
volumes | lista di stringhe o oggetti | | 
depends_on | lista di stringhe | | Dichiarazione delle dipendenze del servizio
labels | mappa | | Definisce una mappa di etichetti (meta-data) non usati da docker, ma esposti per essere utilizzati da altri servizi
___

[prev](../module06/README.md) [home](../README.md)

Copyright (C) 2018-2020 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).

Images from [Play with Docker classroom](https://training.play-with-docker.com/about/)
