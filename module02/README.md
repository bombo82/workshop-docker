# Workshop Docker - Modulo 2

Concetti in questo modulo:
- Creare un'immagine da un container
- Creare un'immagine da un Dockerfile
- Image Layers e Cache
- Tag delle immagini

Nel precedente modulo abbiamo visto come scarciare un'immagine dal _Docker Store_ ed eseguirla.
Scoperto che l'instanza di un'immagine in esecuzione prende il nome di __container__ e come questa contenga un ambiente isolato dagli altri container e che le modifiche all'interno dei container non influiscano con l'imamgine usata per istanziarli.

Tutto questo è molto utile, ma è necessario un modo per creare le nostre immagini, configurale per le nostre esigenze e installare al loro interno le nostre applicazioni.
In questo modulo vediamo come creare le nostre immagini docker personalizzate.


## Creazione di un immagine da un container
In questo esercizio useremo come _ubuntu_ come base per le nostre immagini e come esercizio proviamo a installare al suo interno __figlet__ e lo useremo per disegnare delle scritte in asciiart.
Iniziamo con eseguire una bash linux all'interno di un container ubuntu.
```bash
bom@princesspenny ~ $ docker container run -it ubuntu /bin/bash
```
Ora installiamo __figlet__ e disegnamo la scritta _hello world_.
```bash
root@bac8b86a52b0:/# apt-get update
root@bac8b86a52b0:/# apt-get install -y figlet
root@bac8b86a52b0:/# figlet hello world
```
Perfetto! Abbiamo installato _figlet_ nel container e verificato che funziona correttamente.
Per creare un immagine da un container è necessario conoscere il suo CONTAINER_ID, quindi andiamo alla ricerca del suo ID e poi lanciamo il comando __commit__ per creare una nuova immagine.
```bash
bom@princesspenny ~ $ docker container ls -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                          PORTS               NAMES
bac8b86a52b0        ubuntu              "/bin/bash"         4 minutes ago       Exited (0) About a minute ago                       infallible_murdock

bom@princesspenny ~ $ docker container commit bac8b86a52b0
sha256:3d9ef0cc030b5fce9d8244d8243024e3388f70eaa759275572e137285742a7aa
```
Il comando di commit ci restituisce l'_hashcode_ corrispondende all'immagine appena creata...
verifichiamo visualizzando la lista delle immagini presenti.
```bash
bom@princesspenny ~ $ docker image ls
REPOSITORY                           TAG                 IMAGE ID            CREATED             SIZE
<none>                               <none>              3d9ef0cc030b        41 seconds ago      123MB
ubuntu                               latest              113a43faa138        2 weeks ago         81.2MB
```
Prima di procedere facciamo due considerazioni:
* la colonna IMAGE ID riporta solo i primi 12 caratteri dell'hashcode dell'immagine, mentre il comando di commit ce li mostra tutti. In generale, bastano i primi caratteri per identificare un immagine, un container e qualsiasi altro _oggetto_ gestito da docker;
* le colonne REPOSITORY e TAG riportano il valore `<none>`. Questo significa semplicemente che la nostra immagine non ha nome e versione.

Avere delle immagini senza nome e senza versione non è molto utile... ok, possiamo farne a meno perché tutte le immagini hanno un ID univoco, ma non è molto comodo!
Procediamo assegnando un nome e una versione alla nostra immagine.
```bash
bom@princesspenny ~ $ docker image tag 3d9ef0cc030b nostro-figlet
bom@princesspenny ~ $ docker image ls
REPOSITORY                           TAG                 IMAGE ID            CREATED             SIZE
nostro-figlet                        latest              3d9ef0cc030b        12 minutes ago      123MB
ubuntu                               latest              113a43faa138        2 weeks ago         81.2MB
```
Il risultato è abbastanza curioso e inaspettato... il comando __tag__ ha imspotato sia il REPOSITORY che il TAG.
Cerchiamo di capire meglio il significato di quello che abbiamo scritto e interpelliamo l'help di docker.
```bash
bom@princesspenny ~ $ docker image tag --help

Usage:  docker image tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]

Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
```
Mi sembra che non sia di grande aiuto...
cerchiamo di capire meglio come funziona:
* SOURCE_IMAGE può essere:
  * IMAGE_ID: in questo caso il TAG (opzionale) non va indicato
  * IMAGE_NAME: in questo caso il TAG può essere indicato o meno
  * REGISTRY/IMAGE_NAME
* TARGET_IMAGE può essere:
  * IMAGE_NAME: in questo caso il TAG può essere indicato o meno
  * REGISTRY/IMAGE_NAME
* TAG (opzionale): se omesso viene utilizzato _latest_

Docker crea una collezione con il nome dell'immagine e al suo interno inserisce le immagini da noi create e le deffirenzia per un TAG. Esso normalmente corrisponde alla versione dell'immagine.

Ora possiamo anche capire perhé il comando precedente visualizza il nome dell'imamgine nella colonna REPOSITORY.
In realtà, il nome delle immagini è formato con il riferimento al __Docker Registry__ a cui appartengono e come al solito se omesso viene usato quello di default.

