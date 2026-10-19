-- UCJIMS Stage 0: expanded synthetic Person B dataset
-- Adds 30 EVIDENCE rows, 44 CHAIN_OF_CUSTODY rows and 24 FORENSIC_REPORT rows (98 inserts).
-- Fixed IDs intentionally follow the tracked base and Person C integration-demo rows.
-- Dependencies: Person A schema/data; Person B schema, audit trigger and base data; Person C data and integration demo.
-- Run this file only once per fresh schema. Fixed IDs will collide if rerun.
-- Every record below is synthetic demonstration data; no real case data is included.

-- 30 EVIDENCE rows: IDs 7-36
INSERT INTO EVIDENCE VALUES (
  7, 1, 'Physical', 'Fingerprint lift collected and sealed at the entry point',
  TO_DATE('2025-06-01','YYYY-MM-DD'), 'Scene A', 1,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  8, 2, 'Digital', 'Mobile device secured for authorized forensic imaging',
  TO_DATE('2025-06-04','YYYY-MM-DD'), 'Scene B', 2,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  9, 3, 'Document', 'Signed document recovered and packaged for examination',
  TO_DATE('2025-06-07','YYYY-MM-DD'), 'Office Block', 3,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  10, 4, 'Biological', 'Biological swab sealed for laboratory analysis',
  TO_DATE('2025-06-10','YYYY-MM-DD'), 'Residence 3', 1,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  11, 5, 'Trace', 'Paint transfer sample collected from a vehicle panel',
  TO_DATE('2025-06-13','YYYY-MM-DD'), 'Roadside Scene', 2,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  12, 6, 'Digital', 'CCTV export preserved with acquisition notes',
  TO_DATE('2025-06-16','YYYY-MM-DD'), 'Shop Premises', 3,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  13, 7, 'Physical', 'Tool recovered, photographed and bagged at the scene',
  TO_DATE('2025-06-19','YYYY-MM-DD'), 'Warehouse 2', 1,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  14, 8, 'Document', 'Receipt and transaction record retained for comparison',
  TO_DATE('2025-06-22','YYYY-MM-DD'), 'Records Room', 2,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  15, 9, 'Digital', 'Laptop storage image prepared for examination',
  TO_DATE('2025-06-25','YYYY-MM-DD'), 'Digital Forensics Intake', 3,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  16, 10, 'Trace', 'Trace sample packaged for controlled storage',
  TO_DATE('2025-06-28','YYYY-MM-DD'), 'Vehicle Inspection Bay', 1,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  17, 11, 'Physical', 'Footwear impression cast collected and labelled',
  TO_DATE('2025-07-01','YYYY-MM-DD'), 'Scene A', 2,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  18, 12, 'Trace', 'Fiber sample separated from clothing and sealed',
  TO_DATE('2025-07-04','YYYY-MM-DD'), 'Scene B', 3,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  19, 13, 'Digital', 'External storage device secured for digital acquisition',
  TO_DATE('2025-07-07','YYYY-MM-DD'), 'Office Block', 1,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  20, 14, 'Document', 'Handwritten note submitted for document examination',
  TO_DATE('2025-07-10','YYYY-MM-DD'), 'Residence 3', 2,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  21, 15, 'Physical', 'Broken lock component collected as physical evidence',
  TO_DATE('2025-07-13','YYYY-MM-DD'), 'Roadside Scene', 3,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  22, 1, 'Biological', 'Biological sample sealed and labelled for testing',
  TO_DATE('2025-07-16','YYYY-MM-DD'), 'Shop Premises', 1,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  23, 2, 'Digital', 'Call-detail export received for authorized analysis',
  TO_DATE('2025-07-19','YYYY-MM-DD'), 'Warehouse 2', 2,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  24, 3, 'Physical', 'Glass fragments packaged for laboratory comparison',
  TO_DATE('2025-07-22','YYYY-MM-DD'), 'Records Room', 3,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  25, 4, 'Physical', 'Metal fragment collected and photographed',
  TO_DATE('2025-07-25','YYYY-MM-DD'), 'Digital Forensics Intake', 1,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  26, 5, 'Document', 'Printed correspondence retained as case evidence',
  TO_DATE('2025-07-28','YYYY-MM-DD'), 'Vehicle Inspection Bay', 2,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  27, 6, 'Digital', 'Memory card sealed for forensic acquisition',
  TO_DATE('2025-07-31','YYYY-MM-DD'), 'Scene A', 3,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  28, 7, 'Trace', 'Residue sample transferred to the laboratory',
  TO_DATE('2025-08-03','YYYY-MM-DD'), 'Scene B', 1,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  29, 8, 'Physical', 'Damaged door component recovered and stored',
  TO_DATE('2025-08-06','YYYY-MM-DD'), 'Office Block', 2,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  30, 9, 'Digital', 'Email archive preserved for examination',
  TO_DATE('2025-08-09','YYYY-MM-DD'), 'Residence 3', 3,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  31, 10, 'Trace', 'Soil sample collected in a sealed container',
  TO_DATE('2025-08-12','YYYY-MM-DD'), 'Roadside Scene', 1,
  'Evidence Room A', 'COLLECTED');

