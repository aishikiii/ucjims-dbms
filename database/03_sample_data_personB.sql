-- PERSON B: BASE SYNTHETIC SAMPLE DATA
-- Forensic reports are assigned to seeded Forensic Officer user 8.
-- Custody rows explicitly transfer to the forensic workflow where appropriate.

-- EVIDENCE
INSERT INTO EVIDENCE VALUES
(1, 1, 'Physical', 'Fingerprint collected from the scene',
 TO_DATE('2026-09-01','YYYY-MM-DD'), 'Crime Scene A', 1, 'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES
(2, 1, 'Digital', 'Mobile phone recovered from the scene',
 TO_DATE('2026-09-02','YYYY-MM-DD'), 'Crime Scene A', 1, 'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES
(3, 2, 'Document', 'Document recovered during investigation',
 TO_DATE('2026-09-03','YYYY-MM-DD'), 'Office Room B', 2, 'Forensic Lab 1', 'UNDER_EXAMINATION');

-- CHAIN OF CUSTODY
INSERT INTO CHAIN_OF_CUSTODY VALUES
(1, 1, 1, 2, TO_DATE('2026-09-01 12:00','YYYY-MM-DD HH24:MI'),
 'Evidence Room A', 'Evidence handover', 'Sealed', 'Transferred for safe storage');

INSERT INTO CHAIN_OF_CUSTODY VALUES
(2, 2, 1, 8, TO_DATE('2026-09-02 14:00','YYYY-MM-DD HH24:MI'),
 'Forensic Lab 1', 'Forensic examination', 'Sealed', 'Transferred to forensic officer');

INSERT INTO CHAIN_OF_CUSTODY VALUES
(3, 3, 2, 8, TO_DATE('2026-09-03 16:00','YYYY-MM-DD HH24:MI'),
 'Evidence Room B', 'Forensic intake and secure storage', 'Good', 'Evidence handed over securely');

-- Evidence 1 moved from secure intake to the forensic officer before its report.
INSERT INTO CHAIN_OF_CUSTODY VALUES
(54, 1, 2, 8, TO_DATE('2026-09-02 15:00','YYYY-MM-DD HH24:MI'),
 'Forensic Lab 1', 'Forensic examination', 'Sealed', 'Synthetic handoff before fingerprint report');

-- FORENSIC REPORT
INSERT INTO FORENSIC_REPORT VALUES
(1, 1, 8, TO_DATE('2026-09-04','YYYY-MM-DD'),
 'Fingerprint comparison performed', 'Comparison completed');

INSERT INTO FORENSIC_REPORT VALUES
(2, 2, 8, TO_DATE('2026-09-05','YYYY-MM-DD'),
 'Mobile phone examination started', 'Examination in progress');

COMMIT;
