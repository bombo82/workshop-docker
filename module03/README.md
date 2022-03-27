# Workshop Docker - Modulo 3

Concetti in questo modulo:
- Esecuzione dei container in background
- Bind di porte TCP
- Bind Mount
- Volume
- .dockerignore file

In questo esercizio vediamo come creare un semplice sito web e come pubblicarlo.
Questo sarà il nostro primo container che verrà eseguito in _background_ e che interagirà con il mondo esterno tramite un porta TCP e caricherà delle configurazioni da un filesystem esterno.

## Sito web
Creiamo una nuova directory chiamata app e al suo interno creiamo il Dockerfile.
In questo caso partiamo da un'immagine già pronta scopo, con al suo interno un webserver pre-installato e configurato.

Iniziamo creando un Dockerfile che definisce il nostro container. Partiamo dall'immagine ufficiale di _nginx_, copiamo al suo interno una pagina html ed esponiamo le porte relative al protocollo HTTP.
```dockerfile
FROM nginx:latest
COPY index.html /usr/share/nginx/html
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
```
Ora creiamo il nostro file index.html con il seguente codice:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hello World</title>
</head>
<body>
    <h1>Hello World</h1>
</body>
</html>
```
Perfetto, ora che abbiamo il Dockerfile e la nostra pagina, web non ci resta che fare la build dell'immagine e avviarla.
```bash
bombo82@nolok ~ $ docker image build -t hello-http:v0.1 app
Sending build context to Docker daemon   5.12kB
Step 1/4 : FROM nginx:latest
latest: Pulling from library/nginx
f2aa67a397c4: Pull complete 
1cd0975d4f45: Pull complete 
72fd2d3be09a: Pull complete 
Digest: sha256:3e2ffcf0edca2a4e9b24ca442d227baea7b7f0e33ad654ef1eb806fbd9bedcf0
Status: Downloaded newer image for nginx:latest
 ---> cd5239a0906a
Step 2/4 : COPY app/index.html /usr/share/nginx/html
 ---> 7b60aacf7ca8
Step 3/4 : EXPOSE 80 443
 ---> Running in dc2471482fe7
Removing intermediate container dc2471482fe7
 ---> d1b389b9fd43
Step 4/4 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in ab1a36732076
Removing intermediate container ab1a36732076
 ---> 2e9c6e31c481
Successfully built 2e9c6e31c481
Successfully tagged hello-http:v0.1

bombo82@nolok ~ $ docker container run -d hello-http:v0.1
3c3e0f553bd0deb0f93d71ffa55cafcffc4c59553aa21df835b3d2311b7f919b

bombo82@nolok ~ $ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
3c3e0f553bd0        hello-http:v0.1     "nginx -g 'daemon of…"   11 seconds ago      Up 10 seconds       80/tcp, 443/tcp     agitated_yalow
```
Il comando **ls** ci restituisce la lista dei container in esecuzione e vediamo il nostro sito web è up and running, ma se proviamo ad accedere con un browser riceviamo un errore.
Questo accade perché le porte _esposte_ dal Dockerfile non vengono automaticamente pubblicate.

E' possibile pubblicare le porte usando il flag __-p__ quando facciamo il run e specificando come mappare le porte, oppure è possibile utilizzare il flag __-P__ per dire a docker di pubblicare tutte le porte esposte, ma in questo caso verranno mappate su delle porte casuali dell'host.

Un'ultima nota... il container attualmente ha un nome casuale. E' possibile assegnare un nome al container quando la mandiamo in esecuzione oppure in un secondo tempo.
```bash
bombo82@nolok ~ $ docker container stop 3c3e0f553bd0
3c3e0f553bd0

bombo82@nolok ~ $ docker container run -d -p 80:80 --name hello-http hello-http:v0.1
7fd69dd3c43b298e86bad29f8ac14053796a1501467acb0cbde4858679b39a30