INSERT INTO EVIDENCE VALUES (
  32, 11, 'Document', 'Delivery record received and logged',
  TO_DATE('2025-08-15','YYYY-MM-DD'), 'Shop Premises', 2,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

INSERT INTO EVIDENCE VALUES (
  33, 12, 'Physical', 'Recovered key secured in tamper-evident packaging',
  TO_DATE('2025-08-18','YYYY-MM-DD'), 'Warehouse 2', 3,
  'Evidence Room A', 'RETURNED');

INSERT INTO EVIDENCE VALUES (
  34, 13, 'Digital', 'Network log export preserved for authorized review',
  TO_DATE('2025-08-21','YYYY-MM-DD'), 'Records Room', 1,
  NULL, 'DISPOSED');

INSERT INTO EVIDENCE VALUES (
  35, 14, 'Biological', 'Hair sample packaged for laboratory comparison',
  TO_DATE('2025-08-24','YYYY-MM-DD'), 'Digital Forensics Intake', 2,
  'Evidence Room B', 'COLLECTED');

INSERT INTO EVIDENCE VALUES (
  36, 15, 'Trace', 'Fabric fragment retained for trace comparison',
  TO_DATE('2025-08-27','YYYY-MM-DD'), 'Vehicle Inspection Bay', 3,
  'Forensic Lab 1', 'UNDER_EXAMINATION');

-- 30 initial CHAIN_OF_CUSTODY rows: IDs 7-36; each references its matching evidence ID

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  7, 7, 1, 8,
  TO_DATE('2025-06-02 08:00','YYYY-MM-DD HH24:MI'),
  'Office Block', 'Secure storage', 'Sealed', 'Seal checked and documented at handover');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  8, 8, 2, 9,
  TO_DATE('2025-06-06 09:07','YYYY-MM-DD HH24:MI'),
  'Residence 3', 'Forensic examination', 'Intact', 'Received by authorized staff member');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  9, 9, 3, 10,
  TO_DATE('2025-06-10 10:14','YYYY-MM-DD HH24:MI'),
  'Roadside Scene', 'Evidence review', 'Good', 'Item condition recorded in custody log');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  10, 10, 1, 8,
  TO_DATE('2025-06-11 11:21','YYYY-MM-DD HH24:MI'),
  'Shop Premises', 'Transfer to authorized examiner', 'Tamper-evident seal intact', 'Transfer entered for audit trail');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  11, 11, 2, 9,
  TO_DATE('2025-06-15 12:28','YYYY-MM-DD HH24:MI'),
  'Warehouse 2', 'Laboratory intake', 'Sealed', 'Package condition reviewed and noted');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  12, 12, 3, 10,
  TO_DATE('2025-06-19 13:35','YYYY-MM-DD HH24:MI'),
  'Records Room', 'Secure storage', 'Intact', 'Seal checked and documented at handover');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  13, 13, 1, 8,
  TO_DATE('2025-06-20 14:42','YYYY-MM-DD HH24:MI'),
  'Digital Forensics Intake', 'Forensic examination', 'Good', 'Received by authorized staff member');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  14, 14, 2, 9,
  TO_DATE('2025-06-24 15:49','YYYY-MM-DD HH24:MI'),
  'Vehicle Inspection Bay', 'Evidence review', 'Tamper-evident seal intact', 'Item condition recorded in custody log');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  15, 15, 3, 10,
  TO_DATE('2025-06-28 16:56','YYYY-MM-DD HH24:MI'),
  'Scene A', 'Transfer to authorized examiner', 'Sealed', 'Transfer entered for audit trail');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  16, 16, 1, 8,
  TO_DATE('2025-06-29 08:03','YYYY-MM-DD HH24:MI'),
  'Scene B', 'Laboratory intake', 'Intact', 'Package condition reviewed and noted');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  17, 17, 2, 9,
  TO_DATE('2025-07-03 09:10','YYYY-MM-DD HH24:MI'),
  'Office Block', 'Secure storage', 'Good', 'Seal checked and documented at handover');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  18, 18, 3, 10,
  TO_DATE('2025-07-07 10:17','YYYY-MM-DD HH24:MI'),
  'Residence 3', 'Forensic examination', 'Tamper-evident seal intact', 'Received by authorized staff member');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  19, 19, 1, 8,
  TO_DATE('2025-07-08 11:24','YYYY-MM-DD HH24:MI'),
  'Roadside Scene', 'Evidence review', 'Sealed', 'Item condition recorded in custody log');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  20, 20, 2, 9,
  TO_DATE('2025-07-12 12:31','YYYY-MM-DD HH24:MI'),
  'Shop Premises', 'Transfer to authorized examiner', 'Intact', 'Transfer entered for audit trail');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  21, 21, 3, 10,
  TO_DATE('2025-07-16 13:38','YYYY-MM-DD HH24:MI'),
  'Warehouse 2', 'Laboratory intake', 'Good', 'Package condition reviewed and noted');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  22, 22, 1, 8,
  TO_DATE('2025-07-17 14:45','YYYY-MM-DD HH24:MI'),
  'Records Room', 'Secure storage', 'Tamper-evident seal intact', 'Seal checked and documented at handover');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  23, 23, 2, 9,
  TO_DATE('2025-07-21 15:52','YYYY-MM-DD HH24:MI'),
  'Digital Forensics Intake', 'Forensic examination', 'Sealed', 'Received by authorized staff member');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  24, 24, 3, 10,
  TO_DATE('2025-07-25 16:59','YYYY-MM-DD HH24:MI'),
  'Vehicle Inspection Bay', 'Evidence review', 'Intact', 'Item condition recorded in custody log');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  25, 25, 1, 8,
  TO_DATE('2025-07-26 08:06','YYYY-MM-DD HH24:MI'),
  'Scene A', 'Transfer to authorized examiner', 'Good', 'Transfer entered for audit trail');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  26, 26, 2, 9,
  TO_DATE('2025-07-30 09:13','YYYY-MM-DD HH24:MI'),
  'Scene B', 'Laboratory intake', 'Tamper-evident seal intact', 'Package condition reviewed and noted');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  27, 27, 3, 10,
  TO_DATE('2025-08-03 10:20','YYYY-MM-DD HH24:MI'),
  'Office Block', 'Secure storage', 'Sealed', 'Seal checked and documented at handover');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  28, 28, 1, 8,
  TO_DATE('2025-08-04 11:27','YYYY-MM-DD HH24:MI'),
  'Residence 3', 'Forensic examination', 'Intact', 'Received by authorized staff member');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  29, 29, 2, 9,
  TO_DATE('2025-08-08 12:34','YYYY-MM-DD HH24:MI'),
  'Roadside Scene', 'Evidence review', 'Good', 'Item condition recorded in custody log');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  30, 30, 3, 10,
  TO_DATE('2025-08-12 13:41','YYYY-MM-DD HH24:MI'),
  'Shop Premises', 'Transfer to authorized examiner', 'Tamper-evident seal intact', 'Transfer entered for audit trail');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  31, 31, 1, 2,
  TO_DATE('2025-08-13 14:48','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Secure evidence storage', 'Sealed', 'Awaiting forensic examination');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  32, 32, 2, 9,
  TO_DATE('2025-08-17 15:55','YYYY-MM-DD HH24:MI'),
  'Records Room', 'Secure storage', 'Intact', 'Seal checked and documented at handover');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  33, 33, 3, 10,
  TO_DATE('2025-08-21 16:02','YYYY-MM-DD HH24:MI'),
  'Digital Forensics Intake', 'Forensic examination', 'Good', 'Received by authorized staff member');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  34, 34, 1, 8,
  TO_DATE('2025-08-22 08:09','YYYY-MM-DD HH24:MI'),
  'Vehicle Inspection Bay', 'Evidence review', 'Tamper-evident seal intact', 'Item condition recorded in custody log');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  35, 35, 2, 1,
  TO_DATE('2025-08-26 09:16','YYYY-MM-DD HH24:MI'),
  'Evidence Room B', 'Secure evidence storage', 'Sealed', 'Awaiting forensic examination');

