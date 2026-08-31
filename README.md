# ComUnity — distribuzione

Questo repository e' **pubblico e non contiene codice**: serve solo a due cose.

1. **Il sito vetrina** (`docs/`), pubblicato su <https://comunity.solutions>.
   La cartella si chiama `docs/` perche' GitHub Pages pubblica solo la radice
   del repository o quella cartella: non una qualunque.
2. **L'APK**, allegato alle Release con nome fisso `comunity.apk`.

Il codice sta altrove, in repository privati: `ComUnity_BackEnd` e
`ComUnity_Frontend`.

## Perche' un repository a parte

I repository del codice sono privati, e gli asset delle Release di un repo
privato **non sono scaricabili in anonimo**: un tester dovrebbe autenticarsi su
GitHub per prendere l'app. Un repository pubblico dedicato risolve il problema
senza esporre una riga di codice.

Il sito e il binario stanno poi in due posti diversi: l'APK pesa 66 MB e non
va versionato dentro il sito — finirebbe nella storia del repository a ogni
build, per sempre. Le Release sono fatte apposta per i binari, e il loro
`latest/download` da' il collegamento stabile che al sito serve.

## Il collegamento "sempre aggiornato"

Il pulsante del sito punta a:

```
https://github.com/gabrielepanciotti/ComUnity_Dist/releases/latest/download/comunity.apk
```

GitHub risolve `latest` sull'ultima release e `comunity.apk` e' il nome
dell'asset in ognuna. **Il sito non si tocca a ogni build**: si pubblica una
release nuova e il collegamento segue.

Per la stessa ragione il nome dell'asset non deve mai contenere la versione:
diventerebbe un collegamento rotto che nessuno vede finche' qualcuno non ci
clicca.

## Pubblicare una versione nuova

```bash
cd ../comunity/frontend
flutter build apk --release --dart-define=API_URL=https://app.comunity.solutions

cd ../../comunity-dist
bash scripts/release-apk.sh 1.0.1
```

Lo script **rifiuta** un APK firmato con la chiave di debug. Senza
`android/key.properties` la build Flutter non fallisce: ripiega sulla chiave di
debug e stampa solo un warning. Quell'APK si installa, ma ha una firma diversa
dalle release precedenti, e chi ha gia' l'app non riesce ad aggiornarla — deve
disinstallare, perdendo la sessione.

## Chi puo' entrare

Chiunque puo' scaricare e installare. Per **creare l'account** serve un codice
di invito monouso, che i soci generano dal bot Telegram (`/invita`). Il
controllo sta li', non sul download: un file si inoltra su WhatsApp in dieci
secondi, e l'API e' comunque pubblica.
