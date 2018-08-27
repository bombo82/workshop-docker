# Workshop Docker - Modulo 1

Concetti in questo modulo:
- Docker engine
- Containers e images
- Container isolation

## Eseguiamo il nostro primo container
Bando alla ciance, la cosa migliore è sporcarci le mani con "Hello World"!
```bash
bom@princesspenny ~ $ docker container run hello-world
```
Yeah! il nostro primo container saluta il mondo :-)

![What Happened Image](https://training.play-with-docker.com/images/ops-basics-hello-world.svg)
https://training.play-with-docker.com

Molti di noi hanno un buona confidenza con le VMs e potreste pensare che quello che è successo è molto simile a lanciare una VM presa da un repository.
Fondamentalmente questo è abbastanza vero, ma la natura dei container è molto differente da quella delle VM!
Per il momento possiamo affermare che:
* una VM è un'astrazione _hardware_: prende risorse fisiche CPU e RAM da un host che lo divide e lo condivide tra diverse macchine virtuali più piccole. Esiste un sistema operativo e un'applicazione in esecuzione all'interno della VM, ma di solito il software di virtualizzazione non ne sa nulla.
* un container è un'astrazione a livello _software_: il focus è sul sistema operativo host che mette a disposizione risorse ai container. All'interno del container non vi è un sistema operativo in esecuzione, ma solo delle applicazioni.
L'_engine_ che esegue i container demanda, al sistema operativo host, l'esecuzione delle applicazioni all'interno dei container.

Molte persone utilizzano attualmente sia VM che container nei loro ambienti e, di fatto, possono eseguire container all'interno di VM.

## Images

L'immagine utilizza per il nostro __hello world__ ci propone di provare a usare un container con ubuntu... io preferisco per svariati motivi preferisco usare [Alpine Linux](http://www.alpinelinux.org/).
Essa è una distribuzione GNU/Linux molto _leggera_ e di piccole dimensioni che può essere scaricata e avvia in pochi istanti.
Dato che al suo interno vi è solo il software essenziale, essa è molto utilizzata come base per altre _images_.
```bash
bom@princesspenny ~ $ docker image pull alpine
```
Il comando _pull_ scarica l'immagine richiesta dal __Docker Registry__, che nel nostro caso è [Docker Store](https://store.docker.com/)
Questo è il repository per le immagini di default ed è anche quello ufficiale.

Bene, ora che abbiamo scaricato l'immagine _alpine_ dov'è finita?
```bash
bom@princesspenny ~ $ docker image ls

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-world         latest              e38bc07ac18e        2 months ago        1.85kB
alpine              latest              3fd9065eaf02        5 months ago        4.15MB
```

Proviamo ad eseguirla:
```bash
bom@princesspenny ~ $ docker container run alpine
```
mmm, ma avrà fatto qualcosa? Provviamo a leggere l'help:
```bash
bom@princesspenny ~ $ docker container run --help

Usage:  docker container run [OPTIONS] IMAGE [COMMAND] [ARG...]

Run a command in a new container
```

Ma guarda, _run_ esegue un comando all'interno di un nuovo container...
non si limita ad avviare il container! Allora proviamo con:
```bash
bom@princesspenny ~ $ docker container run alpine ls -l
total 8
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 bin
drwxr-xr-x    5 root     root           340 Jun 20 19:16 dev
drwxr-xr-x    1 root     root            66 Jun 20 19:16 etc
drwxr-xr-x    2 root     root             6 Jan  9 19:37 home
drwxr-xr-x    5 root     root           234 Jan  9 19:37 lib
drwxr-xr-x    5 root     root            44 Jan  9 19:37 media
drwxr-xr-x    2 root     root             6 Jan  9 19:37 mnt
dr-xr-xr-x  438 root     root             0 Jun 20 19:16 proc
drwx------    2 root     root             6 Jan  9 19:37 root
drwxr-xr-x    2 root     root             6 Jan  9 19:37 run
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 sbin
drwxr-xr-x    2 root     root             6 Jan  9 19:37 srv
dr-xr-xr-x   13 100      root             0 Jun 14 09:50 sys
drwxrwxrwt    2 root     root             6 Jan  9 19:37 tmp
drwxr-xr-x    7 root     root            66 Jan  9 19:37 usr
drwxr-xr-x   11 root     root           125 Jan  9 19:37 var
``` 
![Run Details](https://training.play-with-docker.com/images/ops-basics-run-details.svg)
https://training.play-with-docker.com

E' giunto il momento di venir salutati da Alpine Linux, che ne dite?
```bash
bom@princesspenny ~ $ docker container run alpine echo "hello from alpine"
hello from alpine
```
E se ora provassimo ad eseguire una shell?
```bash
bom@princesspenny ~ $ docker container run alpine /bin/sh
```
mmm, non succede nulla, che sia un bug :-(
Verifichiamo i container attivi:
```bash
 bom@princesspenny ~ $ docker container ls
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
Proviamo con l'opzione __-a__ che ci mostra tutti i container creati, anche quello non più attivi:
```bash
bom@princesspenny ~ $ docker container ls -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                         PORTS               NAMES
485b4d233567        alpine              "/bin/sh"           6 minutes ago       Exited (0) 6 minutes ago                           affectionate_bohr
3d7eda8791bc        alpine              "ls -l"             18 minutes ago      Exited (0) 18 minutes ago                          vigilant_colden
774ce0c35f14        hello-world         "/hello"            About an hour ago   Exited (0) About an hour ago                       romantic_bell
```
Ottimo, in realtà funziona tutto come ci aspettiamo... semplicemente viene lanciato il comando __/bin/sh__ che termina immediatamente, perché __docker-engine__ si limita a fare bind e redirect dell'output del container verso l'host.
Come facciamo a fare il bind dell'input dall'host verso il container? E' necessario usare l'opzione __-it__ del comando _run_
```bash
bom@princesspenny ~ $ docker container run -it alpine /bin/sh
/ # 
```

## Isolation
Nel passo precedente abbiamo avviato alcuni container ed eseguito comandi al loro interno.
Dovremmo avere ancora una shell aperta in modo interattivo all'interno di un container.
Proviamo a vedere cosa accade se modifichiamo il filesystem del container... che ne dite di creare un nuovo file e chiudere la shell?!
```bash
/ #  echo "hello world" > hello.txt
/ # ls -l
total 56
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 bin
drwxr-xr-x    5 root     root           360 Jun 20 19:45 dev
drwxr-xr-x    1 root     root          4096 Jun 20 19:45 etc
-rw-r--r--    1 root     root            12 Jun 20 19:46 hello.txt
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 home
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 lib
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 media
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 mnt
dr-xr-xr-x  309 root     root             0 Jun 20 19:45 proc
drwx------    1 root     root          4096 Jun 20 19:46 root
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 run
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 sbin
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 srv
dr-xr-xr-x   12 root     root             0 Jun 20 19:45 sys
drwxrwxrwt    2 root     root          4096 Jan  9 19:37 tmp
drwxr-xr-x    7 root     root          4096 Jan  9 19:37 usr
drwxr-xr-x   11 root     root          4096 Jan  9 19:37 var
/ # exit
```
Ora lanciamo nuovamente __ls__ all'interno del container
```bash
bom@princesspenny ~ $ docker container run alpine ls -l
total 52
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 bin
drwxr-xr-x    5 root     root           340 Jun 20 19:52 dev
drwxr-xr-x    1 root     root          4096 Jun 20 19:52 etc
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 home
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 lib
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 media
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 mnt
dr-xr-xr-x  317 root     root             0 Jun 20 19:52 proc
drwx------    2 root     root          4096 Jan  9 19:37 root
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 run
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 sbin
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 srv
dr-xr-xr-x   12 root     root             0 Jun 20 19:52 sys
drwxrwxrwt    2 root     root          4096 Jan  9 19:37 tmp
drwxr-xr-x    7 root     root          4096 Jan  9 19:37 usr
drwxr-xr-x   11 root     root          4096 Jan  9 19:37 var
```
Che fine ha fatto il nostro _hello.txt_ ??
Come avete già intuito, quando usiamo il comando _run_ viene creato un nuovo container, al suo interno viene eseguito il comando specificato e al termine dell'esecuzione del comando viene terminato anche il container!
Visualizziamo la lista dei container presenti nel nostro sistema e cerchiamo di capire quale di essi continer il file _hello.txt_.
```bash
bom@princesspenny ~ $ docker container ls -a
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                            PORTS               NAMES
7866959f81a5        alpine              "ls -l"             About a minute ago   Exited (0) About a minute ago                         zen_darwin
95cb77e78511        alpine              "/bin/sh"           2 minutes ago        Exited (127) About a minute ago                       eloquent_proskuriakova
```
Riusciamo a identificarlo tramite il comando eseguito e l'indicazione di quando è stato creato.
Possiamo avviarlo usando il comando __docker container start__ e passandogli il _CONTAINER ID_
```bash
bom@princesspenny ~ $ docker container start 95cb77e78511
```
Bene, verifichiamo se effettivamente il container sta girando:
```bash
bom@princesspenny ~ $ docker container ls
```
Si, è up & running... prima avevamo una shell interattiva in cui potevamo eseguire dei comandi, mentre ora non abbiamo modo di usare tale shell.
Ci viene utile un altro comando di docker
```bash
bom@princesspenny ~ $ docker container exec 95cb77e78511 ls -l
total 56
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 bin
drwxr-xr-x    5 root     root           360 Jun 23 16:12 dev
drwxr-xr-x    1 root     root          4096 Jun 23 16:01 etc
-rw-r--r--    1 root     root            12 Jun 23 16:01 hello.txt
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 home
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 lib
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 media
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 mnt
dr-xr-xr-x  310 root     root             0 Jun 23 16:12 proc
drwx------    1 root     root          4096 Jun 23 16:01 root
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 run
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 sbin
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 srv
dr-xr-xr-x   12 root     root             0 Jun 23 16:12 sys
drwxrwxrwt    2 root     root          4096 Jan  9 19:37 tmp
drwxr-xr-x    7 root     root          4096 Jan  9 19:37 usr
drwxr-xr-x   11 root     root          4096 Jan  9 19:37 var
```
Ecco, abbiamo ritrovato il nostro file _hello.txt_ :-)
![Container isolation](https://training.play-with-docker.com/images/ops-basics-isolation.svg)
https://training.play-with-docker.com

## Ma che confusione... run, exec e start
In questo modulo abbiamo visto i comandi:
* _run_: instanzia un container, lo avvia, esegue un comando al suo interno e, al termine dell'esecuzione del comando, ferma il container
* _exec_: esegue un comando all'interno del container specificato
* _start_: avvia un container attualmente fermo

Nel [Modulo 5](./module04/README.md), vedremo nel dettaglio cosa fanno e le differenze tra i tre comandi.
Al momento ci mancano alcune nozioni per comprendere a fondo il loro comportamento.

## Riassunto
Facciamo un breve riassunto dei comandi e delle opzioni finora utilizzate:

Management Command | Command | Option | Behavior
-------------------|---------|--------|---------
image | pull | | Pull an image or a repository from a registry
image | ls | | List images
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

___

Copyright (C)  2018  Gianni Bombelli @ Intré S.r.l.

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).

Images from [Play with Docker classroom](https://training.play-with-docker.com/about/)
