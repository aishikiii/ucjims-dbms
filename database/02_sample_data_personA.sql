-- ROLE
INSERT INTO ROLE VALUES (1, 'Investigator', 'Handles case investigation and evidence collection');
INSERT INTO ROLE VALUES (2, 'Judge', 'Presides over court hearings and delivers judgments');
INSERT INTO ROLE VALUES (3, 'Prosecutor', 'Represents the state in criminal proceedings');
INSERT INTO ROLE VALUES (4, 'Forensic Officer', 'Conducts forensic examination of evidence');
INSERT INTO ROLE VALUES (5, 'Prison Officer', 'Manages inmate records and prison operations');
INSERT INTO ROLE VALUES (6, 'Admin', 'System administration and user management');
INSERT INTO ROLE VALUES (7, 'Cyber Crime Analyst', 'Investigates digital and cyber-based offences');

-- DEPARTMENT
INSERT INTO DEPARTMENT VALUES (1, 'Police', 'City Police Headquarters');
INSERT INTO DEPARTMENT VALUES (2, 'Court', 'District Court Complex');
INSERT INTO DEPARTMENT VALUES (3, 'Forensics', 'Forensic Science Laboratory');
INSERT INTO DEPARTMENT VALUES (4, 'Prison', 'Central Prison Facility');
INSERT INTO DEPARTMENT VALUES (5, 'Cyber Crime Cell', 'Cyber Crime Investigation Unit');

-- APP_USER
INSERT INTO APP_USER VALUES (1, 1, 1, 'Rani Patil', 'ranipati1', 'hash_pw_001', 'ranipati1@ucjims.gov', '9820010001', 'ACTIVE');
INSERT INTO APP_USER VALUES (2, 1, 1, 'Rahul Yadav', 'rahulyad2', 'hash_pw_002', 'rahulyad2@ucjims.gov', '9820010002', 'ACTIVE');
INSERT INTO APP_USER VALUES (3, 1, 1, 'Neha Reddy', 'neharedd3', 'hash_pw_003', 'neharedd3@ucjims.gov', '9820010003', 'ACTIVE');
INSERT INTO APP_USER VALUES (4, 2, 2, 'Amit Singh', 'amitsing4', 'hash_pw_004', 'amitsing4@ucjims.gov', '9820010004', 'ACTIVE');
INSERT INTO APP_USER VALUES (5, 2, 2, 'Vidya Patil', 'vidyapat5', 'hash_pw_005', 'vidyapat5@ucjims.gov', '9820010005', 'ACTIVE');
INSERT INTO APP_USER VALUES (6, 3, 2, 'Dinesh Yadav', 'dineshya6', 'hash_pw_006', 'dineshya6@ucjims.gov', '9820010006', 'ACTIVE');
INSERT INTO APP_USER VALUES (7, 3, 2, 'Suman Rao', 'sumanrao7', 'hash_pw_007', 'sumanrao7@ucjims.gov', '9820010007', 'ACTIVE');
INSERT INTO APP_USER VALUES (8, 4, 3, 'Vikram Pillai', 'vikrampi8', 'hash_pw_008', 'vikrampi8@ucjims.gov', '9820010008', 'ACTIVE');
INSERT INTO APP_USER VALUES (9, 4, 3, 'Nisha Nair', 'nishanai9', 'hash_pw_009', 'nishanai9@ucjims.gov', '9820010009', 'ACTIVE');
INSERT INTO APP_USER VALUES (10, 4, 3, 'Rahul Mehta', 'rahulmeh10', 'hash_pw_010', 'rahulmeh10@ucjims.gov', '9820010010', 'ACTIVE');
INSERT INTO APP_USER VALUES (11, 5, 4, 'Lakshmi Reddy', 'lakshmir11', 'hash_pw_011', 'lakshmir11@ucjims.gov', '9820010011', 'ACTIVE');
INSERT INTO APP_USER VALUES (12, 5, 4, 'Sandeep Bhatt', 'sandeepb12', 'hash_pw_012', 'sandeepb12@ucjims.gov', '9820010012', 'ACTIVE');
INSERT INTO APP_USER VALUES (13, 6, 1, 'Priya Rao', 'priyarao13', 'hash_pw_013', 'priyarao13@ucjims.gov', '9820010013', 'ACTIVE');
INSERT INTO APP_USER VALUES (14, 7, 5, 'Sanjay Chauhan', 'sanjaych14', 'hash_pw_014', 'sanjaych14@ucjims.gov', '9820010014', 'ACTIVE');
INSERT INTO APP_USER VALUES (15, 7, 5, 'Rani Chauhan', 'ranichau15', 'hash_pw_015', 'ranichau15@ucjims.gov', '9820010015', 'ACTIVE');

