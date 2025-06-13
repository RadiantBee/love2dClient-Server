## Why?
<p> I'm a beginner at game netwoking. I've made a few litte projects before and the net-code was awful The information on this topic is incredibly spread over the internet.
I've found it quite hard to find some more advanced info on networking other than "How to set-up socket udp connection" type of stuff.</p>
<p> So I descided to make this little template of a (good enough, I hope) server-client model for games. </p>

## What is it?
<p> This is a prototype of a Authoritative Server built on UDP socket with immediate broadcasting. Huh, what a mouthful! </p>
<p> To better understand what does this means, first we have to explore the types of fundamental models of online communication.</p>
<p> In terms of subjects of communication: </p>

- p2p connection (peer-to-peer) - everyone is connected dirrectly to eachother
- client-server - every player is connected to server, wich manages all communication

<p> In terms of relation between subjects of communication: </p>

- p2p can have:
  - Host-Peer relation - Host is the main user that manages important aspects of communication and game synchronization.
  - Decentralized - I don't really know if it's viable for games, but it still exists and it is beeing used for torrents and stuff... 

p2p ususally is used for co-op games. For 2 players it's quite easy do develop 'cause there is no need to worry about managing scalability, complex communication and synchronisation between lost of players.

- client-server:
    - Authoritative Server - Server runes the game and provides players with the game state.
    - Listener Server - The game is run locally while server only transfers data between clients.

I would say that the most common approach in the Authoritative Server because it's quite flexible and makes it hard to abuse your system.

Now let's categorise the methods that can be used to update and synchronise players:
 - Lockstep. This method can be used with server and p2p architecture. The main idea is that there are determined steps that have to be competed in order to proceed. So game is "locked" and waits for evey
player to complete these steps. It's the most common method of organising communication in strategy games.
    - Pros: great synchonisation and low bandwidth usage.
    - Cons: can be easily broken if someone lags. Long waiting periods.
 - Event-Based. Server recieves events from users (for example inputs like "move-forward", "jump"), processes them and then relays them to everyone. I believe somethis similar is used in Terarria. When
someone lags out, it's possible to observe how game updates are quickly rewinded forward while you get up to synch.
    - Pros: very low bandwidth 'cause only inputs are sent, easy to implement.
    - Cons: hard to synchonise new player to the game state, players can lie about theirs input-states.
 - State-sync. Usually this means that server has some timer that updated everyone every "tick", in time between ticks server processes client sent information. This approach extremely common in multiplayer
competitive games.
    - Pros: good synchronisation, alright bandwidth usage (while packets can be large, they are timed can be predicted), easy to scale
    - Cons: it's very hard to fully implement state-sync, there are a lot and lot of different things that have to be accounted to get the best implementation. Hard to cheat.
 - Immediate Broadcasting. The moment server recieves an update from client, server processes it and sends it to every other players. Good for fast-paced games, where latency is crucial.
    - Pros: very low latency and low bandwidth usage (small packets are sent very frequently).
    - Cons: frequent updates can "clog" slow clients, it's better to use with a low amount of clients.

<p> Phew... And you should take in account that these methods can be combined in a various amont of ways. </p>
<p> I tried to implement state-sync approach, but in the end my solution was jittery and looked quite bad. </p>