bombo82@nolok ~ $ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                         NAMES
7fd69dd3c43b        hello-http:v0.1     "nginx -g 'daemon of…"   9 seconds ago       Up 8 seconds        0.0.0.0:80->80/tcp, 443/tcp   hello-http
```
Ora va molto meglio! Il nostro primo sito web è online.

## Bind mount
Il concetto di _bind mount_ risulta parecchio oscuro per chi non ha dimestichezza con GNU/linux, ma la spiegazione di cosa sia un _bind mount_ devia dallo scopo di questo tutorial, quindi vi rimando a questi oscuri links: [mount point](http://www.linfo.org/mount_point.html) e [bind mount](http://docs.1h.com/Bind_mounts). 
Contestualizzando i _bind mount_ con docker, potrei affermare che essi ci forniscono un sistema per condividere una partizione del HDD, una directory o un file tra l'host e il container.

Finora abbiamo sempre parlato di un container come un sistema isolato dagli altri container e dal sistema che lo ospita! come mai è necessario creare dei bind mount?

Spesso ha poco senso utilizzare dei _bind mount_, ma essi possono essere molto utili durante lo sviluppo delle applicazioni o per passare le configurazioni alle applicazioni interne al container.
Essi ci permettono di modificare dei dati esterni al container e renderli disponibili e aggiornati all'interno del container stesso, senza dover creare una nuova immagine.
Per esempio, un'applicazione può aver bisogno di alcune configurazioni per funzionare e tali configurazioni potrebbe non aver alcune senso inserirle nell'immagine.

**ATTENZIONE:** i _bind mount_ possono essere sia _read only_ che _read/write_. Non solo è buona pratica che tutti i _bind mount_ siano **read only**, ma la presenza di _bind mount_ **read/write** è, quasi sempre, sintomo di un _**ERRORE**_ a livello concettuale o architetturale! Prestate molta attenzione quando usate i _bind mount_ e nel caso in cui abbiate la tentazione di crearlo _read/write_ fermatevi e ponetevi delle domande!

Modifichiamo la nostra applicazione web aggiungendo un JavaScript che legge il messaggio di saluto da visualizzare da un file di configurazione.
Le modifiche non sono tantissime e per comodità è possibile usare il contenuto della folder _app-configurable_ che è già pronto all'uso.

All'inteno della folder trovate i seguenti file:
* __conf.json__ file di configurazione contenente il messaggio da visualizzare
* __Dockerfile__ file con le specifiche per la creazione dell'immagine
* __.dockerignore__ file che definisce i file che docker deve ignorare durante la creazione delle immagini
* __index.html__ homepage del sito web
* __index.js__ script che eseguito lato client contenente la logica per leggere la configurazione e visualizzare il messaggio

Fermiamo il container del precedente esercizio e poi procedere con la creazione della nuova immagine e la sua esecuzione.
```bash
bombo82@nolok ~ $ docker container stop hello-http
hello-http

bombo82@nolok ~ $ docker image build -t hello-http-configurable:v0.1 app-configurable
Sending build context to Docker daemon  5.632kB
Step 1/4 : FROM nginx:latest
 ---> cd5239a0906a
Step 2/4 : COPY . /usr/share/nginx/html/
 ---> d8d39de31d03
Step 3/4 : EXPOSE 80 443
 ---> Running in 0872936a6c3e
Removing intermediate container 0872936a6c3e
 ---> 827716b841ed
Step 4/4 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in fd38cb53775d
Removing intermediate container fd38cb53775d
 ---> 603c5995a28d
Successfully built 603c5995a28d
Successfully tagged hello-http-configurable:v0.1

bombo82@nolok ~ $ docker container run \
    -d \
    -p 80:80 \
    --name hello-http-configurable \
    hello-http-configurable:v0.1
593c3ecdaeec5d579d9497500d4ba102ecae6c4f4ccdb7de64a3c0b944c92d22

bombo82@nolok ~ $ docker container ls
CONTAINER ID        IMAGE                          COMMAND                  CREATED             STATUS              PORTS                         NAMES
593c3ecdaeec        hello-http-configurable:v0.1   "nginx -g 'daemon of…"   27 seconds ago      Up 27 seconds       0.0.0.0:80->80/tcp, 443/tcp   hello-http-configurable
```
Verifichiamo che il container sia in esecuzione e il risultato della nostra chiamata http.
Il file di configurazione non è presente all'interno del container perché il file _.dockerignore_ ha istruito docker per ometterlo durante la creazione dell'imamgine.
Potete controllare eseguendo il seguente comando, oppure eseguendo in modo interattivo una shell all'interno del container.
```bash
bombo82@nolok ~ $ docker container exec hello-http-configurable ls /usr/share/nginx/html/
50x.html
index.html
index.js
```
Ora possiamo fare il passo conclusivo... dobbiamo aggiungere un _bind mount_ al comando di run, al fine di montare il file di configurazione externo.
```bash
bombo82@nolok ~ $ docker container stop hello-http-configurable
hello-http-configurable

bombo82@nolok ~ $ docker container rm hello-http-configurable
hello-http-configurable

bombo82@nolok ~ $ docker container run \
    -d \
    -p 80:80 \
    --name hello-http-configurable \
    --mount type=bind,source="$(pwd)"/app-configurable/conf.json,target=/usr/share/nginx/html/conf.json,readonly \
    hello-http-configurable:v0.1

