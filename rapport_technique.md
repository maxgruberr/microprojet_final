## 2. Description technique de l’application et du matériel

Cette section détaille l'architecture matérielle et logicielle de l'application de jeu de bataille navale implémentée sur le microcontrôleur ATmega128.

### 2.1 Périphériques Matériels Utilisés

Le système est construit autour des composants suivants :

*   **Microcontrôleur ATmega128 :** Cerveau du système, il exécute le code du jeu, gère les périphériques et les interfaces.
*   **Carte de développement AVR SK300 :** Plateforme fournissant l'infrastructure de base pour l'ATmega128, incluant l'alimentation et des périphériques de test (LEDs, boutons).
*   **Interface de communication FTDI :** Un câble FTDI (USB vers série) est utilisé pour relier le port UART0 de l'ATmega128 à un terminal PC (par exemple, RealTerm). Cela permet l'envoi de commandes clavier pour le jeu.
*   **Matrice LED WS2812B (8x8) :** Principal dispositif d'affichage du jeu. Elle représente les grilles de bataille et l'état des navires.
*   **Écran LCD Hitachi HD44780U (2x16) :** Affichage secondaire utilisé pour les messages textuels, les instructions et l'état du jeu.
*   **Programmation/Débogage :** Un programmateur AVRISP-U est utilisé conjointement avec l'environnement de développement Atmel Studio 7 pour charger le programme sur l'ATmega128 et pour le débogage.

### 2.2 Utilisation des Ports du Microcontrôleur ATmega128

Les ports d'E/S de l'ATmega128 sont configurés comme suit :

*   **PORTA (AD0-AD7) :** Utilisé comme bus de données pour l'interface XMEM (External Memory Interface) connectée à l'écran LCD.
*   **PORTB :** Configuré en sortie. Utilisé brièvement au démarrage pour contrôler les LEDs de la carte STK300 à des fins de diagnostic.
*   **PORTC :**
    *   Certaines lignes de ce port sont utilisées comme lignes de contrôle pour l'interface XMEM (ALE, /RD, /WR) connectée à l'écran LCD. La configuration exacte dépend du schéma de câblage spécifique entre l'ATmega128 et le LCD via la SK300. (Note : L'analyse initiale suggère PORTG ou PORTC, mais `main.asm` configure DDRC en entrée, ce qui est contradictoire si utilisé pour le contrôle XMEM. Ce point pourrait nécessiter une vérification sur le matériel réel ou le schéma détaillé. Pour ce document, nous nous basons sur l'usage potentiel pour XMEM comme indiqué dans l'analyse.)
    *   Dans `main.asm`, `DDRC` est configuré en entrée, suggérant une utilisation pour les boutons de la STK300, bien que le jeu principal utilise l'UART pour les commandes.