INSERT INTO CHAIN_OF_CUSTODY VALUES (
  36, 36, 3, 10,
  TO_DATE('2025-08-30 10:23','YYYY-MM-DD HH24:MI'),
  'Scene B', 'Laboratory intake', 'Intact', 'Package condition reviewed and noted');

-- Final return/disposal chain events IDs 40-53 close the status histories for returned/disposed items.
-- 24 FORENSIC_REPORT rows: IDs 6-29 for evidence IDs 7-30

INSERT INTO FORENSIC_REPORT VALUES (
  6, 7, 8, TO_DATE('2025-06-04','YYYY-MM-DD'),
  'Initial visual examination and evidence documentation completed', 'Findings recorded; authorized review required');

INSERT INTO FORENSIC_REPORT VALUES (
  7, 8, 9, TO_DATE('2025-06-08','YYYY-MM-DD'),
  'Digital acquisition initiated and device condition recorded', 'Examination completed; observations documented');

INSERT INTO FORENSIC_REPORT VALUES (
  8, 9, 10, TO_DATE('2025-06-12','YYYY-MM-DD'),
  'Document features reviewed and comparison notes recorded', 'No definitive conclusion recorded in this synthetic example');

INSERT INTO FORENSIC_REPORT VALUES (
  9, 10, 8, TO_DATE('2025-06-16','YYYY-MM-DD'),
  'Laboratory screening completed and observations documented', 'Preliminary findings documented for review');

