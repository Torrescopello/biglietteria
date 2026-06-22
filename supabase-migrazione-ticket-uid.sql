-- ============================================================
-- Migrazione: identificativo univoco per ticket (ticket_uid)
-- ============================================================
-- Scopo: dare a ogni vendita un ID univoco e stabile, indipendente dal
-- numero ticket (che e' ciclico 1-100 e si ripete piu' volte al giorno).
-- Serve a:
--   1. impedire DEFINITIVAMENTE i doppioni in scrittura (idempotenza);
--   2. evitare collisioni negli ingressi tra due ticket con lo stesso numero
--      dopo il giro del rotolo (giornate con oltre 100 biglietti).
--
-- E' SICURA e RETROCOMPATIBILE:
--   - la colonna e' nullable: le righe vecchie restano valide (uid = NULL);
--   - il codice funziona sia prima sia dopo questa migrazione.
-- Consiglio: eseguila in un momento tranquillo, poi aggiorna l'app.
-- ============================================================

-- 1) Aggiunge la colonna (se non esiste gia')
alter table public.vendite
  add column if not exists ticket_uid text;

-- 2) Indice unico (parziale) su (ticket_uid, tipo): blocca a livello di DB
--    un secondo inserimento della stessa riga di una vendita. Riguarda solo
--    le righe con uid valorizzato, quindi non tocca i dati storici (uid NULL).
--    Una vendita ha una sola riga per tipo, quindi (uid, tipo) e' univoco.
create unique index if not exists vendite_uid_tipo_uniq
  on public.vendite (ticket_uid, tipo)
  where ticket_uid is not null;

-- Fatto. Da ora ogni nuova vendita salva il suo ticket_uid e i doppioni
-- diventano impossibili sia lato app sia lato database.