Torniamo al nostro intento iniziale... usare un container per rappresentare in asciiart delle frasi!
```bash
bom@princesspenny ~ $ docker container run nostro-figlet figlet hello world
 _          _ _                            _     _ 
| |__   ___| | | ___   __      _____  _ __| | __| |
| '_ \ / _ \ | |/ _ \  \ \ /\ / / _ \| '__| |/ _` |
| | | |  __/ | | (_) |  \ V  V / (_) | |  | | (_| |
|_| |_|\___|_|_|\___/    \_/\_/ \___/|_|  |_|\__,_|
                                                   
```
In questo esempio abbiamo visto come creare un container, inserire librerie e applicazioni al suo interno e poi farne _commit_ in modo da creare una nuova immagine risuabile.

L'approccio visto sopra ci permette di creare delle immagini in modo rapido e semplice, ma in modo __manuale__. Questo approccio rende le immagini da noi create qualcosa di immutabile... ricordate che abbiamo eseguito il comando __apt-get update__ all'interno del container?
Esso è stato eseguito nel momento in cui abbiamo creato l'immagine e non verrà eseguito nuovamente in futuro e anche la versione di ubuntu utilizzata come base non verrà mai aggiornata.
Esiste un modo più potente, flessibile e soprattutto automatizzabile per creare delle immagini docker.

## Creare un immagine da un Dockerfile
In questo esercizio proviamo a creare un semplice script js da eseguire all'interno del container e stampare a video il solito _hello_.

Iniziamo creando una nuova directory chiamata __app__ e al suo interno  creiamo il file _index.js_ con il seguente codice:
```javascript
var os = require("os");
var hostname = os.hostname();
console.log("hello from " + hostname);
```
Creiamo anche un file chiamato __Dockerfile__. Esso raccoglie tutte le informazioni per creare la nostra immagine custom.
Il Dockerfile contiene un elenco di comandi che docker eseguirà in fase di build dell'immagine e tramite questi comandi possiamo eseguire istruzioni all'interno dell'immagine, copiare file, impostare variabili d'ambiente e altro ancora...
```dockerfile
FROM alpine
RUN apk update && apk add nodejs
COPY app/ /app
WORKDIR /app
CMD ["node","index.js"]
```
Una volta creati i 2 file in questione non ci resta che lanciare la _build_ dell'imamgine e provare a eseguire un'istanza dell'immagine appena creata.
```bash
bom@princesspenny ~ $ docker image build -t hello:v0.1 .
Sending build context to Docker daemon  11.26kB
Step 1/5 : FROM alpine
 ---> 3fd9065eaf02
Step 2/5 : RUN apk update && apk add nodejs
 ---> Running in 25293f7354b1
fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/community/x86_64/APKINDEX.tar.gz
v3.7.0-214-g519be0a2d1 [http://dl-cdn.alpinelinux.org/alpine/v3.7/main]
v3.7.0-207-gac61833f9b [http://dl-cdn.alpinelinux.org/alpine/v3.7/community]
OK: 9054 distinct packages available
(1/10) Installing ca-certificates (20171114-r0)
(2/10) Installing nodejs-npm (8.9.3-r1)
(3/10) Installing c-ares (1.13.0-r0)
(4/10) Installing libcrypto1.0 (1.0.2o-r0)
(5/10) Installing libgcc (6.4.0-r5)
(6/10) Installing http-parser (2.7.1-r1)
(7/10) Installing libssl1.0 (1.0.2o-r0)
(8/10) Installing libstdc++ (6.4.0-r5)
(9/10) Installing libuv (1.17.0-r0)
(10/10) Installing nodejs (8.9.3-r1)
Executing busybox-1.27.2-r7.trigger
Executing ca-certificates-20171114-r0.trigger
OK: 61 MiB in 21 packages
Removing intermediate container 25293f7354b1
 ---> 4f97d0fd8068
Step 3/5 : COPY . /app
 ---> 59e781a04217
Step 4/5 : WORKDIR /app
Removing intermediate container 77eb381229d4
 ---> aba575608486
Step 5/5 : CMD ["node","index.js"]
 ---> Running in 6c955a9c5209
Removing intermediate container 6c955a9c5209
 ---> 81b4cd5f4dcc
Successfully built 81b4cd5f4dcc
Successfully tagged hello:v0.1

bom@princesspenny ~ $ docker container run hello:v0.1
hello from 271da2c4bfb4
```
![Dockerfile Build](https://training.play-with-docker.com/images/ops-images-dockerfile.svg)
https://training.play-with-docker.com

Wow, abbiamo creato la nostra prima applicazione che gira in un container docker!
L'applicazione è un semplice file _JavaScript_ che stampa a video un _hello world_ personalizzato con l'hostname del container. La nostra applicazione viene eseguita tramite _Node.js_.

Cosa accade se eseguimo il container passandogli un'istruzione come parametro?
```bash
bom@princesspenny ~ $ docker container run hello:v0.1 echo hello world
hello world
```
__ATTENZIONE:__ quando lanciamo un container passandogli un comando da eseguire, esso andrà a sovrascrivere l'istruzione __CMD__ definita nel Dockerfile.

## Image Layers
Quando avviamo un'immagine, essa ci appare come un unico _filesystem_ contenente il sistema operativo e la nostra applicazione.
In realtà le immagini sono formate da più __layer__ e ogni istruzione inserita nel Dockerfile crea un nuovo layer.
Alcune istruzioni eseguono anche un _commit_ del layer che creano, mentre altre istruzioni non effettuano il commit.
```bash
bom@princesspenny ~ $docker image history hello:v0.1
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
953fc4730149        8 seconds ago       /bin/sh -c #(nop)  CMD ["node" "index.js"]      0B                  
83cc031eceea        8 seconds ago       /bin/sh -c #(nop) WORKDIR /app                  0B                  
c6434e4bd005        8 seconds ago       /bin/sh -c #(nop) COPY dir:d8c0c3fbe4e2bc387…   12.7kB              
4f97d0fd8068        11 hours ago        /bin/sh -c apk update && apk add nodejs         46.1MB              
3fd9065eaf02        5 months ago        /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B                  
<missing>           5 months ago        /bin/sh -c #(nop) ADD file:093f0723fa46f6cdb…   4.15MB              
```
Quello che vediamo è la lista delle immagini intermedie che sono state create e committate durante la creazione della nostra immagine hello:v1.
Non tutti i layer creati durante la build vengono committati, alcuni sono temporanei e vengono rimossi nello step successivo della build.

Proviamo a modificare il nostro _index.js_ e vediamo come questo influisce sui layer della nostra immagine.
```bash
bom@princesspenny ~ $ echo "console.log(\"this is v0.2\");" >> index.js
bom@princesspenny ~ $ docker image build -t hello:v0.2 .
Sending build context to Docker daemon   16.9kB
Step 1/5 : FROM alpine
 ---> 3fd9065eaf02
Step 2/5 : RUN apk update && apk add nodejs
 ---> Using cache
 ---> 4f97d0fd8068
Step 3/5 : COPY . /app
 ---> 1414d5d0c86b
Step 4/5 : WORKDIR /app
Removing intermediate container e1c002459df2
 ---> 3b2550c55667
Step 5/5 : CMD ["node","index.js"]
 ---> Running in cd5ae2990a86
Removing intermediate container cd5ae2990a86
 ---> 25342fe1aa40
Successfully built 25342fe1aa40
Successfully tagged hello:v0.2
```
L'output del comando di build riporta sempre l'esecuzione di 5 step, ma alcuni di essi riportano l'indicazione __Using cache__.
![Docker Build Cache](https://training.play-with-docker.com/images/ops-images-cache.svg)
https://training.play-with-docker.com

## Riassunto
Facciamo un breve riassunto dei comandi e delle opzioni finora utilizzate:

Management Command | Command | Option | Behavior
-------------------|---------|--------|---------
image | pull | | Pull an image or a repository from a registry
image | ls | | List images
image | tag | | Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
image | build | | Build an image from a Dockerfile
| | | -t, --tag list | Name and optionally a tag in the 'name:tag' format
image | history | | Show the history of an image
image | inspect | | Display detailed information on one or more images
| | | -f, --format string | Format the output using the given Go template
container | run | | Run a command in a new container
| | | -i, --interactive | Keep STDIN open even if not attached 
| | | -t, --tty | Allocate a pseudo-TTY
container | exec | | Run a command in a running container
| | | -i, --interactive | Keep STDIN open even if not attached 
| | | -t, --tty | Allocate a pseudo-TTY
container | start | | Start one or more stopped containers
container | stop | | Stop one or more running containers
container | ls | | List running containers
| | | -a, --all | Show all containers (default shows just running)

Dockerfile Quick Reference:

Instruction | Commit Layer | Reference
------------|--------------|----------
FROM | No | Initializes a new build stage and sets the Base Image for subsequent instructions. As such, a valid Dockerfile must start with a FROM instruction. The image can be any valid image – it is especially easy to start by pulling an image from the Public Repositories.
RUN | Yes | Will execute any commands in a new layer on top of the current image and commit the results. The resulting committed image will be used for the next step in the Dockerfile.
COPY | Yes | Copies new files or directories from <src> and adds them to the filesystem of the container at the path <dest>.
WORKDIR | No | Instruction sets the working directory for any RUN, CMD, ENTRYPOINT, COPY and ADD instructions that __follow__ it in the Dockerfile. If the WORKDIR doesn’t exist, it will be created even if it’s not used in any subsequent Dockerfile instruction.
CMD | No | There can only be one CMD instruction in a Dockerfile. If you list more than one CMD then only the last CMD will take effect. __The main purpose of a CMD is to provide defaults for an executing container.__ These defaults can include an executable, or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.
___

Copyright (C) 2018-2019 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).

Images from [Play with Docker classroom](https://training.play-with-docker.com/about/)