INSERT INTO FORENSIC_REPORT VALUES (
  10, 11, 9, TO_DATE('2025-06-20','YYYY-MM-DD'),
  'Trace comparison performed and examiner notes retained', 'Findings recorded; authorized review required');

INSERT INTO FORENSIC_REPORT VALUES (
  11, 12, 10, TO_DATE('2025-06-20','YYYY-MM-DD'),
  'Footage reviewed and relevant segment identified', 'Examination completed; observations documented');

INSERT INTO FORENSIC_REPORT VALUES (
  12, 13, 8, TO_DATE('2025-06-23','YYYY-MM-DD'),
  'Tool-mark comparison completed and observations logged', 'No definitive conclusion recorded in this synthetic example');

INSERT INTO FORENSIC_REPORT VALUES (
  13, 14, 9, TO_DATE('2025-06-27','YYYY-MM-DD'),
  'Transaction records reviewed and findings summarized', 'Preliminary findings documented for review');

INSERT INTO FORENSIC_REPORT VALUES (
  14, 15, 10, TO_DATE('2025-07-01','YYYY-MM-DD'),
  'Storage image verified and analysis notes retained', 'Findings recorded; authorized review required');

INSERT INTO FORENSIC_REPORT VALUES (
  15, 16, 8, TO_DATE('2025-07-05','YYYY-MM-DD'),
  'Laboratory comparison completed for authorized review', 'Examination completed; observations documented');

INSERT INTO FORENSIC_REPORT VALUES (
  16, 17, 9, TO_DATE('2025-07-04','YYYY-MM-DD'),
  'Impression characteristics documented for comparison', 'No definitive conclusion recorded in this synthetic example');

INSERT INTO FORENSIC_REPORT VALUES (
  17, 18, 10, TO_DATE('2025-07-08','YYYY-MM-DD'),
  'Fiber characteristics recorded and comparison initiated', 'Preliminary findings documented for review');

INSERT INTO FORENSIC_REPORT VALUES (
  18, 19, 8, TO_DATE('2025-07-12','YYYY-MM-DD'),
  'Digital media acquisition and integrity check completed', 'Findings recorded; authorized review required');

INSERT INTO FORENSIC_REPORT VALUES (
  19, 20, 9, TO_DATE('2025-07-16','YYYY-MM-DD'),
  'Handwriting features examined and documented', 'Examination completed; observations documented');

INSERT INTO FORENSIC_REPORT VALUES (
  20, 21, 10, TO_DATE('2025-07-20','YYYY-MM-DD'),
  'Surface/tool-mark observations recorded for review', 'No definitive conclusion recorded in this synthetic example');

INSERT INTO FORENSIC_REPORT VALUES (
  21, 22, 8, TO_DATE('2025-07-19','YYYY-MM-DD'),
  'Sample preparation and initial screening documented', 'Preliminary findings documented for review');