bombo82@nolok ~ $ docker container exec hello-http-configurable ls /usr/share/nginx/html/50x.html
conf.json
index.html
index.js
```

## Volume
In docker, un concetto simile a quello dei _bind mount_ è quello dei _volume_.
La differenza principale tra questi 2 concetti è che i _bind mount_ dipendono dalla struttura delle directory del host, mentre i **volumi sono completamente gestiti da docker!**
I volumi sono il meccanismo principale e **preferito** per persistere i dati generati dai container, per esempio lo _store su filesystem_ dei DBMS, i file allegati/caricati dagli utenti in un'applicazione web.

I principali vantaggi nell'uso sono:
- è facile creare un backup dei _volume_;
- i _volume_ possono essere migrati più facilmente rispetto ai _bind mount_;
- possono essere gestiti tramite "Docker CLI" e le "Docker API";
- funzionano in modo consistente con container linux che Windows;
- possono essere condivisi in modo sicuro ed efficiente tra più container, senza "side-effects";
- i driver usati per accedere ai _volumes_ permettono il salvataggio su host remoti o provider cloud;
- i driver usati per accedere ai _volumes_ implementano la crittografia nativamente;
- i driver usati per accedere ai _volumes_ hanno più funzionalità rispetto a quelli dei _bind mount_;
- i nuovi _volume_ possono essere pre-popolati da un _container_.

Inoltre, i dati scritti nei _volumes_ non incrementano la dimensione dei container e sopravvivono alla ricreazione dei _containers_ che li usano.

usare i _volume_ è una buona soluzione tutte le volte che sentite l'esigenza di avere uno spazio in cui scrivere dei dati tramite il _container_ oppure dovete condividere dati tra più _container_.

**ATTENZIONE:** nella sezione precedente ho affermato che usare i _bind mount_ in _read/write_ è male... ora avete una possibile alternativa a tutte le volte che verrete tentati dal "lato oscuro di Docker", ma ricordate che non è l'unica possibile.

In futuro scriverò un tutorial (o amplierò questo), con alcuni argomenti di livello intermedio, come la gestione delle _network_, dei _volume_ o dei _tmpfs mount_, ma per il momento vi rimando alla documentazione ufficiale [link](https://docs.docker.com/storage/volumes/).

## Riassunto
Facciamo un breve riassunto dei comandi e delle opzioni finora utilizzate:

| Management Command | Command | Option              | Behavior                                              |
|--------------------|---------|---------------------|-------------------------------------------------------|
| image              | pull    |                     | Pull an image or a repository from a registry         |
| image              | ls      |                     | List images                                           |
| image              | tag     |                     | Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE |
| image              | build   |                     | Build an image from a Dockerfile                      |
|                    |         | -t, --tag list      | Name and optionally a tag in the 'name:tag' format    |
| image              | history |                     | Show the history of an image                          |
| image              | inspect |                     | Display detailed information on one or more images    |
|                    |         | -f, --format string | Format the output using the given Go template         |
| container          | run     |                     | Run a command in a new container                      |
|                    |         | -i, --interactive   | Keep STDIN open even if not attached                  |
|                    |         | -t, --tty           | Allocate a pseudo-TTY                                 |
|                    |         | -d, --detach        | Run container in background and print container ID    |
|                    |         | -p, --publish list  | Publish a container's port(s) to the host             |
|                    |         | -P, --publish-all   | Publish all exposed ports to random ports             |
|                    |         | --name string       | Assign a name to the container                        |
|                    |         | --mount mount       | Attach a filesystem mount to the container            |
| container          | stop    |                     | Stop one or more running containers                   |
| container          | exec    |                     | Run a command in a running container                  |
|                    |         | -i, --interactive   | Keep STDIN open even if not attached                  |
|                    |         | -t, --tty           | Allocate a pseudo-TTY                                 |
| container          | start   |                     | Start one or more stopped containers                  |
| container          | stop    |                     | Stop one or more running containers                   |
| container          | ls      |                     | List running containers                               |
|                    |         | -a, --all           | Show all containers (default shows just running)      |

Dockerfile Quick Reference:

| Instruction | Commit Layer | Reference                                                                                                                                                                                                                                                                                                                                                   |
|-------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FROM        | No           | Initializes a new build stage and sets the Base Image for subsequent instructions. As such, a valid Dockerfile must start with a FROM instruction. The image can be any valid image – it is especially easy to start by pulling an image from the Public Repositories.                                                                                      |
| RUN         | Yes          | Will execute any commands in a new layer on top of the current image and commit the results. The resulting committed image will be used for the next step in the Dockerfile.                                                                                                                                                                                |
| COPY        | Yes          | Copies new files or directories from <src> and adds them to the filesystem of the container at the path <dest>.                                                                                                                                                                                                                                             |
| WORKDIR     | No           | Instruction sets the working directory for any RUN, CMD, ENTRYPOINT, COPY and ADD instructions that __follow__ it in the Dockerfile. If the WORKDIR doesn’t exist, it will be created even if it’s not used in any subsequent Dockerfile instruction.                                                                                                       |
| EXPOSE      | No           | Informs Docker that the container listens on the specified network ports at runtime. The EXPOSE instruction does not actually publish the port. It functions as a type of documentation between the person who builds the image and the person who runs the container, about which ports are intended to be published.                                      |
| CMD         | No           | There can only be one CMD instruction in a Dockerfile. If you list more than one CMD then only the last CMD will take effect. __The main purpose of a CMD is to provide defaults for an executing container.__ These defaults can include an executable, or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well. |

___

[prev](../module02/README.md) [home](../README.md) [next](../module04/README.md)

Copyright (C) 2018-2022 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
