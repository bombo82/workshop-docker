# Workshop Docker - Modulo 5

Concetti in questo modulo:
- Diamo un senso ai comandi run, exec e start
- Statistiche di utilizzo delle risorse

## Ciclo di vita di un container
Per capire come funzionano i comandi __run__, __exec__ e __start__ è necessario dare un occhio agli internals di docker.

![event state](http://docker-saigon.github.io/img/event_state.png)
http://docker-saigon.github.io/img/event_state.png

### create
Il comando __create__ crea un nuovo container basato sull'immagine che volete! ma non si limita a fare solo questo...

Tramite il comando __create__ è possibili inizializzare il container sfruttanto parecchie opzioni, per esempio:
* inizializzare l'interfaccia di rete interna al container (ip, hostname, dns, host file, etc.)
* definire le risorse massime utilizzabile dal container (CPUs, RAM, device iops e bps, etc.)
* definire policy di sicurezza (cgroups, isolation, etc.)
* esporre e mappare porte e volumi
* definire variabili d'ambiente (direttamente o tramite file)
* fare overwrite del __ENTRYPOINT__ di default definito nel _Dockerfile_
* un sacco di altre opzioni

### start
Il comando __start__ si limita, per davvero, ad avviare uno o più container ed eseguire le istruzioni presenti negli __ENTRYPOINT__ e/o nei __RUN__ del container. 

Questo comando ha poche opzioni:
* -a, --attach : redirige lo STDOUT/STDERR e i _signals_
* -i, --interactive : redirige lo STDIN
La particolarità di questo comando è che esso accetta un elenco di container e li avvia tutti. 

Come comportamento di default il comando _start_ esegue i container in modo __detached__, cioè senza redirect di STDOUT/STDERR, quindi eseguendo un container non vedremo in console alcun messaggio di quello ceh sta accadendo.

### run
Il comando __run__ esegue, internament e in successione, il comando _create_ e poi il comando _start_.

Le opzioni messe a disposizione dal comando __run__ corrispondono, con buona approssimazione, alle opzioni messe a dispozione dal comando _create_ più quelle del comando _start_.
A differenza del comando _start_, ma come il comando _create_ accetta come parametro una sola immagine e crea ed esegue un solo container.

Il comando _run_, come comportamento di default, avvia il container in modo __attached__, cioè facendo il redirect di STDOUT/STDERR e questo ci permette di visualizzate il risultato dei comandi eseguiti internamente al container.

### exec
Esegue un comando all'interno del container. Esso non ha alcune legame con i comandi definiti in __ENTRYPOINT__ e __RUN__.

Come impostazione di default vine eseguito in modo _attached_, ma non interattivo (senza redirect di STDIN) e senza allocare uno pseudo-TTY ... ricordate che negli esempi precedenti abbiamo eseguito una shell linux internamente al container e usando le opzioni `-i -t` o `-it`? queste opzioni ci hanno permesso di utilizzare la bash internamente al container!
Possiamo definire un environemt particolare o una workdir e passarli come parametri al comandoi _exec_.

## Interrogare docker per vedere processi e risorse
Dovremmo aver imparato a creare immagini e a trasformarle ed eseguirle sotto forma di container.
Giunti a questo punto dovremmo essere consapevoli di come funziona docker, di alcuni principi rigardanti i container e dovremmo avere ababstanza dimestichezza per creare i nostri container e le nostre immagini.

Manca ancora un tassello molto importante, ~~se vogliamo essere persone migliori~~, diventare consapevoli di cosa stiamo eseguendo all'interno dei container e le risorse sono utilizzate.

Esistono due comandi:
* _docker container stats_ : mostra le statistiche delle risorse utilizzate da tutti i container in esecuzione
* _docker container top_ : mostra i processi in esecuzione all'interno del container

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
