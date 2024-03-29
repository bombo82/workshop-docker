# Workshop Docker - Modulo 4.2

Alcune istruzioni dei Dockerfile sembrano molto simili e spesso vengono usate in modo intercambiabile, anche se non lo sono.
In questo modulo vorrei fare un po' di chiarezza su queste istruzioni, così che possano essere utilizzate in modo più consapevole.

## ADD vs COPY
Il funzionamento è molto simile e in generale è preferibile usare __COPY__, perché ha un comportamento più trasparente rispetto all'istruzione __ADD__.
__COPY__ permette solamente di copiare file o directory locali all'interno dell'immagine; mentre, __ADD__ ha delle funzionalità aggiuntive quali decomprimere archivi compressi e il supporto agli URL remoti.
Queste funzionalità aggiuntive, rendono l'istruzione __ADD__ molto potente, ma diventa poco immediata e a volte il risultato atteso è differente da quello reale... soprattutto all'inizio!

Quando più passi nel Dockerfile utilizzano file diversi copiati dell'esterno, è preferibile copiarli singolarmente con __COPY__, piuttosto che copiare tutta la directory o un archivio.
Ciò garantisce che la cache dei layer per ogni passaggio sia invalidata (forzando la fase di riesecuzione) se i file specificatamente richiesti cambiano e non se cambia uno qualsiasi dei file contenuti nella directory.
```dockerfile
FROM python
COPY requirements.txt /tmp/requirements.txt
RUN pip install -qr /tmp/requirements.txt
WORKDIR /src
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```
E' sconsigliato usare __ADD__ per scaricare file da URL remoti perché è poco efficiente, piuttosto usa curl o wget.
```dockerfile
RUN mkdir -p /usr/src/things \
    && curl -SL https://example.com/big.tar.xz \
    | tar -xJC /usr/src/things \
    && make -C /usr/src/things all
```

## ENTRYPOINT vs CMD
__Spesso vengono considerati la stessa cosa e non esiste nulla di più sbagliato!__
Le due istruzioni hanno un significato e un comportamento completamente differente, anche se in alcuni casi otteniamo lo stesso risultato.

### CMD
Ha tre differenti forme sintattiche (andiamo bene):
1. __CMD ["executable","param1","param2"]__ _exec form_
2. __CMD ["param1","param2"]__ _as default parameters to ENTRYPOINT_
3. __CMD command param1 param2__ _shell form_

Lo scopo principale (forma 1 e 3), è quello di fornire un comando di default da eseguire all'interno del container.
Se sono presenti più istruzioni __CMD__ l'ultima incontrata vince!
Se viene passato un comando tramite _docker container run_ quest'ultimo viene eseguito e sovrascrive l'eventuale istruzione __CMD__ presente nel Dockerfile.

Se è definito un __ENTRYPONT__ l'istruzione __CMD__ assume il senso di _parametro di default per l'istruzione __ENTRYPOINT___ (forma 2). 

Esempio Dockerfile-cmd:
```dockerfile
FROM alpine
CMD ["ping", "localhost"]
```

```bash
bombo82@nolok ~ $ docker image build -f esempi/Dockerfile-cmd -t ping:cmd esempi
Sending build context to Docker daemon  2.048kB
Step 1/2 : FROM alpine
latest: Pulling from library/alpine
ff3a5c916c92: Pull complete 
Digest: sha256:e1871801d30885a610511c867de0d6baca7ed4e6a2573d506bbec7fd3b03873f
Status: Downloaded newer image for alpine:latest
 ---> 3fd9065eaf02
Step 2/2 : CMD ["ping", "localhost"]
 ---> Running in 8fa43310dd31
Removing intermediate container 8fa43310dd31
 ---> 68f69729a39d
Successfully built 68f69729a39d
Successfully tagged ping:cmd
```

Proviamo ad eseguire il container senza passare un comando esterno:
```bash
bombo82@nolok ~ $ docker container run ping:cmd
PING localhost (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: seq=0 ttl=64 time=0.043 ms
64 bytes from 127.0.0.1: seq=1 ttl=64 time=0.058 ms
^C
--- localhost ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.043/0.050/0.058 ms
```