INSERT INTO FORENSIC_REPORT VALUES (
  22, 23, 9, TO_DATE('2025-07-23','YYYY-MM-DD'),
  'Digital records reviewed and relevant artefacts logged', 'Findings recorded; authorized review required');

INSERT INTO FORENSIC_REPORT VALUES (
  23, 24, 10, TO_DATE('2025-07-27','YYYY-MM-DD'),
  'Glass-fragment features documented for comparison', 'Examination completed; observations documented');

INSERT INTO FORENSIC_REPORT VALUES (
  24, 25, 8, TO_DATE('2025-07-31','YYYY-MM-DD'),
  'Material characteristics examined and recorded', 'No definitive conclusion recorded in this synthetic example');

INSERT INTO FORENSIC_REPORT VALUES (
  25, 26, 9, TO_DATE('2025-08-04','YYYY-MM-DD'),
  'Document authenticity indicators reviewed', 'Preliminary findings documented for review');

INSERT INTO FORENSIC_REPORT VALUES (
  26, 27, 10, TO_DATE('2025-08-04','YYYY-MM-DD'),
  'Memory-card acquisition completed and logged', 'Findings recorded; authorized review required');

INSERT INTO FORENSIC_REPORT VALUES (
  27, 28, 8, TO_DATE('2025-08-07','YYYY-MM-DD'),
  'Trace sample screened and observations documented', 'Examination completed; observations documented');

INSERT INTO FORENSIC_REPORT VALUES (
  28, 29, 9, TO_DATE('2025-08-11','YYYY-MM-DD'),
  'Image enhancement and review completed', 'No definitive conclusion recorded in this synthetic example');

INSERT INTO FORENSIC_REPORT VALUES (
  29, 30, 10, TO_DATE('2025-08-15','YYYY-MM-DD'),
  'Email archive integrity and metadata reviewed', 'Preliminary findings documented for review');


-- RETURN completed examinations to the original collector for items marked RETURNED.
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  40, 9, 10, 3, TO_DATE('2025-06-13 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return recorded after report 8');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  41, 13, 8, 1, TO_DATE('2025-06-24 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return recorded after report 12');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  42, 17, 9, 2, TO_DATE('2025-07-05 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return recorded after report 16');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  43, 21, 10, 3, TO_DATE('2025-07-21 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return recorded after report 20');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  44, 25, 8, 1, TO_DATE('2025-08-01 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return recorded after report 24');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  45, 29, 9, 2, TO_DATE('2025-08-12 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after forensic examination', 'Sealed', 'Synthetic return recorded after report 28');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  46, 33, 10, 3, TO_DATE('2025-08-25 10:00','YYYY-MM-DD HH24:MI'),
  'Evidence Room A', 'Return after authorized evidence review', 'Sealed', 'Synthetic return; no forensic report fixture was added for this item');

-- Record a final disposal event for each item whose current status is DISPOSED.
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  47, 10, 8, NULL, TO_DATE('2025-06-18 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic evidence disposal recorded after report 9');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  48, 14, 9, NULL, TO_DATE('2025-06-29 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic evidence disposal recorded after report 13');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  49, 18, 10, NULL, TO_DATE('2025-07-10 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic evidence disposal recorded after report 17');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  50, 22, 8, NULL, TO_DATE('2025-07-22 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic evidence disposal recorded after report 21');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  51, 26, 9, NULL, TO_DATE('2025-08-06 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic evidence disposal recorded after report 25');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  52, 30, 10, NULL, TO_DATE('2025-08-17 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic evidence disposal recorded after report 29');
INSERT INTO CHAIN_OF_CUSTODY VALUES (
  53, 34, 8, NULL, TO_DATE('2025-08-25 15:00','YYYY-MM-DD HH24:MI'),
  'Authorized Disposal Unit', 'Evidence disposal', 'Disposed', 'Synthetic disposal after authorized review');

COMMIT;

-- Expected Person B counts after all base, integration and additional data have run once:
-- EVIDENCE = 36; CHAIN_OF_CUSTODY = 54; FORENSIC_REPORT = 29.
-- EVIDENCE_AUDIT = 54 if the trigger was valid and every custody insert fired once.
-- Initial handoff status is UNDER_EXAMINATION; RETURNED items have return events;
-- DISPOSED items have a final disposal event. Every audit row is generated by the trigger.
