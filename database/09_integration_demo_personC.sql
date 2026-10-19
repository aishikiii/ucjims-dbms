-- UCJIMS - Integration demo data (shared connected cases)
-- Synthetic demonstration records only.

-- EVIDENCE
INSERT INTO EVIDENCE VALUES
(4, 4, 'Physical', 'Tools recovered from the burglary scene',
 TO_DATE('2024-05-12','YYYY-MM-DD'),
 'Residential premises, MG Road', 1, 'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES
(5, 4, 'Digital', 'CCTV footage from a neighbouring shop',
 TO_DATE('2024-05-13','YYYY-MM-DD'),
 'MG Road', 14, 'Digital Evidence Vault', 'RETURNED');

INSERT INTO EVIDENCE VALUES
(6, 14, 'Physical', 'Sample of seized narcotic substance',
 TO_DATE('2024-03-11','YYYY-MM-DD'),
 'Whitefield, Chennai', 1, NULL, 'DISPOSED');

-- CHAIN OF CUSTODY
INSERT INTO CHAIN_OF_CUSTODY VALUES
(4, 4, 1, 8, TO_DATE('2024-05-14 14:00','YYYY-MM-DD HH24:MI'),
 'Forensic Lab 1', 'Forensic examination', 'Sealed',
 'Handed to forensic officer for tool-mark and print analysis');

INSERT INTO CHAIN_OF_CUSTODY VALUES
(5, 5, 14, 8, TO_DATE('2024-05-15 10:30','YYYY-MM-DD HH24:MI'),
 'Forensic Lab 1', 'Footage enhancement', 'Intact',
 'Digital copy and original storage device handed over');

INSERT INTO CHAIN_OF_CUSTODY VALUES
(6, 6, 1, 9, TO_DATE('2024-03-12 11:00','YYYY-MM-DD HH24:MI'),
 'Forensic Lab 1', 'Chemical analysis', 'Sealed',
 'Sample transferred for lab testing');

-- FORENSIC REPORT
INSERT INTO FORENSIC_REPORT VALUES
(3, 4, 8, TO_DATE('2024-05-16','YYYY-MM-DD'),
 'Tool-mark and fingerprint analysis', 'Synthetic finding recorded for demonstration');

INSERT INTO FORENSIC_REPORT VALUES
(4, 5, 8, TO_DATE('2024-05-20','YYYY-MM-DD'),
 'CCTV footage enhancement and review', 'Synthetic identification observation recorded');

INSERT INTO FORENSIC_REPORT VALUES
(5, 6, 9, TO_DATE('2024-03-15','YYYY-MM-DD'),
 'Chemical analysis of seized sample', 'Synthetic laboratory result recorded');


-- Terminal events: returned items are handed back to their collecting unit; the disposed sample
-- is recorded as disposed rather than leaving an unexplained terminal status.
INSERT INTO CHAIN_OF_CUSTODY VALUES
(37, 4, 8, 1, TO_DATE('2024-05-21 10:00','YYYY-MM-DD HH24:MI'),
 'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return transfer after report 3');

INSERT INTO CHAIN_OF_CUSTODY VALUES
(38, 5, 8, 14, TO_DATE('2024-05-22 10:00','YYYY-MM-DD HH24:MI'),
 'Digital Evidence Vault', 'Return after forensic examination', 'Intact', 'Synthetic return transfer after report 4');

INSERT INTO CHAIN_OF_CUSTODY VALUES
(39, 6, 9, NULL, TO_DATE('2024-03-16 12:00','YYYY-MM-DD HH24:MI'),
 'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic disposal event after forensic analysis');

COMMIT;

-- Integration check: cases with evidence and a judgment
SELECT c.case_id, c.case_number, COUNT(DISTINCT e.evidence_id) AS evidence_items,
       COUNT(DISTINCT fr.report_id) AS forensic_reports, MAX(j.verdict) AS verdict
FROM CASE_TABLE c
JOIN EVIDENCE e              ON e.case_id = c.case_id
LEFT JOIN FORENSIC_REPORT fr ON fr.evidence_id = e.evidence_id
LEFT JOIN JUDGMENT j         ON j.case_id = c.case_id
GROUP BY c.case_id, c.case_number
ORDER BY c.case_id;