Come ci aspettavamo è stato eseguito il comando _ping_ verso l'host _localhost_. Ora proviamo a passare alcuni comandi e vediamo cosa accade:
```bash
bombo82@nolok ~ $ docker container run ping:cmd ping www.google.it
PING www.google.it (172.217.19.131): 56 data bytes
64 bytes from 172.217.19.131: seq=0 ttl=52 time=30.429 ms
64 bytes from 172.217.19.131: seq=1 ttl=52 time=30.695 ms
^C
--- www.google.it ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 30.429/30.562/30.695 ms

bombo82@nolok ~ $ docker container run ping:cmd ls -l
total 52
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 bin
drwxr-xr-x    5 root     root           340 Jun 24 18:10 dev
drwxr-xr-x    1 root     root          4096 Jun 24 18:10 etc
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 home
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 lib
drwxr-xr-x    5 root     root          4096 Jan  9 19:37 media
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 mnt
dr-xr-xr-x  330 root     root             0 Jun 24 18:10 proc
drwx------    2 root     root          4096 Jan  9 19:37 root
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 run
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 sbin
drwxr-xr-x    2 root     root          4096 Jan  9 19:37 srv
dr-xr-xr-x   12 root     root             0 Jun 24 18:10 sys
drwxrwxrwt    2 root     root          4096 Jan  9 19:37 tmp
drwxr-xr-x    7 root     root          4096 Jan  9 19:37 usr
drwxr-xr-x   11 root     root          4096 Jan  9 19:37 var

```

Il _container_ esegue i comandi passati al posto di quello inserito nel dockerfile, purché i relativi eseguibili siano installati all'interno del _container_, potremmo anche installare nuovo software malevolo!!!.

### ENTRYPOINT
Ha solo due differenti forme:
* __ENTRYPOINT ["executable", "param1", "param2"]__ _exec form, preferred_
* __ENTRYPOINT command param1 param2__ _shell form_

Questa istruzione definisce un eseguibile (binario o script) che verrà eseguito all'interno del container.
Potremmo dire che ___ENTRYPOINT__ rende un container un file eseguibile_ e in realtà il comportamento è molto simile.

L'istruzione __ENTRYPOINT__ viene utilizzata principalmente per inizializzare il container ed eseguire delle applicazioni come se fossero dei servizi.
Le immagini docker ufficiali di _redis_, _postgres_, _mongo_ e molte altre, utilizzano proprio un __ENTRYPOINT__ con uno specifico script di inizializzazione per avviare il servizio e __CMD__ per definire dei parametri di default.

Tramite _docker container run_ possiamo passare dei parametri che verranno concatenati a quelli presenti nell'istruzione __ENTRYPOINT__, ma non possiamo fare un "_overrride_" del comando da eseguire.
```dockerfile
FROM alpine
ENTRYPOINT ["ping", "localhost"]
```

```bash
bombo82@nolok ~ $ docker image build -f esempi/Dockerfile-entrypoint -t ping:entrypoint esempi
Sending build context to Docker daemon  3.072kB
Step 1/2 : FROM alpine
 ---> 3fd9065eaf02
Step 2/2 : ENTRYPOINT ["ping", "localhost"]
 ---> Running in 93dcade74014
Removing intermediate container 93dcade74014
 ---> aba6a34d6b74
Successfully built aba6a34d6b74
Successfully tagged ping:entrypoint
```

Proviamo ad eseguire il container senza passare un comando esterno:
```bash
bombo82@nolok ~ $ docker container run ping:entrypoint
PING localhost (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: seq=0 ttl=64 time=0.048 ms
64 bytes from 127.0.0.1: seq=1 ttl=64 time=0.049 ms
^C
--- localhost ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.048/0.048/0.049 ms
```

Come vi aspettavamo è stato eseguito il comando _ping_ verso l'host _localhost_. Ora proviamo a passare alcuni comandi e vediamo cosa accade:
```bash
bombo82@nolok ~ $ docker container run ping:entrypoint ls -l
ping: unrecognized option: l
BusyBox v1.27.2 (2017-12-12 10:41:50 GMT) multi-call binary.

Usage: ping [OPTIONS] HOST

Send ICMP ECHO_REQUEST packets to network hosts

        -4,-6           Force IP or IPv6 name resolution
        -c CNT          Send only CNT pings
        -s SIZE         Send SIZE data bytes in packets (default 56)
        -t TTL          Set TTL
        -I IFACE/IP     Source interface or IP address
        -W SEC          Seconds to wait for the first response (default 10)
                        (after all -c CNT packets are sent)
        -w SEC          Seconds until ping exits (default:infinite)
                        (can exit earlier with -c CNT)
        -q              Quiet, only display output at start
                        and when finished
        -p              Pattern to use for payload
```

In questo caso otteniamo un errore! Il _CMD_ passato dall'esterno viene utilizzato come parametri aggiuntivi per il comando definito dal _ENTRYPOINT_, quindi non è possibile eseguire comandi arbitrari passati dall'esterno.