-- PERSON
INSERT INTO PERSON VALUES (1, 'Sarita Menon', TO_DATE('1979-08-19','YYYY-MM-DD'), 'Female', '9900020001', 'Bangalore', 'ID2001');
INSERT INTO PERSON VALUES (2, 'Kunal Saxena', TO_DATE('1965-03-23','YYYY-MM-DD'), 'Male', '9900020002', 'Hyderabad', 'ID2002');
INSERT INTO PERSON VALUES (3, 'Shalini Tiwari', TO_DATE('1974-04-25','YYYY-MM-DD'), 'Female', '9900020003', 'Mumbai', 'ID2003');
INSERT INTO PERSON VALUES (4, 'Karan Mehta', TO_DATE('1989-02-12','YYYY-MM-DD'), 'Male', '9900020004', 'Mumbai', 'ID2004');
INSERT INTO PERSON VALUES (5, 'Geeta Tiwari', TO_DATE('1967-12-15','YYYY-MM-DD'), 'Female', '9900020005', 'Jaipur', 'ID2005');
INSERT INTO PERSON VALUES (6, 'Karan Kulkarni', TO_DATE('1989-02-18','YYYY-MM-DD'), 'Male', '9900020006', 'Bangalore', 'ID2006');
INSERT INTO PERSON VALUES (7, 'Jyoti Kapoor', TO_DATE('1988-10-07','YYYY-MM-DD'), 'Female', '9900020007', 'Pune', 'ID2007');
INSERT INTO PERSON VALUES (8, 'Arjun Joshi', TO_DATE('1979-05-03','YYYY-MM-DD'), 'Male', '9900020008', 'Kolkata', 'ID2008');
INSERT INTO PERSON VALUES (9, 'Mamta Patil', TO_DATE('1989-05-15','YYYY-MM-DD'), 'Female', '9900020009', 'Mumbai', 'ID2009');
INSERT INTO PERSON VALUES (10, 'Rajesh Kumari', TO_DATE('1987-04-22','YYYY-MM-DD'), 'Male', '9900020010', 'Bangalore', 'ID2010');
INSERT INTO PERSON VALUES (11, 'Usha Kulkarni', TO_DATE('1969-10-21','YYYY-MM-DD'), 'Female', '9900020011', 'Chandigarh', 'ID2011');
INSERT INTO PERSON VALUES (12, 'Gaurav Yadav', TO_DATE('1980-03-15','YYYY-MM-DD'), 'Male', '9900020012', 'Hyderabad', 'ID2012');
INSERT INTO PERSON VALUES (13, 'Neha Kulkarni', TO_DATE('2000-04-22','YYYY-MM-DD'), 'Female', '9900020013', 'Mumbai', 'ID2013');
INSERT INTO PERSON VALUES (14, 'Aditya Mishra', TO_DATE('1968-04-27','YYYY-MM-DD'), 'Male', '9900020014', 'Delhi', 'ID2014');
INSERT INTO PERSON VALUES (15, 'Asha Khanna', TO_DATE('1990-05-03','YYYY-MM-DD'), 'Female', '9900020015', 'Kolkata', 'ID2015');
INSERT INTO PERSON VALUES (16, 'Harish Pillai', TO_DATE('1985-04-21','YYYY-MM-DD'), 'Male', '9900020016', 'Chennai', 'ID2016');
INSERT INTO PERSON VALUES (17, 'Swati Trivedi', TO_DATE('1994-03-09','YYYY-MM-DD'), 'Female', '9900020017', 'Chandigarh', 'ID2017');
INSERT INTO PERSON VALUES (18, 'Amit Yadav', TO_DATE('2000-09-09','YYYY-MM-DD'), 'Male', '9900020018', 'Lucknow', 'ID2018');
INSERT INTO PERSON VALUES (19, 'Nisha Trivedi', TO_DATE('2002-07-12','YYYY-MM-DD'), 'Female', '9900020019', 'Kolkata', 'ID2019');
INSERT INTO PERSON VALUES (20, 'Manoj Bose', TO_DATE('1996-02-25','YYYY-MM-DD'), 'Male', '9900020020', 'Delhi', 'ID2020');
INSERT INTO PERSON VALUES (21, 'Mamta Patil', TO_DATE('1974-11-06','YYYY-MM-DD'), 'Female', '9900020021', 'Hyderabad', 'ID2021');
INSERT INTO PERSON VALUES (22, 'Prakash Mehta', TO_DATE('1989-07-20','YYYY-MM-DD'), 'Male', '9900020022', 'Chennai', 'ID2022');
INSERT INTO PERSON VALUES (23, 'Kiran Tiwari', TO_DATE('2000-01-22','YYYY-MM-DD'), 'Female', '9900020023', 'Pune', 'ID2023');
INSERT INTO PERSON VALUES (24, 'Dinesh Trivedi', TO_DATE('1999-05-25','YYYY-MM-DD'), 'Male', '9900020024', 'Mumbai', 'ID2024');
INSERT INTO PERSON VALUES (25, 'Divya Iyer', TO_DATE('1992-03-15','YYYY-MM-DD'), 'Female', '9900020025', 'Delhi', 'ID2025');
INSERT INTO PERSON VALUES (26, 'Ashok Trivedi', TO_DATE('1981-09-25','YYYY-MM-DD'), 'Male', '9900020026', 'Chandigarh', 'ID2026');
INSERT INTO PERSON VALUES (27, 'Kiran Kulkarni', TO_DATE('1971-11-10','YYYY-MM-DD'), 'Female', '9900020027', 'Jaipur', 'ID2027');
INSERT INTO PERSON VALUES (28, 'Prakash Malhotra', TO_DATE('1974-06-25','YYYY-MM-DD'), 'Male', '9900020028', 'Chandigarh', 'ID2028');
INSERT INTO PERSON VALUES (29, 'Sarita Mishra', TO_DATE('1998-01-20','YYYY-MM-DD'), 'Female', '9900020029', 'Mumbai', 'ID2029');
INSERT INTO PERSON VALUES (30, 'Naveen Sharma', TO_DATE('1972-06-27','YYYY-MM-DD'), 'Male', '9900020030', 'Bangalore', 'ID2030');
INSERT INTO PERSON VALUES (31, 'Kavita Nair', TO_DATE('1980-10-03','YYYY-MM-DD'), 'Female', '9900020031', 'Pune', 'ID2031');
INSERT INTO PERSON VALUES (32, 'Ashok Chopra', TO_DATE('1969-09-25','YYYY-MM-DD'), 'Male', '9900020032', 'Chandigarh', 'ID2032');
INSERT INTO PERSON VALUES (33, 'Pooja Joshi', TO_DATE('1995-09-06','YYYY-MM-DD'), 'Female', '9900020033', 'Bangalore', 'ID2033');
INSERT INTO PERSON VALUES (34, 'Sandeep Saxena', TO_DATE('1992-04-18','YYYY-MM-DD'), 'Male', '9900020034', 'Kolkata', 'ID2034');
INSERT INTO PERSON VALUES (35, 'Usha Iyer', TO_DATE('1990-11-21','YYYY-MM-DD'), 'Female', '9900020035', 'Mumbai', 'ID2035');
INSERT INTO PERSON VALUES (36, 'Vivek Trivedi', TO_DATE('1998-08-04','YYYY-MM-DD'), 'Male', '9900020036', 'Kolkata', 'ID2036');
INSERT INTO PERSON VALUES (37, 'Kavita Mehta', TO_DATE('1986-01-19','YYYY-MM-DD'), 'Female', '9900020037', 'Jaipur', 'ID2037');
INSERT INTO PERSON VALUES (38, 'Amit Pillai', TO_DATE('1979-01-03','YYYY-MM-DD'), 'Male', '9900020038', 'Delhi', 'ID2038');
INSERT INTO PERSON VALUES (39, 'Kavita Mehta', TO_DATE('1967-06-03','YYYY-MM-DD'), 'Female', '9900020039', 'Jaipur', 'ID2039');
INSERT INTO PERSON VALUES (40, 'Amit Tiwari', TO_DATE('1996-04-18','YYYY-MM-DD'), 'Male', '9900020040', 'Chandigarh', 'ID2040');

