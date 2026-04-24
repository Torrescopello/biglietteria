-- ============================================================
-- MIGRATION: Counter biglietti atomico per multi-device
-- Da eseguire UNA SOLA VOLTA nel SQL Editor di Supabase
-- ============================================================

-- Tabella contatori giornalieri
CREATE TABLE IF NOT EXISTS ticket_counters (
  data   date    PRIMARY KEY,
  valore integer NOT NULL DEFAULT 0
);

-- Funzione atomica: incrementa e restituisce il prossimo numero
-- Usa INSERT ... ON CONFLICT DO UPDATE (upsert atomico, thread-safe)
CREATE OR REPLACE FUNCTION get_next_ticket_num(p_data date)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_next integer;
BEGIN
  INSERT INTO ticket_counters (data, valore)
    VALUES (p_data, 1)
  ON CONFLICT (data) DO UPDATE
    SET valore = ticket_counters.valore + 1
  RETURNING valore INTO v_next;
  RETURN v_next;
END;
$$;

-- Permessi: la funzione deve essere chiamabile dall'app (anon key)
GRANT EXECUTE ON FUNCTION get_next_ticket_num(date) TO anon, authenticated;
GRANT ALL ON TABLE ticket_counters TO anon, authenticated;

-- Row Level Security (opzionale ma consigliato)
ALTER TABLE ticket_counters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lettura libera ticket_counters"  ON ticket_counters FOR SELECT USING (true);
CREATE POLICY "Modifica libera ticket_counters" ON ticket_counters FOR ALL    USING (true);

-- ============================================================
-- Tabella rimborsi giornalieri (payload JSON serializzato)
-- ============================================================
CREATE TABLE IF NOT EXISTS rimborsi_giornata (
  data    date PRIMARY KEY,
  payload text NOT NULL
);

GRANT ALL ON TABLE rimborsi_giornata TO anon, authenticated;
ALTER TABLE rimborsi_giornata ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rw_rimborsi" ON rimborsi_giornata FOR ALL USING (true);