### Combinare ENTRYPOINT e CMD
Come diretta conseguenza di quanto detto sopra potremmo combinare __ENTRYPOINT__ e __CMD__.
L'istruzione __ENTRYPOINT__  è utilizzabile per definire l'eseguibile da lanciare all'interno del container e tramite __CMD__ e _docker container run_ possiamo passare i parametri necessari alla sua esecuzione.

Tornando all'esempio del ping, definiamo il seguente Dockerfile:
```dockerfile
FROM alpine
ENTRYPOINT ["ping", "-c", "3"]
CMD ["localhost"]
```
```bash
bombo82@nolok ~ $ docker image build -t ping:combined esempi
Sending build context to Docker daemon  4.096kB
Step 1/3 : FROM alpine
 ---> 3fd9065eaf02
Step 2/3 : ENTRYPOINT ["ping", "-c", "3"]
 ---> Running in 6c7b51198362
Removing intermediate container 6c7b51198362
 ---> e996e3b27ded
Step 3/3 : CMD ["localhost"]
 ---> Running in 9792f87ff5b8
Removing intermediate container 9792f87ff5b8
 ---> 558d5fcd22ca
Successfully built 558d5fcd22ca
Successfully tagged ping:combined
```

Proviamo ad eseguire il container senza passare un comando esterno:
```bash
bombo82@nolok ~ $ docker container run ping:combined
PING localhost (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: seq=0 ttl=64 time=0.047 ms
64 bytes from 127.0.0.1: seq=1 ttl=64 time=0.059 ms
64 bytes from 127.0.0.1: seq=2 ttl=64 time=0.057 ms

--- localhost ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.047/0.054/0.059 ms
```

Niente di nuovo, continua a funzionare tutto come in precedenza! Ora passiamo un nome host differente come parametro.
```bash
bombo82@nolok ~ $ docker container run ping:combined www.google.it
PING www.google.it (172.217.19.131): 56 data bytes
64 bytes from 172.217.19.131: seq=0 ttl=52 time=29.998 ms
64 bytes from 172.217.19.131: seq=1 ttl=52 time=29.385 ms
64 bytes from 172.217.19.131: seq=2 ttl=52 time=29.766 ms

--- www.google.it ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 29.385/29.716/29.998 ms
```

Avendo combinato **ENTRYPOINT** con **CMD** possiamo lanciare il container con alcuni parametri che andranno a sovrascrivere il contenuto del **CMD**, oppure senza parametri e verranno utilizzati quelli di default definiti dall'istruzione **CMD**.
Se ora proviamo a lanciare il container con un comando arbitrario, esso verrà interpretato come parametro del **ENTRYPOINT** che abbiamo definito, con il risultato che ci sarà restituito un errore!
```bash
bombo82@nolok ~ $ docker container run ping:combined ls -l
ping: unrecognized option: l
BusyBox v1.27.2 (2017-12-12 10:41:50 GMT) multi-call binary.

Usage: ping [OPTIONS] HOST

Send ICMP ECHO_REQUEST packets to network hosts

        -4,-6           Force IP or IPv6 name resolution
        -c CNT          Send only CNT pings
        -s SIZE         Send SIZE data bytes in packets (default 56)
        -t TTL          Set TTL
        -I IFACE/IP     Source interface or IP address
        -W SEC          Seconds to wait for the first response (default 10)
                        (after all -c CNT packets are sent)
        -w SEC          Seconds until ping exits (default:infinite)
                        (can exit earlier with -c CNT)
        -q              Quiet, only display output at start
                        and when finished
        -p              Pattern to use for payload
```

### Conclusioni
Abbiamo scoperto che **ENTRYPOINT** e **CMD** sono due istruzioni differenti, anche se potrebbero venir confuse e utilizzate in modo improprio!
Purtroppo questa confusione è dovuta ai nomi delle due istruzioni e alla possibilità di usare entrambe per lanciare un comando, anche se il modo migliore di utilizzarle è proprio quello di combinarle tra loro.

In conclusione, dovremmo utilizzarle nel seguente modo:
- **ENTRYPOINT:** definire l'istruzione da eseguire all'avvio del _container_ comprensiva degli eventuali parametri obbligatori che non vogliamo esporre all'estreno del _container_;
- **CMD:** fornire i valori di default per i parametri opzionali, che potranno essere sovrascritti all'avvio del _container_ al momento dell'avvio dello stesso.

___

[prev](../module04.1/README.md)  [home](../../README.md) [up](../README.md)  [next](../module04.3/README.md)

Copyright (C) 2018-2022 Gianni Bombelli and Contributors

[![Image](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

Except where otherwise noted, content on this documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