-- CASE_TABLE
INSERT INTO CASE_TABLE VALUES (1, 'C2024001', 'Theft', TO_DATE('2024-02-24','YYYY-MM-DD'), TO_DATE('2024-02-19','YYYY-MM-DD'), 'Salt Lake, Lucknow', 'Theft of valuables reported by the complainant', 'UNDER_INVESTIGATION', 'MEDIUM');
INSERT INTO CASE_TABLE VALUES (2, 'C2024002', 'Assault', TO_DATE('2024-03-08','YYYY-MM-DD'), TO_DATE('2024-03-04','YYYY-MM-DD'), 'Sector 17, Hyderabad', 'Physical assault following a dispute', 'CHARGESHEETED', 'HIGH');
INSERT INTO CASE_TABLE VALUES (3, 'C2024003', 'Fraud', TO_DATE('2024-04-04','YYYY-MM-DD'), TO_DATE('2024-04-03','YYYY-MM-DD'), 'Banjara Hills, Hyderabad', 'Financial fraud involving forged documents', 'UNDER_TRIAL', 'LOW');
INSERT INTO CASE_TABLE VALUES (4, 'C2024004', 'Burglary', TO_DATE('2024-05-14','YYYY-MM-DD'), TO_DATE('2024-05-10','YYYY-MM-DD'), 'MG Road, Chennai', 'Burglary of residential or commercial premises', 'CLOSED', 'MEDIUM');
INSERT INTO CASE_TABLE VALUES (5, 'C2024005', 'Cybercrime', TO_DATE('2024-06-22','YYYY-MM-DD'), TO_DATE('2024-06-21','YYYY-MM-DD'), 'Marine Lines, Delhi', 'Online financial scam targeting the victim', 'OPEN', 'HIGH');
INSERT INTO CASE_TABLE VALUES (6, 'C2024006', 'Homicide', TO_DATE('2024-07-24','YYYY-MM-DD'), TO_DATE('2024-07-21','YYYY-MM-DD'), 'Sector 17, Pune', 'Unlawful killing under investigation', 'UNDER_INVESTIGATION', 'LOW');
INSERT INTO CASE_TABLE VALUES (7, 'C2024007', 'Kidnapping', TO_DATE('2024-08-07','YYYY-MM-DD'), TO_DATE('2024-08-05','YYYY-MM-DD'), 'Salt Lake, Jaipur', 'Abduction reported by family members', 'CHARGESHEETED', 'MEDIUM');
INSERT INTO CASE_TABLE VALUES (8, 'C2024008', 'Robbery', TO_DATE('2024-09-05','YYYY-MM-DD'), TO_DATE('2024-09-01','YYYY-MM-DD'), 'Whitefield, Chandigarh', 'Armed robbery at a public location', 'UNDER_TRIAL', 'HIGH');
INSERT INTO CASE_TABLE VALUES (9, 'C2024009', 'Extortion', TO_DATE('2024-10-15','YYYY-MM-DD'), TO_DATE('2024-10-13','YYYY-MM-DD'), 'Salt Lake, Pune', 'Threats made to extort money from the victim', 'CLOSED', 'LOW');
INSERT INTO CASE_TABLE VALUES (10, 'C2024010', 'Domestic Violence', TO_DATE('2024-11-18','YYYY-MM-DD'), TO_DATE('2024-11-17','YYYY-MM-DD'), 'MG Road, Delhi', 'Domestic abuse reported by a family member', 'OPEN', 'MEDIUM');
INSERT INTO CASE_TABLE VALUES (11, 'C2024011', 'Smuggling', TO_DATE('2024-12-03','YYYY-MM-DD'), TO_DATE('2024-12-01','YYYY-MM-DD'), 'Marine Lines, Chandigarh', 'Smuggling of contraband goods', 'UNDER_INVESTIGATION', 'HIGH');
INSERT INTO CASE_TABLE VALUES (12, 'C2024012', 'Forgery', TO_DATE('2024-01-16','YYYY-MM-DD'), TO_DATE('2024-01-12','YYYY-MM-DD'), 'Marine Lines, Kolkata', 'Forgery of official documents', 'CHARGESHEETED', 'LOW');
INSERT INTO CASE_TABLE VALUES (13, 'C2024013', 'Arson', TO_DATE('2024-02-02','YYYY-MM-DD'), TO_DATE('2024-02-01','YYYY-MM-DD'), 'MG Road, Hyderabad', 'Deliberate fire set to property', 'UNDER_TRIAL', 'MEDIUM');
INSERT INTO CASE_TABLE VALUES (14, 'C2024014', 'Drug Trafficking', TO_DATE('2024-03-13','YYYY-MM-DD'), TO_DATE('2024-03-10','YYYY-MM-DD'), 'Whitefield, Chennai', 'Trafficking of illegal narcotics', 'CLOSED', 'HIGH');
INSERT INTO CASE_TABLE VALUES (15, 'C2024015', 'Vandalism', TO_DATE('2024-04-14','YYYY-MM-DD'), TO_DATE('2024-04-09','YYYY-MM-DD'), 'Connaught Place, Chennai', 'Deliberate destruction of public/private property', 'OPEN', 'LOW');

