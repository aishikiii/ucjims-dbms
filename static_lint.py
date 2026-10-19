import re, pathlib, zipfile, os, json, collections, sys
root=pathlib.Path(__file__).resolve().parent / 'database'

def iter_insert_values(sql, table):
    pat=re.compile(r'INSERT\s+INTO\s+'+re.escape(table)+r'\s+VALUES\s*\(', re.I)
    for m in pat.finditer(sql):
        i=m.end(); depth=1; quote=False; buf=[]
        while i<len(sql):
            ch=sql[i]
            if ch=="'":
                if quote and i+1<len(sql) and sql[i+1]=="'":
                    buf.append("''"); i+=2; continue
                quote=not quote
                buf.append(ch); i+=1; continue
            if not quote:
                if ch=='(': depth+=1
                elif ch==')':
                    depth-=1
                    if depth==0: break
            buf.append(ch); i+=1
        if depth!=0: raise ValueError(f'unclosed insert for {table} at {m.start()}')
        # split values at depth zero outside strings
        expr=''.join(buf); fields=[]; cur=[]; dep=0; q=False; j=0
        while j<len(expr):
            ch=expr[j]
            if ch=="'":
                if q and j+1<len(expr) and expr[j+1]=="'": cur.append("''"); j+=2; continue
                q=not q; cur.append(ch); j+=1; continue
            if not q:
                if ch=='(': dep+=1
                elif ch==')': dep-=1
                elif ch==',' and dep==0:
                    fields.append(''.join(cur).strip()); cur=[]; j+=1; continue
            cur.append(ch); j+=1
        fields.append(''.join(cur).strip())
        yield [x.strip() for x in fields]

def date(expr):
    m=re.search(r"TO_DATE\('([^']+)'\s*,\s*'([^']+)'\)",expr,re.I)
    if not m: return None
    fmt=m.group(2)
    from datetime import datetime
    pyfmt=fmt.replace('YYYY','%Y').replace('MM','%m').replace('DD','%d').replace('HH24','%H').replace('MI','%M')
    return datetime.strptime(m.group(1),pyfmt)

files={p.name:p.read_text() for p in root.glob('*.sql')}
baseB=files['03_sample_data_personB.sql']; extra=files['03a_additional_sample_data_personB.sql']; integ=files['09_integration_demo_personC.sql']
allSql='\n'.join([baseB,extra,integ])
tables={'EVIDENCE':9,'CHAIN_OF_CUSTODY':9,'FORENSIC_REPORT':6}
rows={t:list(iter_insert_values(allSql,t)) for t in tables}
print('Insertion statement counts across three Person B files:')
for t, nfields in tables.items():
    print(t, len(rows[t]), 'rows; field arities', sorted(set(map(len,rows[t]))))
    assert all(len(r)==nfields for r in rows[t]), f'bad arity in {t}'

# IDs/uniqueness
pkidx={'EVIDENCE':0,'CHAIN_OF_CUSTODY':0,'FORENSIC_REPORT':0}
ids={t:[int(r[0]) for r in rs] for t,rs in rows.items()}
for t,v in ids.items():
    assert len(v)==len(set(v)), f'duplicate {t} ids'
    print(t,'IDs',min(v),max(v),'unique',len(v))

# Parse evidence rows
Ev={}
for r in rows['EVIDENCE']:
    evid=int(r[0]);
    Ev[evid]={'case':int(r[1]), 'type':r[2].strip("'"), 'collected':date(r[4]), 'collector':int(r[6]), 'storage':None if r[7].upper()=='NULL' else r[7].strip("'"), 'status':r[8].strip("'")}
Cust=[]
for r in rows['CHAIN_OF_CUSTODY']:
    t=date(r[4]); Cust.append({'id':int(r[0]),'evidence':int(r[1]),'from':None if r[2].upper()=='NULL' else int(r[2]),'to':None if r[3].upper()=='NULL' else int(r[3]),'date':t,'location':r[5].strip("'"),'purpose':r[6].strip("'"),'condition':r[7].strip("'"),'remarks':r[8].strip("'")})
Reports=[]
for r in rows['FORENSIC_REPORT']:
    Reports.append({'id':int(r[0]),'evidence':int(r[1]),'officer':int(r[2]),'date':date(r[3])})
err=[]
for c in Cust:
    if c['evidence'] not in Ev: err.append(f"Custody {c['id']} references missing evidence {c['evidence']}")
    else:
        if c['from'] is not None and c['to'] is not None and c['from']==c['to']: err.append(f"Custody {c['id']} sender=receiver")
        if c['date'] < Ev[c['evidence']]['collected']: err.append(f"Custody {c['id']} before collection")