*   **PORTD :**
    *   `PD1` (bit 1 de PORTD) : Utilisé comme ligne de données série pour commander la matrice de LEDs WS2812B.
    *   `PIND` (registre d'entrée de PORTD) : Suggéré par `definitions.asm` pour la lecture des boutons de la STK300, mais non activement utilisé par la logique principale du jeu.
*   **PORTE :**
    *   `PE0 (RXD0)` : Ligne de réception (entrée) pour l'UART0, connectée à l'interface FTDI pour recevoir les commandes du clavier depuis le PC.
    *   `PE1 (TXD0)` : Ligne de transmission (sortie) pour l'UART0, connectée à l'interface FTDI pour envoyer des données au PC (non utilisé activement par le jeu mais configuré).
*   **PORTG :** Potentiellement utilisé pour les lignes de contrôle de l'interface XMEM (ALE, /RD, /WR) pour l'écran LCD, si non situées sur PORTC.

### 2.3 Interfaces d’Acquisition et d’Affichage

Le système communique avec l'utilisateur et affiche l'état du jeu via plusieurs interfaces :

*   **Interface d’Acquisition (Clavier via UART) :**
    *   L'acquisition des commandes du joueur (coordonnées de placement des bateaux, coordonnées de tir) se fait via le port série UART0.
    *   Le microcontrôleur ATmega128 reçoit les caractères envoyés depuis un terminal PC (par exemple, RealTerm) via un câble FTDI.
    *   La communication est configurée à un baud rate de 9600, avec 8 bits de données, pas de parité et 1 bit de stop (8-N-1).
    *   La réception des données est gérée par polling du flag `RXC0` (Receive Complete) dans le registre `UCSR0A`. Une fois le flag positionné, la donnée est lue depuis le registre `UDR0`.
    *   Les routines spécifiques de lecture et d'interprétation des commandes sont `read_uart_boat` (dans `placement.asm`) et `read_uart_bomb` (dans `battle.asm`).

*   **Interface d’Affichage (Écran LCD Hitachi HD44780U) :**
    *   L'écran LCD est un modèle 2x16 caractères, mappé en mémoire externe de l'ATmega128.
    *   Pour activer l'accès à la mémoire externe, le bit `SRE` (Enable External SRAM and XMEM) du registre `MCUCR` est mis à 1. Le bit `SRW10` du même registre est également activé pour introduire un état d'attente, assurant une communication stable avec le LCD.
    *   Le registre d'instruction (IR) du LCD est accessible à l'adresse `0x8000`.
    *   Le registre de données (DR) du LCD est accessible à l'adresse `0xC000`.
    *   La communication physique s'effectue via le bus XMEM, utilisant PORTA pour les données (AD0-AD7) et des lignes de contrôle (comme ALE, /RD, /WR) probablement issues de PORTG ou PORTC.
    *   Des routines de bas niveau pour l'écriture de commandes et de données sur le LCD sont définies dans `lcd.asm`.
    *   Le formatage du texte affiché sur le LCD est géré par les routines de `printf.asm`, qui utilisent les fonctions de `lcd.asm`.

*   **Interface d’Affichage (Matrice LED WS2812B) :**
    *   La matrice LED 8x8 RGB est l'affichage principal du jeu. Elle est utilisée pour visualiser les grilles des joueurs, la position des bateaux, les tirs et les animations.
    *   Elle est contrôlée par une unique ligne de données série connectée au port `PD1` de l'ATmega128.
    *   Les données représentant l'état des deux grilles de jeu (8x8 pixels, chaque pixel nécessitant 3 bytes pour les couleurs RGB) sont stockées en SRAM externe :
        *   Grille de placement : à partir de l'adresse `0x0400`.
        *   Grille du Joueur 1 (J1) : à partir de l'adresse `0x0500`.
        *   Grille du Joueur 2 (J2) : à partir de l'adresse `0x0600`.
    *   Les routines pour envoyer les données à la matrice LED, dessiner les éléments graphiques (fond, bateaux, curseur, explosions) et gérer les pointeurs vers ces grilles en mémoire sont implémentées dans `drawing.asm`, `battle.asm`, et `placement.asm`.

### 2.4 Gestion des Interruptions

Le système utilise une interruption principale pour gérer le timing du jeu :

*   **Interruption par débordement du Timer/Counter0 (Timer0 Overflow) :**
    *   Cette interruption est activée en mettant à 1 le bit `TOIE0` (Timer/Counter0 Overflow Interrupt Enable) dans le registre `TIMSK`.
    *   Le Timer0 est configuré pour utiliser un prescaler qui divise la fréquence de l'horloge système par 1024. Ceci est réalisé en écrivant la valeur `0x05` dans le registre `TCCR0B` (Timer/Counter0 Control Register B). (Note : L'analyse mentionne `TCCR0` dans `placement.asm`, il est supposé que cela réfère à `TCCR0B` pour l'activation du prescaler, car `TCCR0A` concerne le mode de fonctionnement du comparateur/PWM).
    *   Lorsque le Timer0 déborde, la routine de service d'interruption (ISR) nommée `overflow0` (définie dans `main.asm`) est exécutée.
    *   **Rôle de l'ISR `overflow0` :**
        *   Elle incrémente un compteur logiciel nommé `ov_count`.
        *   Lorsque `ov_count` atteint la valeur 10 (ce qui correspond approximativement à une durée de 0.65 secondes avec une horloge système de 16MHz et un prescaler de 1024 : T_overflow = (256 * 1024) / 16MHz ≈ 16.384 ms; 10 * 16.384 ms ≈ 0.16s. Il semble y avoir une erreur dans le calcul de 0.65s dans l'analyse initiale, ou alors `ov_count` a un autre rôle ou une autre valeur cible pour 0.65s. En se basant sur 10, c'est plus proche de 0.16s. Si l'objectif est bien ~0.65s, `ov_count` devrait atteindre environ 40.), elle effectue les actions suivantes :
            *   Change le joueur actif (passe la main à l'autre joueur).
            *   Restaure la position du curseur à un emplacement par défaut pour le nouveau joueur.
        *   Cette interruption sert donc de limite de temps par tour ou de mécanisme de temporisation pour certains aspects du jeu, notamment pendant la phase de bataille pour rythmer les tours.

### 2.5 Fonctionnement du Programme (Flux d'Exécution)

Le programme suit une structure modulaire avec un flux d'exécution principal gérant les différentes phases du jeu :

1.  **Initialisation (Routine `reset` dans `main.asm`) :**
    *   Configuration du Stack Pointer (`SP`) pour la pile.
    *   Initialisation de l'écran LCD : envoi des commandes de configuration initiales (via `lcd.asm`).
    *   Initialisation de la matrice LED WS2812B : typiquement, effacement de la matrice (via `drawing.asm`).
    *   Initialisation de l'UART0 : configuration du baud rate, format des trames (via `uart.asm`).
    *   Configuration des Data Direction Registers (DDR) pour les ports :
        *   `PORTB` configuré en sortie (pour les LEDs de la STK300).
        *   `DDRC` configuré en entrée (pour les boutons de la STK300, bien que non primordiaux pour le jeu).
    *   Configuration initiale du Timer0 : les interruptions sont activées (`TIMSK`), mais le prescaler (et donc le démarrage effectif du timer) est activé plus tard, spécifiquement avant la phase de bataille.
    *   Activation globale des interruptions (`sei` instruction).
    *   Initialisation des variables de jeu : scores, état du jeu (par exemple, la variable `battle` qui indique la phase en cours).
    *   Initialisation des grilles de jeu en mémoire SRAM externe : appel des routines `board_init` (probablement pour la grille de placement) et `battle_init_1` / `battle_init_2` (pour les grilles des joueurs J1 et J2).
    *   Affichage d'un message initial ou d'une séquence de bienvenue sur l'écran LCD (par exemple, via la routine `m_initial_sequence` de `messages.asm`).

2.  **Boucle Principale (Routine `main` dans `main.asm`) :**
    *   Vérification de l'état `game_over` : Si la partie est terminée (`game_over` est vrai), le programme saute à la section `restart`.
    *   Sélection de la phase de jeu en fonction de la variable `battle` :
        *   **Si `battle` = 0 (Phase de Placement des Bateaux) :**
            *   Appel de la routine `boat_positions` (définie dans `placement.asm`).
            *   Cette routine gère la saisie des coordonnées par l'utilisateur (via UART) pour positionner ses bateaux sur sa grille.
            *   Elle met à jour l'affichage de la matrice LED pour refléter le placement.
            *   Une fois le placement terminé pour les deux joueurs, le prescaler du Timer0 est activé pour démarrer le comptage (et donc les interruptions de changement de tour).
        *   **Si `battle` = 1 (Phase de Bataille) :**
            *   Appel de la routine `bataille` (définie dans `battle.asm`).
            *   Cette routine gère la saisie des coordonnées de tir par le joueur actif (via UART).
            *   Elle met à jour la matrice LED pour montrer les tirs, les résultats (touché, manqué, coulé).
            *   Elle gère la logique de détection des bateaux touchés et coulés.
            *   L'interruption du Timer0 (routine `overflow0`) peut intervenir pendant cette phase pour changer automatiquement de joueur si un délai est dépassé (bien que l'analyse suggère que le changement de joueur via Timer0 est conditionné par `ov_count` atteignant 10, ce qui est une courte période).

3.  **Fin de Partie (Routine `restart` dans `main.asm`) :**
    *   Affichage des messages de victoire ou de "Game Over" sur l'écran LCD.
    *   Exécution d'une animation sur la matrice LED pour signaler la fin de la partie.
    *   Pause de quelques secondes (par exemple, 2 secondes comme mentionné dans l'analyse).
    *   Saut inconditionnel (`jmp reset`) à la routine d'initialisation pour recommencer une nouvelle partie.

### 2.6 Présentation des Modules Logiciels (Fichiers .asm)

Le code source du projet est organisé en plusieurs fichiers assembleur, chacun ayant un rôle spécifique :

*   **`main.asm` :**
    *   **Rôle :** Fichier principal du programme. Il contient le point d'entrée (`reset`), la boucle principale (`main`), la routine de service d'interruption du Timer0 (`overflow0`), et la logique de fin de partie (`restart`). Il orchestre l'appel aux routines des autres modules et gère les initialisations globales.

*   **`definitions.asm` :**
    *   **Rôle :** Contient les définitions globales utilisées à travers tout le projet. Cela inclut les adresses des registres d'E/S, les adresses mémoire pour les périphériques externes (LCD, grilles en SRAM), les constantes de jeu (par exemple, taille des grilles, nombre de bateaux), et d'autres valeurs fixes.

*   **`macros.asm` :**
    *   **Rôle :** Définit des macros assembleur. Les macros sont des fragments de code réutilisables qui simplifient l'écriture de séquences d'instructions répétitives, améliorant la lisibilité et la maintenabilité du code.

*   **`lcd.asm` :**
    *   **Rôle :** Pilote (driver) pour l'écran LCD Hitachi HD44780U. Il contient les routines de bas niveau pour envoyer des commandes (par exemple, effacer l'écran, positionner le curseur) et des données (caractères à afficher) au LCD, en respectant les timings et le protocole de communication du LCD mappé en mémoire.

*   **`uart.asm` :**
    *   **Rôle :** Pilote pour le module UART0 de l'ATmega128. Il fournit les routines pour initialiser l'UART (baud rate, format de trame) et pour transmettre (`uart_transmit`) et recevoir (`uart_receive_polling` ou similaire) des octets via la communication série. Ces routines sont utilisées pour l'interaction avec le clavier via le terminal PC.

*   **`printf.asm` :**
    *   **Rôle :** Fournit des fonctionnalités de formatage de sortie, similaires à une fonction `printf` simplifiée en C. Ces routines permettent de convertir des valeurs binaires (comme des scores ou des coordonnées) en chaînes de caractères ASCII et de les afficher sur l'écran LCD en utilisant les fonctions de `lcd.asm`.

*   **`messages.asm` :**
    *   **Rôle :** Regroupe les chaînes de caractères (messages) spécifiques au jeu qui sont affichées sur l'écran LCD. Par exemple, les messages d'accueil, les instructions pour le joueur, les messages de victoire/défaite, etc. Centraliser les messages ici facilite leur gestion et leur modification.

*   **`drawing.asm` :**
    *   **Rôle :** Contient les routines graphiques pour la matrice LED WS2812B. Cela inclut l'envoi de données série aux LEDs, le dessin des grilles de fond, l'affichage des bateaux, des curseurs, des animations d'explosion, et la gestion des pointeurs vers les différentes zones de la SRAM externe où sont stockées les données des grilles.

*   **`placement.asm` :**
    *   **Rôle :** Gère la logique de la phase de placement des bateaux. Ce module contient les routines pour interagir avec le joueur (via UART et `uart.asm`) afin d'obtenir les positions et orientations des bateaux, valider ces positions, et mettre à jour la grille de placement correspondante (affichée sur la matrice LED via `drawing.asm`).

*   **`battle.asm` :**
    *   **Rôle :** Gère la logique de la phase de bataille. Ce module inclut les routines pour permettre au joueur actif de choisir des coordonnées de tir (via UART), vérifier si un bateau ennemi est touché, mettre à jour l'état des grilles des deux joueurs, gérer les bateaux coulés, et déterminer les conditions de victoire. Il interagit avec `drawing.asm` pour l'affichage sur la matrice LED.

Ce découpage modulaire permet une meilleure organisation du code, facilite le développement, le débogage et la maintenance de l'application.

### 2.7 Description de Détail de l’Accès aux Périphériques

Cette sous-section approfondit les mécanismes d'interaction avec les périphériques matériels clés du système : l'écran LCD, la matrice de LEDs WS2812B et la communication série UART0.

#### 2.7.1 Communication avec l'Écran LCD (Hitachi HD44780U)

L'écran LCD, un modèle Hitachi HD44780U de 2 lignes par 16 caractères, est interfacé avec l'ATmega128 via son interface de mémoire externe (XMEM). Cette méthode permet un accès rapide et direct à l'écran comme s'il s'agissait d'une zone mémoire.

**Configuration de l'Interface Mémoire Externe :**
Pour utiliser l'écran LCD, l'interface XMEM doit être activée et configurée. Ceci est réalisé en manipulant les bits du registre `MCUCR` (MCU Control Register) :
*   `SRE` (Bit 7 - Enable External SRAM and XMEM) : Ce bit est mis à `1` pour activer l'interface mémoire externe.
*   `SRW10` (Bit 6 - Wait state select for upper external SRAM) : Ce bit est également mis à `1`. Il introduit un état d'attente (wait state) lors des accès à la partie supérieure de la mémoire externe. Cet état d'attente est crucial pour les périphériques plus lents comme l'écran LCD, garantissant que les signaux de données et de contrôle ont suffisamment de temps pour se stabiliser, assurant ainsi une communication fiable.

**Adresses Mappées en Mémoire :**
Une fois l'interface XMEM activée, l'écran LCD est accessible via deux adresses mémoire spécifiques :
*   **Registre d'Instruction (IR) à `0x8000` :** Écrire à cette adresse envoie des commandes à l'écran LCD. Les commandes incluent des opérations telles que l'effacement de l'écran, le retour du curseur à la position initiale, le contrôle de l'affichage (curseur visible/invisible, clignotant), et le réglage du mode d'entrée.
*   **Registre de Données (DR) à `0xC000` :** Écrire à cette adresse envoie des données (caractères ASCII) à afficher sur l'écran à la position actuelle du curseur.

**Processus d'Envoi de Commandes/Données :**
Le module `lcd.asm` contient les routines logicielles qui encapsulent ces opérations.
1.  **Pour envoyer une commande :**
    *   La valeur de la commande est chargée dans un registre de travail.
    *   L'adresse du Registre d'Instruction (`0x8000`) est chargée dans les registres pointeurs X, Y ou Z.
    *   L'instruction `ST X, Rr` (ou `STS 0x8000, Rr`) est utilisée pour écrire la valeur du registre de travail à l'adresse du IR.
    *   Des délais appropriés (busy flag check ou délais fixes) sont respectés entre les commandes, comme requis par la fiche technique du HD44780U. Les routines comme `LCD_wr_ir` gèrent ces aspects.

2.  **Pour envoyer un caractère à afficher :**
    *   Le code ASCII du caractère est chargé dans un registre de travail.
    *   L'adresse du Registre de Données (`0xC000`) est chargée dans les registres pointeurs.
    *   L'instruction `ST X, Rr` (ou `STS 0xC000, Rr`) écrit le caractère.
    *   La routine `LCD_wr_dr` est typiquement utilisée pour cela, et `LCD_putc` est une fonction de plus haut niveau qui envoie un caractère.

Le bus de données physique pour cette communication est PORTA (AD0-AD7), et les lignes de contrôle nécessaires (ALE, /RD, /WR) sont gérées par l'ATmega128, typiquement via des broches sur PORTG ou PORTC, selon la configuration matérielle spécifique de la carte SK300.

#### 2.7.2 Contrôle de la Matrice de LEDs WS2812B

La matrice de LEDs RGB 8x8 est du type WS2812B, où chaque LED est adressable individuellement et contient son propre contrôleur intégré. La communication avec ces LEDs se fait via un protocole série spécifique sur une seule ligne de données.

**Ligne de Données :**
*   La broche `PD1` (Port D, bit 1) de l'ATmega128 est configurée en sortie et est utilisée comme ligne de données série pour envoyer les informations de couleur à la chaîne de LEDs. La fonction `ws2812b4_init` dans `drawing.asm` initialise `DDRD` pour configurer PD1 en sortie.

**Format des Données et Protocole de Temporisation :**
Chaque LED WS2812B nécessite 24 bits de données pour définir sa couleur : 8 bits pour le Vert (G), 8 bits pour le Rouge (R), et 8 bits pour le Bleu (B), dans cet ordre spécifique (GRB).
Le protocole est basé sur des timings très précis pour les niveaux haut et bas du signal :
*   **Bit '0' :** Un niveau haut court suivi d'un niveau bas plus long.
*   **Bit '1' :** Un niveau haut plus long suivi d'un niveau bas court.

Ces timings sont critiques et sont généralement de l'ordre de quelques centaines de nanosecondes. Dans le code (`drawing.asm`), cela est réalisé à l'aide de macros et d'un contrôle précis du port :
*   **Macros `WS2812b4_WR0` et `WS2812b4_WR1` :** Ces macros sont cruciales. Elles génèrent les séquences de timing exactes pour un bit '0' et un bit '1' respectivement. Elles utilisent des instructions `sbi` (set bit) et `cbi` (clear bit) sur le port `PD1`, entrelacées avec des instructions `nop` (no operation) pour affiner la durée des niveaux haut et bas. Le nombre de `nop` est calculé en fonction de la fréquence d'horloge du microcontrôleur (16MHz) pour respecter les spécifications de la WS2812B.

**Envoi des Données de Couleur :**
*   La fonction `ws2812b4_byte3wr` dans `drawing.asm` est responsable de l'envoi des 3 octets (24 bits) de données de couleur pour une seule LED. Elle prend typiquement les valeurs G, R, B comme paramètres (ou les lit depuis la mémoire), et pour chaque bit de chaque octet, elle appelle la macro `WS2812b4_WR0` ou `WS2812b4_WR1` appropriée.
*   L'ordre d'envoi est Vert, puis Rouge, puis Bleu.
*   Pour afficher l'état de toute la matrice (64 LEDs), cette fonction (ou une boucle l'utilisant) est appelée 64 fois, en envoyant un total de 64 * 3 = 192 octets.

**Signal de Reset :**
*   Après l'envoi de toutes les données pour la chaîne de LEDs, un signal de "Reset" est nécessaire pour que les LEDs appliquent les couleurs reçues. Ce signal consiste à maintenir la ligne de données à un niveau bas pendant une durée spécifique (généralement plus de 50 µs).
*   La fonction `ws2812b4_reset` (ou une séquence similaire) dans `drawing.asm` gère cela en mettant la ligne `PD1` à bas pendant un nombre suffisant de cycles d'horloge.

**Stockage des États des LEDs :**
Les données de couleur pour chaque LED des différentes grilles de jeu sont stockées en SRAM externe. Cela permet de conserver l'état complet de l'affichage et de le modifier facilement.
*   Grille de placement (utilisée pendant la phase de positionnement) : à partir de l'adresse `0x0400`.
*   Grille du Joueur 1 (J1) : à partir de l'adresse `0x0500`.
*   Grille du Joueur 2 (J2) : à partir de l'adresse `0x0600`.
Chaque grille occupe 8x8 = 64 pixels, et chaque pixel nécessite 3 octets pour la couleur (G, R, B), donc 192 octets par grille. Les routines `point_memory_placement`, `point_memory_player1`, et `point_memory_player2` dans `drawing.asm` sont utilisées pour initialiser les pointeurs (par exemple, les registres X, Y, Z) vers ces zones mémoire avant de lire ou d'écrire les données des LEDs.

#### 2.7.3 Gestion de la Communication Série (UART0)

La communication série UART0 est utilisée pour l'acquisition des commandes du joueur, envoyées depuis un clavier de PC via un terminal série (comme RealTerm) et un convertisseur USB-série FTDI.

**Configuration de l'UART0 :**
L'initialisation de l'UART0 est effectuée par la routine `UART0_init` dans `uart.asm`. Les paramètres de communication sont les suivants :
*   **Baud Rate :** 9600 bits par seconde. La valeur appropriée pour les registres `UBRR0H` et `UBRR0L` est calculée en fonction de la fréquence de l'horloge système (F_CPU = 16MHz) et du baud rate désiré. Pour 9600 baud et F_CPU=16MHz, UBRR = (16000000 / (16 * 9600)) - 1 = 103 (0x0067).
*   **Format de Trame :** 8 bits de données, pas de bit de parité, 1 bit de stop (communément appelé configuration "8-N-1"). Ceci est configuré dans les registres `UCSR0B` et `UCSR0C`.
    *   `UCSR0C` : `URSEL` mis à 0 pour écrire dans `UCSR0C`. `UCSZ01` et `UCSZ00` mis à 1 pour 8 bits de données (`0b00000110`). Les bits de parité (`UPM01`, `UPM00`) sont à 0 pour aucune parité. `USBS0` à 0 pour 1 bit de stop.
    *   `UCSR0B` : Les bits `RXEN0` (Receiver Enable) et `TXEN0` (Transmitter Enable) sont mis à 1 pour activer la réception et la transmission. Les interruptions UART ne sont pas utilisées pour la réception dans ce projet ; la réception est gérée par polling.

**Broches Utilisées :**
*   `PE0 (RXD0)` : Cette broche du Port E est configurée comme entrée (le bit 0 de `DDRE` est à 0). Elle reçoit les données série du câble FTDI.
*   `PE1 (TXD0)` : Cette broche du Port E est configurée comme sortie (le bit 1 de `DDRE` est à 1). Elle transmettrait des données série vers le PC, bien que cette fonctionnalité ne soit pas activement utilisée pour le retour d'information dans le jeu principal.

**Méthode de Lecture (Polling) :**
La réception des caractères se fait par une méthode de polling (scrutation) et non par interruption. Cette gestion est implémentée directement dans les routines qui nécessitent une entrée utilisateur, comme `read_uart_boat` (`placement.asm`) et `read_uart_bomb` (`battle.asm`). Le processus est le suivant :
1.  **Vérification du Flag de Réception :** Le programme boucle et vérifie continuellement le bit `RXC0` (USART Receive Complete) dans le registre `UCSR0A` (USART Control and Status Register A).
    *   Si `RXC0` est à `0`, cela signifie qu'aucun nouveau caractère n'a été reçu. Le programme continue de boucler (ou effectue d'autres tâches non bloquantes).
    *   Si `RXC0` est à `1`, un caractère complet a été reçu et est prêt à être lu depuis le buffer de réception.
2.  **Lecture de la Donnée :** Une fois que `RXC0` est détecté à `1`, le caractère reçu est lu depuis le registre de données `UDR0` (USART I/O Data Register 0). La lecture de `UDR0` a également pour effet d'effacer le flag `RXC0`.
3.  **Traitement de la Donnée :** Le caractère lu (qui est une valeur ASCII) est ensuite traité par la logique du jeu (par exemple, conversion en coordonnée, validation de la commande).

Cette méthode de polling est simple à implémenter mais peut être moins efficace qu'une gestion par interruption, car le microcontrôleur passe du temps à vérifier activement le flag. Cependant, pour une application où l'entrée utilisateur est attendue à des moments spécifiques, elle est souvent suffisante.

## 3. Références

Cette section liste les documents techniques et les outils utilisés pour le développement de l'application.

### 3.1 Fiches Techniques (Datasheets)

*   Fiche technique du microcontrôleur ATmega128
*   Fiche technique de la matrice de LED WS2812B
*   Fiche technique de l'écran LCD Hitachi HD44780U

### 3.2 Outils Logiciels et Matériels de Développement

*   **Environnement de Développement Intégré (IDE) :** Atmel Studio 7
*   **Outil de Programmation/Débogage :** AVRISP-U
*   **Logiciel Terminal Série :** RealTerm (utilisé pour l'envoi des commandes clavier via UART)
*   **Interface de Communication :** Câble FTDI (pour la liaison UART-USB)
*   **Plateforme de Développement Matérielle :** Carte de développement AVR SK300