-- FIR
INSERT INTO FIR VALUES (1, 1, 2, 19, 'FIR2024/001', TO_DATE('2024-02-24','YYYY-MM-DD'), 'Whitefield PS', 'Complainant reported the theft incident');
INSERT INTO FIR VALUES (2, 2, 1, 38, 'FIR2024/002', TO_DATE('2024-03-08','YYYY-MM-DD'), 'Central PS', 'Complainant reported the assault incident');
INSERT INTO FIR VALUES (3, 3, 3, 4, 'FIR2024/003', TO_DATE('2024-04-04','YYYY-MM-DD'), 'Central PS', 'Complainant reported the fraud incident');
INSERT INTO FIR VALUES (4, 4, 15, 31, 'FIR2024/004', TO_DATE('2024-05-14','YYYY-MM-DD'), 'Sector 17 PS', 'Complainant reported the burglary incident');
INSERT INTO FIR VALUES (5, 5, 1, 33, 'FIR2024/005', TO_DATE('2024-06-22','YYYY-MM-DD'), 'MG Road PS', 'Complainant reported the cybercrime incident');
INSERT INTO FIR VALUES (6, 6, 2, 5, 'FIR2024/006', TO_DATE('2024-07-24','YYYY-MM-DD'), 'MG Road PS', 'Complainant reported the homicide incident');
INSERT INTO FIR VALUES (7, 7, 2, 26, 'FIR2024/007', TO_DATE('2024-08-07','YYYY-MM-DD'), 'MG Road PS', 'Complainant reported the kidnapping incident');
INSERT INTO FIR VALUES (8, 8, 15, 16, 'FIR2024/008', TO_DATE('2024-09-05','YYYY-MM-DD'), 'Central PS', 'Complainant reported the robbery incident');
INSERT INTO FIR VALUES (9, 9, 15, 6, 'FIR2024/009', TO_DATE('2024-10-15','YYYY-MM-DD'), 'Banjara Hills PS', 'Complainant reported the extortion incident');
INSERT INTO FIR VALUES (10, 10, 15, 37, 'FIR2024/010', TO_DATE('2024-11-18','YYYY-MM-DD'), 'Connaught Place PS', 'Complainant reported the domestic violence incident');
INSERT INTO FIR VALUES (11, 11, 3, 14, 'FIR2024/011', TO_DATE('2024-12-03','YYYY-MM-DD'), 'Connaught Place PS', 'Complainant reported the smuggling incident');
INSERT INTO FIR VALUES (12, 12, 2, 17, 'FIR2024/012', TO_DATE('2024-01-16','YYYY-MM-DD'), 'Banjara Hills PS', 'Complainant reported the forgery incident');
INSERT INTO FIR VALUES (13, 13, 2, 20, 'FIR2024/013', TO_DATE('2024-02-02','YYYY-MM-DD'), 'Salt Lake PS', 'Complainant reported the arson incident');
INSERT INTO FIR VALUES (14, 14, 3, 5, 'FIR2024/014', TO_DATE('2024-03-13','YYYY-MM-DD'), 'Central PS', 'Complainant reported the drug trafficking incident');
INSERT INTO FIR VALUES (15, 15, 14, 40, 'FIR2024/015', TO_DATE('2024-04-14','YYYY-MM-DD'), 'MG Road PS', 'Complainant reported the vandalism incident');