for rep in Reports:
    if rep['evidence'] not in Ev: err.append(f"Report {rep['id']} references missing evidence {rep['evidence']}")
    elif rep['date'] < Ev[rep['evidence']]['collected']: err.append(f"Report {rep['id']} before collection")
    elif rep['officer'] not in (8,9,10): err.append(f"Report {rep['id']} assigned to non-forensic user {rep['officer']}")
byEv=collections.defaultdict(list)
for c in Cust: byEv[c['evidence']].append(c)
for eid in Ev:
    hist=sorted(byEv[eid],key=lambda c:(c['date'],c['id']))
    if not hist: err.append(f'Evidence {eid} has no custody events'); continue
    if hist[0]['from'] != Ev[eid]['collector']: err.append(f'Evidence {eid}: first transfer not from collector {Ev[eid]["collector"]}: {hist[0]}')
    for p,c in zip(hist,hist[1:]):
        if p['to'] is not None and c['from'] != p['to']: err.append(f'Evidence {eid}: broken chain at custody {c["id"]}; prior to={p["to"]}, current from={c["from"]}')
    last=hist[-1]
    st=Ev[eid]['status']
    if st=='RETURNED' and last['to'] != Ev[eid]['collector']: err.append(f'Evidence {eid}: RETURNED but final to={last["to"]}, collector={Ev[eid]["collector"]}')
    if st=='DISPOSED' and not (last['to'] is None and last['condition']=='Disposed'): err.append(f'Evidence {eid}: DISPOSED but final event not disposal: {last}')
    if st=='UNDER_EXAMINATION' and last['to'] not in (8,9,10): err.append(f'Evidence {eid}: UNDER_EXAMINATION but final user {last["to"]}')
    if st=='COLLECTED' and (last['to'] is None or last['to']==Ev[eid]['collector'] or last['to'] in (8,9,10)):
        err.append(f'Evidence {eid}: COLLECTED status conflicts with final custody recipient {last["to"]}')
    if last['to'] is None and Ev[eid]['storage'] is not None:
        err.append(f'Evidence {eid}: disposed status retains storage location {Ev[eid]["storage"]}')
    for rep in [r for r in Reports if r['evidence']==eid]:
        if not any(c['to'] in (8,9,10) and c['date'] < rep['date'] for c in hist): err.append(f'Report {rep["id"]}: no previous forensic handoff')
print('Combined Person B + integration rows expected: EVIDENCE',len(Ev),'CUSTODY',len(Cust),'REPORTS',len(Reports))
print('Evidence statuses:',dict(collections.Counter(v['status'] for v in Ev.values())))
print('Static errors:', len(err))
for e in err: print('ERROR:',e)
if err: sys.exit(2)

# Master runner includes can reference unchanged files already tracked in the source repository.
runner=files['run_fresh_setup.sql']
refs=re.findall(r'^@@([^\s]+)',runner,re.M)
tracked_unchanged={'01_tables_personA.sql','02_sample_data_personA.sql','03_queries_personA.sql',
 '02_tables_personB.sql','04_triggers_personB.sql','05_queries_personB.sql',
 '06_tables_personC.sql','07_sample_data_personC.sql','08_queries_personC.sql'}
missing=[x for x in refs if x not in files and x not in tracked_unchanged]
print('Runner includes:', len(refs), 'scripts; missing from package and tracked repo:', missing)
assert not missing
assert all((x in files or x in tracked_unchanged) for x in refs)
assert 'stage0_baseline_gate.sql' in refs, 'Fresh runner must stop on Stage 0 acceptance failures'
assert '10_stage1_hardening.sql' in refs and '14_stage1_validation.sql' in refs
# Domain values required by Stage 1 evidence-type CHECK constraint.
evidence_types={r[2].strip("'") for r in rows['EVIDENCE']}
assert evidence_types <= {'Physical','Digital','Document','Biological','Trace'}, evidence_types
print('Evidence types satisfy Stage 1 domain constraint:', sorted(evidence_types))

# Validate constraint/index names length in current implementation (Oracle legacy <=30)
hard=files['10_stage1_hardening.sql']
names=re.findall(r'CONSTRAINT\s+(\w+)',hard,re.I)+re.findall(r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+(\w+)',hard,re.I)
long=[n for n in names if len(n)>30]
print('Stage1 constraint/index name count:',len(names),'over 30 chars:',long)
assert not long

# PL/SQL slash terminator check
for fn,s in files.items():
    if re.search(r'CREATE\s+OR\s+REPLACE\s+(?:TRIGGER|PROCEDURE|FUNCTION|VIEW)',s,re.I):
        if not re.search(r'\n/\s*(?:\n|$)',s): print('WARNING missing slash delimiter:',fn)

print('Stage 0 acceptance gate is included in the master runner.')
print('Static lint passed.')