-- CASE_PERSON
INSERT INTO CASE_PERSON VALUES (1, 1, 35, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (2, 1, 14, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (3, 2, 17, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (4, 2, 9, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (5, 2, 23, 'WITNESS', 'Provided statement relevant to the investigation');
INSERT INTO CASE_PERSON VALUES (6, 2, 5, 'COMPLAINANT', 'Registered the initial complaint');
INSERT INTO CASE_PERSON VALUES (7, 3, 11, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (8, 3, 29, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (9, 3, 35, 'OFFICIAL', 'Assisting the investigation in an official capacity');
INSERT INTO CASE_PERSON VALUES (10, 4, 40, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (11, 4, 34, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (12, 4, 1, 'OFFICIAL', 'Assisting the investigation in an official capacity');
INSERT INTO CASE_PERSON VALUES (13, 5, 20, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (14, 5, 7, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (15, 5, 9, 'WITNESS', 'Provided statement relevant to the investigation');
INSERT INTO CASE_PERSON VALUES (16, 5, 17, 'WITNESS', 'Provided statement relevant to the investigation');
INSERT INTO CASE_PERSON VALUES (17, 6, 36, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (18, 6, 10, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (19, 6, 18, 'OFFICIAL', 'Assisting the investigation in an official capacity');
INSERT INTO CASE_PERSON VALUES (20, 6, 19, 'WITNESS', 'Provided statement relevant to the investigation');
INSERT INTO CASE_PERSON VALUES (21, 7, 22, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (22, 7, 14, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (23, 7, 17, 'COMPLAINANT', 'Registered the initial complaint');
INSERT INTO CASE_PERSON VALUES (24, 7, 33, 'COMPLAINANT', 'Registered the initial complaint');
INSERT INTO CASE_PERSON VALUES (25, 8, 6, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (26, 8, 28, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (27, 9, 3, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (28, 9, 1, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (29, 9, 22, 'WITNESS', 'Provided statement relevant to the investigation');
INSERT INTO CASE_PERSON VALUES (30, 10, 17, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (31, 10, 11, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (32, 10, 29, 'OFFICIAL', 'Assisting the investigation in an official capacity');
INSERT INTO CASE_PERSON VALUES (33, 10, 36, 'COMPLAINANT', 'Registered the initial complaint');
INSERT INTO CASE_PERSON VALUES (34, 11, 1, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (35, 11, 8, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (36, 11, 5, 'OFFICIAL', 'Assisting the investigation in an official capacity');
INSERT INTO CASE_PERSON VALUES (37, 11, 10, 'WITNESS', 'Provided statement relevant to the investigation');
INSERT INTO CASE_PERSON VALUES (38, 12, 38, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (39, 12, 36, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (40, 12, 10, 'COMPLAINANT', 'Registered the initial complaint');
INSERT INTO CASE_PERSON VALUES (41, 13, 3, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (42, 13, 20, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (43, 14, 3, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (44, 14, 23, 'VICTIM', 'Filed complaint / affected party in the case');
INSERT INTO CASE_PERSON VALUES (45, 14, 14, 'OFFICIAL', 'Assisting the investigation in an official capacity');
INSERT INTO CASE_PERSON VALUES (46, 15, 7, 'ACCUSED', 'Named as the primary suspect in the case');
INSERT INTO CASE_PERSON VALUES (47, 15, 23, 'VICTIM', 'Filed complaint / affected party in the case');

-- INVESTIGATION
INSERT INTO INVESTIGATION VALUES (1, 1, TO_DATE('2024-02-19','YYYY-MM-DD'), NULL, 'SUSPENDED', 'Investigation findings compiled for case C2024001, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (2, 2, TO_DATE('2024-03-04','YYYY-MM-DD'), TO_DATE('2024-04-20','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024002, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (3, 3, TO_DATE('2024-04-03','YYYY-MM-DD'), TO_DATE('2024-05-24','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024003, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (4, 4, TO_DATE('2024-05-10','YYYY-MM-DD'), TO_DATE('2024-06-05','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024004, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (5, 5, TO_DATE('2024-06-21','YYYY-MM-DD'), NULL, 'ONGOING', 'Investigation findings compiled for case C2024005, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (6, 6, TO_DATE('2024-07-21','YYYY-MM-DD'), NULL, 'ONGOING', 'Investigation findings compiled for case C2024006, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (7, 7, TO_DATE('2024-08-05','YYYY-MM-DD'), TO_DATE('2024-09-06','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024007, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (8, 8, TO_DATE('2024-09-01','YYYY-MM-DD'), TO_DATE('2024-10-06','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024008, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (9, 9, TO_DATE('2024-10-13','YYYY-MM-DD'), TO_DATE('2024-11-14','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024009, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (10, 10, TO_DATE('2024-11-17','YYYY-MM-DD'), NULL, 'ONGOING', 'Investigation findings compiled for case C2024010, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (11, 11, TO_DATE('2024-12-01','YYYY-MM-DD'), NULL, 'ONGOING', 'Investigation findings compiled for case C2024011, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (12, 12, TO_DATE('2024-01-12','YYYY-MM-DD'), TO_DATE('2024-02-06','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024012, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (13, 13, TO_DATE('2024-02-01','YYYY-MM-DD'), TO_DATE('2024-03-24','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024013, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (14, 14, TO_DATE('2024-03-10','YYYY-MM-DD'), TO_DATE('2024-04-11','YYYY-MM-DD'), 'COMPLETED', 'Investigation findings compiled for case C2024014, evidence and witness statements under review');
INSERT INTO INVESTIGATION VALUES (15, 15, TO_DATE('2024-04-09','YYYY-MM-DD'), NULL, 'ONGOING', 'Investigation findings compiled for case C2024015, evidence and witness statements under review');

-- CASE_INVESTIGATOR
INSERT INTO CASE_INVESTIGATOR VALUES (1, 1, 2, TO_DATE('2024-02-24','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (2, 2, 2, TO_DATE('2024-03-08','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (3, 3, 1, TO_DATE('2024-04-04','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (4, 3, 14, TO_DATE('2024-04-04','YYYY-MM-DD'), 'ASSISTANT');
INSERT INTO CASE_INVESTIGATOR VALUES (5, 4, 14, TO_DATE('2024-05-14','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (6, 5, 2, TO_DATE('2024-06-22','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (7, 6, 3, TO_DATE('2024-07-24','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (8, 7, 2, TO_DATE('2024-08-07','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (9, 8, 1, TO_DATE('2024-09-05','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (10, 9, 2, TO_DATE('2024-10-15','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (11, 9, 14, TO_DATE('2024-10-15','YYYY-MM-DD'), 'ASSISTANT');
INSERT INTO CASE_INVESTIGATOR VALUES (12, 10, 3, TO_DATE('2024-11-18','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (13, 11, 3, TO_DATE('2024-12-03','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (14, 12, 15, TO_DATE('2024-01-16','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (15, 13, 15, TO_DATE('2024-02-02','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (16, 14, 1, TO_DATE('2024-03-13','YYYY-MM-DD'), 'LEAD');
INSERT INTO CASE_INVESTIGATOR VALUES (17, 15, 3, TO_DATE('2024-04-14','YYYY-MM-DD'), 'LEAD');

COMMIT;

-- Quick check: row counts per table
SELECT 'ROLE' AS table_name, COUNT(*) AS row_count FROM ROLE
UNION ALL SELECT 'DEPARTMENT', COUNT(*) FROM DEPARTMENT
UNION ALL SELECT 'APP_USER', COUNT(*) FROM APP_USER
UNION ALL SELECT 'PERSON', COUNT(*) FROM PERSON
UNION ALL SELECT 'CASE_TABLE', COUNT(*) FROM CASE_TABLE
UNION ALL SELECT 'FIR', COUNT(*) FROM FIR
UNION ALL SELECT 'CASE_PERSON', COUNT(*) FROM CASE_PERSON
UNION ALL SELECT 'INVESTIGATION', COUNT(*) FROM INVESTIGATION
UNION ALL SELECT 'CASE_INVESTIGATOR', COUNT(*) FROM CASE_INVESTIGATOR;